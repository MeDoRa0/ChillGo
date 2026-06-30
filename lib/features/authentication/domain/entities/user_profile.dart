import 'package:equatable/equatable.dart';

/// Model representing a user profile within the domain layer.
class UserProfile extends Equatable {
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

  @override
  List<Object?> get props => [id, username, displayName, avatarUrl, createdAt];
}
