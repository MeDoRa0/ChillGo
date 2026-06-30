import 'dart:async';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../../../profile/domain/repositories/profile_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource authDatasource;
  final ProfileRepository profileRepository;
  
  final _statusController = StreamController<AuthStatus>.broadcast();
  AuthStatus _cachedStatus = AuthStatus.unknown;
  StreamSubscription<dynamic>? _authSub;

  AuthRepositoryImpl({
    required this.authDatasource,
    required this.profileRepository,
  }) {
    // Seed initial status
    _statusController.add(AuthStatus.unknown);
    
    _authSub = authDatasource.authStateChanges.listen((user) async {
      await _updateStatus(user);
    });
  }

  Future<void> _updateStatus(dynamic user) async {
    if (user == null) {
      _cachedStatus = AuthStatus.unauthenticated;
    } else {
      try {
        final profile = await profileRepository.getProfile(user.uid);
        if (profile != null) {
          _cachedStatus = AuthStatus.authenticatedWithProfile;
        } else {
          // Confirmed null response → user genuinely has no profile yet.
          _cachedStatus = AuthStatus.authenticatedNoProfile;
        }
      } catch (e) {
        // A Firestore/network/rules exception is NOT a missing profile.
        // Leave _cachedStatus as its current value (unknown on first run,
        // or the last successfully resolved status on subsequent runs) and
        // surface it so the router can handle the transient error correctly
        // instead of misrouting an existing user into onboarding.
        _cachedStatus = AuthStatus.unknown;
      }
    }
    _statusController.add(_cachedStatus);
  }

  @override
  AuthStatus get currentStatus => _cachedStatus;

  @override
  Stream<AuthStatus> get status => _statusController.stream;

  @override
  UserCredentials? get currentCredentials {
    final user = authDatasource.currentUser;
    if (user == null) return null;
    return UserCredentials(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
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
    await _updateStatus(user);
  }
}
