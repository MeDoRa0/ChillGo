import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../../../profile/domain/repositories/profile_repository.dart';

/// Maximum time we wait for a Firestore profile read before retrying it.
const _kProfileFetchTimeout = Duration(seconds: 10);

const _kProfileFetchRetryDelay = Duration(seconds: 1);

/// How long after construction we wait for `authStateChanges` to emit the
/// restored user before triggering a defensive manual fetch. This covers the
/// race where `authStateChanges` is subscribed to after auth restoration has
/// already completed (the stream does not replay past events).
const _kAuthStateRestoreFallback = Duration(milliseconds: 250);

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource authDatasource;
  final ProfileRepository profileRepository;

  final _statusController = StreamController<AuthStatus>.broadcast();
  AuthStatus _cachedStatus = AuthStatus.unknown;
  String? _cachedUsername;
  String? _cachedDisplayName;
  String? _cachedAvatarUrl;
  StreamSubscription<dynamic>? _authSub;
  Timer? _restoreFallbackTimer;
  Timer? _profileFetchRetryTimer;
  Future<void> _statusRefresh = Future.value();
  String? _latestAuthUserId;

  AuthRepositoryImpl({
    required this.authDatasource,
    required this.profileRepository,
  }) {
    // Seed initial status.
    _statusController.add(AuthStatus.unknown);

    _authSub = authDatasource.authStateChanges.listen(
      (user) {
        if (kDebugMode) {
          debugPrint(
            '[ChillGo] authStateChanges emitted user: ${user?.uid ?? 'null'}',
          );
        }
        _refreshStatus(user, cancelRestoreFallback: user != null);
      },
      onError: (Object e, StackTrace stack) {
        // Listener-level failures (e.g., stream closed) must not escape —
        // they would leave the app stranded on /loading with no signal.
        if (kDebugMode) {
          debugPrint('[ChillGo] authStateChanges stream error: $e\n$stack');
        }
        _cancelRestoreFallbackTimer();
        if (_cachedStatus == AuthStatus.unknown) {
          _cachedStatus = AuthStatus.unauthenticated;
          _safeEmit(_cachedStatus);
        }
      },
    );

    // Defensive fallback: if `authStateChanges` does not emit within a short
    // window (e.g., subscribed after Firebase Auth has already restored the
    // user), we explicitly read `currentUser` and kick off status resolution.
    // This guarantees the app never stays stuck on /loading because of a
    // missed stream event.
    _restoreFallbackTimer = Timer(_kAuthStateRestoreFallback, () {
      if (_cachedStatus != AuthStatus.unknown) return;
      final currentUser = authDatasource.currentUser;
      if (currentUser != null) {
        if (kDebugMode) {
          debugPrint(
            '[ChillGo] authStateChanges did not emit within '
            '${_kAuthStateRestoreFallback.inMilliseconds}ms; '
            'using currentUser fallback for uid ${currentUser.uid}.',
          );
        }
        // Defensive log showing we triggered the fallback.
        if (kDebugMode) {
          debugPrint('[ChillGo] Triggering authState restore fallback');
        }
        _refreshStatus(currentUser, cancelRestoreFallback: true);
      } else {
        if (kDebugMode) {
          debugPrint(
            '[ChillGo] authStateChanges did not emit within '
            '${_kAuthStateRestoreFallback.inMilliseconds}ms; '
            'treating app as unauthenticated.',
          );
        }
        _cachedStatus = AuthStatus.unauthenticated;
        _safeEmit(_cachedStatus);
      }
    });
  }

  Future<void> _refreshStatus(
    dynamic user, {
    required bool cancelRestoreFallback,
  }) {
    if (cancelRestoreFallback) {
      _cancelRestoreFallbackTimer();
    }
    _updateLatestAuthUser(user);

    _statusRefresh = _statusRefresh.then((_) => _updateStatus(user));
    return _statusRefresh;
  }

  void _updateLatestAuthUser(dynamic user) {
    final userId = user?.uid as String?;
    if (userId == _latestAuthUserId) return;

    _latestAuthUserId = userId;
    _profileFetchRetryTimer?.cancel();
    _profileFetchRetryTimer = null;

    if (_cachedStatus == AuthStatus.unknown) return;
    _cachedUsername = null;
    _cachedDisplayName = null;
    _cachedAvatarUrl = null;
    _cachedStatus = AuthStatus.unknown;
    _safeEmit(_cachedStatus);
  }

  void _cancelRestoreFallbackTimer() {
    _restoreFallbackTimer?.cancel();
    _restoreFallbackTimer = null;
  }

  Future<void> _updateStatus(dynamic user) async {
    if (kDebugMode) {
      debugPrint(
        '[ChillGo] _updateStatus start; user=${user?.uid ?? 'null'}, cached=$_cachedStatus',
      );
    }
    try {
      if (user == null) {
        if (!_isLatestAuthState(user)) return;
        _cachedUsername = null;
        _cachedDisplayName = null;
        _cachedAvatarUrl = null;
        _cachedStatus = AuthStatus.unauthenticated;
      } else {
        final profile = await _getProfileWithTimeout(user.uid);
        if (!_isLatestAuthState(user)) return;
        if (profile != null) {
          _cachedUsername = profile.username;
          _cachedDisplayName = profile.displayName;
          _cachedAvatarUrl = profile.avatarUrl;
          _cachedStatus = AuthStatus.authenticatedWithProfile;
        } else {
          // Confirmed null response → user genuinely has no profile yet.
          _cachedUsername = null;
          _cachedDisplayName = null;
          _cachedAvatarUrl = null;
          _cachedStatus = AuthStatus.authenticatedNoProfile;
        }
      }
      _safeEmit(_cachedStatus);
      if (kDebugMode) {
        debugPrint(
          '[ChillGo] _updateStatus finished; newStatus=$_cachedStatus, username=$_cachedUsername',
        );
      }
    } on FirebaseException catch (error, stack) {
      // visible — this is the exact signal that was missing before.
      _retryProfileFetch(user, error, stack);
    } on TimeoutException catch (error, stack) {
      _retryProfileFetch(user, error, stack);
    }
  }

  /// Bounds a profile read so a transient failure can be retried.
  Future<UserProfile?> _getProfileWithTimeout(String uid) {
    return profileRepository.getProfile(uid).timeout(_kProfileFetchTimeout);
  }

  bool _isLatestAuthState(dynamic user) {
    return user == null
        ? _latestAuthUserId == null
        : user.uid == _latestAuthUserId;
  }

  void _scheduleProfileFetchRetry(String userId) {
    _profileFetchRetryTimer?.cancel();
    _profileFetchRetryTimer = Timer(_kProfileFetchRetryDelay, () {
      final currentUser = authDatasource.currentUser;
      if (currentUser?.uid != userId) return;
      _refreshStatus(currentUser, cancelRestoreFallback: false);
    });
  }

  void _retryProfileFetch(dynamic user, Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('[ChillGo] Profile fetch failed: $error\n$stack');
    }
    if (!_isLatestAuthState(user) || user == null) return;
    _scheduleProfileFetchRetry(user.uid);
  }

  /// Emit through the broadcast controller without letting a closed-sink
  /// exception escape into the async event loop and become an unhandled
  /// error (which would also lock the router).
  void _safeEmit(AuthStatus status) {
    try {
      if (!_statusController.isClosed) {
        _statusController.add(status);
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[ChillGo] Failed to emit status $status: $e\n$stack');
      }
    }
  }

  @override
  AuthStatus get currentStatus => _cachedStatus;

  @override
  Stream<AuthStatus> get status => _statusController.stream;

  @override
  UserCredentials? get currentCredentials {
    final user = authDatasource.currentUser;
    if (user == null) return null;
    return _credentialsFromUser(
      user,
      username: _cachedUsername,
      displayName: _cachedDisplayName,
      photoUrl: _cachedAvatarUrl,
    );
  }

  @override
  Future<UserCredentials?> refreshCurrentUserToken() async {
    final user = await authDatasource.refreshCurrentUserToken();
    if (user == null) return null;
    return _credentialsFromUser(
      user,
      username: _cachedUsername,
      displayName: _cachedDisplayName,
      photoUrl: _cachedAvatarUrl,
    );
  }

  UserCredentials _credentialsFromUser(
    dynamic user, {
    String? username,
    String? displayName,
    String? photoUrl,
  }) {
    return UserCredentials(
      uid: user.uid,
      email: user.email,
      displayName: displayName ?? user.displayName,
      photoUrl: photoUrl ?? user.photoURL,
      username: username,
    );
  }

  @override
  Future<UserCredentials> signInWithGoogle() async {
    final credential = await authDatasource.signInWithGoogle();
    final user = credential.user!;
    return UserCredentials(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  @override
  Future<UserCredentials> signInWithApple() async {
    final credential = await authDatasource.signInWithApple();
    final user = credential.user!;
    return UserCredentials(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  @override
  Future<void> signOut() async {
    await authDatasource.signOut();
  }

  @override
  Future<void> forceRefreshStatus() async {
    final user = authDatasource.currentUser;
    await _refreshStatus(user, cancelRestoreFallback: true);
  }

  Future<void> dispose() async {
    _cancelRestoreFallbackTimer();
    _profileFetchRetryTimer?.cancel();
    await _authSub?.cancel();
    await _statusController.close();
  }
}
