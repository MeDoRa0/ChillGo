import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../../../profile/domain/repositories/profile_repository.dart';

/// Maximum time we wait for a Firestore profile read before treating it as
/// missing and routing the user onward. Without this bound, a hung network
/// call (common on Android emulators with broken Google Play Services) would
/// lock the app on /loading indefinitely.
const _kProfileFetchTimeout = Duration(seconds: 10);

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
  StreamSubscription<dynamic>? _authSub;
  Timer? _restoreFallbackTimer;
  Future<void> _statusRefresh = Future.value();

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

    _statusRefresh = _statusRefresh.then((_) => _updateStatus(user));
    return _statusRefresh;
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
        _cachedUsername = null;
        _cachedDisplayName = null;
        _cachedStatus = AuthStatus.unauthenticated;
      } else {
        // Bound the profile fetch so a hung Firestore call cannot pin the
        // app on /loading. On timeout we treat it as "no profile" (the safe
        // direction) and log so the issue is visible in logcat.
        final profile = await _getProfileWithTimeout(user.uid);
        if (profile != null) {
          _cachedUsername = profile.username;
          _cachedDisplayName = profile.displayName;
          _cachedStatus = AuthStatus.authenticatedWithProfile;
        } else {
          // Confirmed null response → user genuinely has no profile yet.
          _cachedUsername = null;
          _cachedDisplayName = null;
          _cachedStatus = AuthStatus.authenticatedNoProfile;
        }
      }
      _safeEmit(_cachedStatus);
      if (kDebugMode) {
        debugPrint(
          '[ChillGo] _updateStatus finished; newStatus=$_cachedStatus, username=$_cachedUsername',
        );
      }
    } catch (e, stack) {
      // A Firestore/network/rules exception is NOT a missing profile.
      // Log every failure (not just first run) so silent hangs become
      // visible — this is the exact signal that was missing before.
      if (kDebugMode) {
        debugPrint('[ChillGo] Profile fetch failed: $e\n$stack');
      }

      if (_cachedStatus == AuthStatus.unknown) {
        // First run: fall back to authenticatedNoProfile so the router
        // can proceed to onboarding, which is recoverable.
        _cachedStatus = AuthStatus.authenticatedNoProfile;
        _safeEmit(_cachedStatus);
        if (kDebugMode) {
          debugPrint(
            '[ChillGo] _updateStatus fallback to authenticatedNoProfile',
          );
        }
      }
      // On subsequent runs, preserve the last successfully resolved
      // status so the router does not misroute on a transient error.
    }
  }

  /// Wraps [ProfileRepository.getProfile] with a hard timeout so a hung
  /// Firestore call cannot lock the app on /loading indefinitely. Returning
  /// `null` on timeout is intentional — the router treats it the same as a
  /// genuine "no profile" response and routes the user to onboarding, which
  /// is recoverable.
  Future<UserProfile?> _getProfileWithTimeout(String uid) async {
    try {
      return await profileRepository
          .getProfile(uid)
          .timeout(_kProfileFetchTimeout);
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint(
          '[ChillGo] Profile fetch timed out after '
          '${_kProfileFetchTimeout.inSeconds}s for uid $uid; '
          'treating as no profile.',
        );
      }
      return null;
    }
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
    );
  }

  UserCredentials _credentialsFromUser(
    dynamic user, {
    String? username,
    String? displayName,
  }) {
    return UserCredentials(
      uid: user.uid,
      email: user.email,
      displayName: displayName ?? user.displayName,
      photoUrl: user.photoURL,
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
    await _authSub?.cancel();
    await _statusController.close();
  }
}
