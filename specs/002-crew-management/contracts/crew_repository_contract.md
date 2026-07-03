# Repository Interface Contract: CrewRepository

This document defines the abstract class contracts and entities signature for `CrewRepository`, which will be located in the domain layer at `lib/features/crews/domain/repositories/crew_repository.dart`.

## Domain Entities

### Crew
```dart
class Crew extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;

  const Crew({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, ownerId, createdAt];
}
```

### CrewMembership
```dart
class CrewMembership extends Equatable {
  final String id;
  final String crewId;
  final String userId;
  final String role; // 'owner' | 'member'
  final DateTime joinedAt;
  final String username;
  final String displayName;
  final String? avatarUrl;

  const CrewMembership({
    required this.id,
    required this.crewId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [
        id,
        crewId,
        userId,
        role,
        joinedAt,
        username,
        displayName,
        avatarUrl,
      ];
}
```

### CrewInvitation
```dart
class CrewInvitation extends Equatable {
  final String id;
  final String crewId;
  final String invitedUserId;
  final String invitedByUserId;
  final DateTime createdAt;
  final String crewName;
  final String invitedByUsername;
  final String invitedByDisplayName;

  const CrewInvitation({
    required this.id,
    required this.crewId,
    required this.invitedUserId,
    required this.invitedByUserId,
    required this.createdAt,
    required this.crewName,
    required this.invitedByUsername,
    required this.invitedByDisplayName,
  });

  @override
  List<Object?> get props => [
        id,
        crewId,
        invitedUserId,
        invitedByUserId,
        createdAt,
        crewName,
        invitedByUsername,
        invitedByDisplayName,
      ];
}
```

---

## CrewRepository Abstract Class
```dart
abstract class CrewRepository {
  /// Creates a new Crew and registers the creator as the 'owner' membership atomically.
  Future<void> createCrew({
    required String name,
    required UserProfile ownerProfile,
  });

  /// Updates the crew name. Only callable by the owner (enforced by firestore rules).
  Future<void> updateCrewName({
    required String crewId,
    required String newName,
  });

  /// Deletes the crew. Only callable by the owner.
  /// Note: Cascading deletion of memberships and invitations is done client-side in a batch.
  Future<void> deleteCrew({
    required String crewId,
  });

  /// Subscribes to real-time updates of crews that the user belongs to.
  Stream<List<Crew>> watchUserCrews(String userId);

  /// Subscribes to real-time updates of memberships for a specific crew.
  Stream<List<CrewMembership>> watchCrewMemberships(String crewId);

  /// Subscribes to real-time updates of pending invitations sent to a specific user.
  Stream<List<CrewInvitation>> watchUserInvitations(String userId);

  /// Subscribes to real-time updates of pending invitations for a specific crew.
  Stream<List<CrewInvitation>> watchCrewPendingInvitations(String crewId);

  /// Invites a user to a crew by their unique username.
  /// 1. Resolves username -> UID.
  /// 2. Verifies if already a member or already invited.
  /// 3. Writes the CrewInvitation document.
  Future<void> inviteUserByUsername({
    required String crewId,
    required String username,
    required UserProfile inviterProfile,
    required String crewName,
  });

  /// Accepts a crew invitation.
  /// 1. Creates a CrewMembership for the user as 'member'.
  /// 2. Deletes the CrewInvitation.
  Future<void> acceptInvitation({
    required CrewInvitation invitation,
    required UserProfile userProfile,
  });

  /// Rejects a crew invitation by deleting the invitation document.
  Future<void> rejectInvitation({
    required String crewId,
    required String userId,
  });

  /// Revokes a pending crew invitation. Only callable by the owner.
  Future<void> revokeInvitation({
    required String crewId,
    required String userId,
  });

  /// Leaves a crew. A member removes their own membership.
  /// The Owner cannot leave directly (must delete the crew).
  Future<void> leaveCrew({
    required String crewId,
    required String userId,
  });

  /// Removes a member from a crew. Only callable by the owner.
  Future<void> removeMember({
    required String crewId,
    required String userId,
  });
}
```
