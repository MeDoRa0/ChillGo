import 'dart:async';

/// Model representing a user profile within the domain layer.
class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });
}

/// Public profile fields exposed for authenticated username lookup.
class PublicUserProfile {
  final String username;
  final String displayName;
  final String? avatarUrl;

  const PublicUserProfile({
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });
}

/// Abstract Repository defining the contract for profile operations.
abstract class ProfileRepository {
  /// Fetches the profile of the user matching the given [uid].
  /// Returns null if the profile does not exist.
  Future<UserProfile?> getProfile(String uid);

  /// Checks if a [username] is unique and available.
  /// Usernames are case-insensitive, 3-20 chars, alphanumeric or underscores,
  /// and cannot contain spaces.
  Future<bool> isUsernameAvailable(String username);

  /// Finds a public profile by username for invitation flows.
  /// Returns only username, display name, and avatar URL.
  Future<PublicUserProfile?> lookupByUsername(String username);

  /// Creates a new user profile and registers the unique username.
  /// Must be executed atomically (e.g., using a Firestore Transaction).
  /// Throws an exception if the username is already taken.
  Future<void> createProfile({
    required String uid,
    required String username,
    required String displayName,
    String? avatarUrl,
  });

  /// Updates the user's display name.
  Future<void> updateProfile({
    required String uid,
    required String displayName,
  });

  /// Uploads compressed JPEG, PNG, or WebP image bytes to remote storage and
  /// returns the download URL.
  Future<String> uploadAvatar({
    required String uid,
    required List<int> imageBytes,
    required String contentType,
    required int originalSizeBytes,
  });
}
