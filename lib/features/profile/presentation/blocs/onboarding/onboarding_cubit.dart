import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
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
    required ProfileRepository profileRepository,
    required AuthRepository authRepository,
  })  : _profileRepository = profileRepository,
        _authRepository = authRepository,
        super(OnboardingInitial());

  Future<void> submitOnboarding({
    required String uid,
    required String username,
    required String displayName,
  }) async {
    emit(OnboardingLoading());
    try {
      final isAvailable = await _profileRepository.isUsernameAvailable(username);
      if (!isAvailable) {
        emit(const OnboardingFailure('Username is already taken'));
        return;
      }
      await _profileRepository.createProfile(
        uid: uid,
        username: username,
        displayName: displayName,
      );
      await _authRepository.forceRefreshStatus();
      emit(OnboardingSuccess());
    } catch (e) {
      emit(OnboardingFailure(e.toString()));
    }
  }
}
