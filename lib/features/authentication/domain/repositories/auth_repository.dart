import 'dart:async';

/// Represent the basic authentication states of the user.
enum AuthStatus {
  unknown,
  unauthenticated,
  authenticatedNoProfile,
  authenticatedWithProfile,
}

/// A representation of the user credentials returned by identity providers.
class UserCredentials {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// The ChillGo application username — only available AFTER onboarding
  /// (when the user picks a unique username and a profile document exists).
  /// Null before onboarding; non-null afterwards.
  final String? username;

  const UserCredentials({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.username,
  });
}

/// Abstract Repository defining the contract for authentication actions.
abstract class AuthRepository {
  /// Stream that emits the current [AuthStatus] of the application.
  Stream<AuthStatus> get status;

  /// Retrieves the current authenticated user's [AuthStatus] synchronously.
  AuthStatus get currentStatus;

  /// Retrieves the current authenticated user's credentials, if any.
  UserCredentials? get currentCredentials;

  /// Signs in the user using Google OAuth.
  /// Throws an exception on failure or user cancellation.
  Future<UserCredentials> signInWithGoogle();

  /// Signs in the user using Apple OAuth.
  /// Throws an exception on failure or user cancellation.
  Future<UserCredentials> signInWithApple();

  /// Signs out the current user, clearing all local sessions and tokens.
  Future<void> signOut();

  /// Forces the repository to refresh the authentication status (e.g., after onboarding completes).
  Future<void> forceRefreshStatus();
}
