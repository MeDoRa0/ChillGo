import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../../authentication/domain/entities/user_profile.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileFailure extends ProfileState {
  final String error;

  const ProfileFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileCubit({required ProfileRepository profileRepository})
    : _profileRepository = profileRepository,
      super(ProfileInitial());

  Future<void> loadProfile(String uid) async {
    emit(ProfileLoading());
    try {
      final profile = await _profileRepository.getProfile(uid);
      if (profile != null) {
        emit(ProfileLoaded(profile));
      } else {
        emit(const ProfileFailure('Profile not found'));
      }
    } catch (e) {
      emit(ProfileFailure(e.toString()));
    }
  }

  Future<void> updateDisplayName(String uid, String displayName) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      final trimmedDisplayName = displayName.trim();
      if (trimmedDisplayName.isEmpty || trimmedDisplayName.length > 50) {
        emit(const ProfileFailure('Display name must be 1-50 characters'));
        emit(currentState);
        return;
      }

      emit(ProfileLoading());
      try {
        await _profileRepository.updateProfile(
          uid: uid,
          displayName: trimmedDisplayName,
        );
        final updatedProfile = UserProfile(
          id: currentState.profile.id,
          username: currentState.profile.username,
          displayName: trimmedDisplayName,
          avatarUrl: currentState.profile.avatarUrl,
          createdAt: currentState.profile.createdAt,
        );
        emit(ProfileLoaded(updatedProfile));
      } catch (e) {
        emit(ProfileFailure(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> updateAvatar(
    String uid,
    List<int> imageBytes,
    String ext,
  ) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(ProfileLoading());
      try {
        final avatarUrl = await _profileRepository.uploadAvatar(
          uid: uid,
          imageBytes: imageBytes,
          fileExtension: ext,
        );
        await _profileRepository.updateProfile(uid: uid, avatarUrl: avatarUrl);
        final updatedProfile = UserProfile(
          id: currentState.profile.id,
          username: currentState.profile.username,
          displayName: currentState.profile.displayName,
          avatarUrl: avatarUrl,
          createdAt: currentState.profile.createdAt,
        );
        emit(ProfileLoaded(updatedProfile));
      } catch (e) {
        emit(ProfileFailure(e.toString()));
        emit(currentState);
      }
    }
  }
}
