import '../../domain/repositories/profile_repository.dart';
import '../datasources/firestore_profile_datasource.dart';
import '../../../authentication/domain/entities/user_profile.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirestoreProfileDatasource profileDatasource;

  ProfileRepositoryImpl({required this.profileDatasource});

  @override
  Future<UserProfile?> getProfile(String uid) {
    return profileDatasource.getProfile(uid);
  }

  @override
  Future<bool> isUsernameAvailable(String username) {
    return profileDatasource.isUsernameAvailable(username);
  }

  @override
  Future<void> createProfile({
    required String uid,
    required String username,
    required String displayName,
    String? avatarUrl,
  }) {
    return profileDatasource.createProfile(
      uid: uid,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? avatarUrl,
  }) {
    return profileDatasource.updateProfile(
      uid: uid,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<String> uploadAvatar({
    required String uid,
    required List<int> imageBytes,
    required String fileExtension,
  }) {
    return profileDatasource.uploadAvatar(
      uid: uid,
      imageBytes: imageBytes,
      fileExtension: fileExtension,
    );
  }
}
