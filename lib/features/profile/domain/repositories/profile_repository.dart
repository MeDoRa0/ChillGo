import 'dart:async';
import '../../../authentication/domain/entities/user_profile.dart';

/// Abstract Repository defining the contract for profile operations.
abstract class ProfileRepository {
  /// Fetches the profile of the user matching the given [uid].
  /// Returns null if the profile does not exist.
  Future<UserProfile?> getProfile(String uid);

  /// Checks if a [username] is unique and available.
  /// Usernames are case-insensitive and cannot contain spaces.
  Future<bool> isUsernameAvailable(String username);

  /// Creates a new user profile and registers the unique username.
  /// Must be executed atomically (e.g., using a Firestore Transaction).
  /// Throws an exception if the username is already taken.
  Future<void> createProfile({
    required String uid,
    required String username,
    required String displayName,
    String? avatarUrl,
  });

  /// Updates the user's profile details.
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? avatarUrl,
  });

  /// Uploads the compressed image bytes to remote storage and returns the download URL.
  Future<String> uploadAvatar({
    required String uid,
    required List<int> imageBytes,
    required String fileExtension,
  });
}
