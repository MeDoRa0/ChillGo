import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../../authentication/domain/repositories/auth_repository.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingSuccess extends OnboardingState {}

class OnboardingFailure extends OnboardingState {
  final String error;

  const OnboardingFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class OnboardingCubit extends Cubit<OnboardingState> {
  final ProfileRepository _profileRepository;
  final AuthRepository _authRepository;

  OnboardingCubit({
    required this._profileRepository,
    required this._authRepository,
  }) : super(OnboardingInitial());

  Future<void> submitOnboarding({
    required String uid,
    required String username,
    required String displayName,
  }) async {
    emit(OnboardingLoading());
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        emit(
          const OnboardingFailure('Authentication lost. Please sign in again.'),
        );
        return;
      }

      debugPrint(
        '[OnboardingCubit] submitOnboarding start uid=$uid username=$username',
      );
      await _refreshFirebaseUserToken(firebaseUser);
      debugPrint(
        '[OnboardingCubit] ID token refreshed for uid: ${firebaseUser.uid}',
      );

      final isAvailable = await _profileRepository.isUsernameAvailable(
        username,
      );
      debugPrint('[OnboardingCubit] isUsernameAvailable=$isAvailable');
      if (!isAvailable) {
        emit(const OnboardingFailure('Username is already taken'));
        return;
      }

      await _attemptCreateProfileWithRetry(
        uid: uid,
        username: username,
        displayName: displayName,
        firebaseUser: firebaseUser,
      );

      try {
        await _authRepository.forceRefreshStatus();
      } catch (_) {
        // forceRefreshStatus is best-effort; ignore failure to ensure onboarding outcome
        // remains decided by createProfile success.
      }
      emit(OnboardingSuccess());
    } catch (e) {
      debugPrint('[OnboardingCubit] Error during onboarding: $e');
      emit(OnboardingFailure(e.toString()));
    }
  }

  Future<void> _attemptCreateProfileWithRetry({
    required String uid,
    required String username,
    required String displayName,
    required User firebaseUser,
  }) async {
    try {
      await _profileRepository.createProfile(
        uid: uid,
        username: username,
        displayName: displayName,
      );
    } catch (e) {
      final errorText = e.toString();
      if (errorText.contains('permission-denied')) {
        debugPrint(
          '[OnboardingCubit] permission-denied on createProfile, refreshing auth token and retrying',
        );
        await _refreshFirebaseUserToken(firebaseUser);
        await _profileRepository.createProfile(
          uid: uid,
          username: username,
          displayName: displayName,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> _refreshFirebaseUserToken(User firebaseUser) async {
    await firebaseUser.reload();
    await firebaseUser.getIdToken(true);
    debugPrint(
      '[OnboardingCubit] Firebase auth token refreshed for uid: ${firebaseUser.uid}',
    );
  }
}
