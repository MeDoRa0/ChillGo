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
  final CrewRole role;
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
  final String invitedUsername;

  const CrewInvitation({
    required this.id,
    required this.crewId,
    required this.invitedUserId,
    required this.invitedByUserId,
    required this.createdAt,
    required this.crewName,
    required this.invitedByUsername,
    required this.invitedByDisplayName,
    this.invitedUsername = '',
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
        invitedUsername,
      ];
}
```

---

## CrewRepository Abstract Class
```dart
abstract class CrewRepository {
  /// Creates a new Crew and registers the creator as the 'owner' membership atomically.
  /// Returns the generated crew id.
  /// The implementation uses the current authenticated user as owner and rejects
  /// trimmed names shorter than 3 characters or longer than 50 characters.
  Future<String> createCrew(String name);

  /// Subscribes to real-time updates of crews that the current user belongs to.
  Stream<List<Crew>> streamCrews();

  /// Subscribes to real-time updates for a specific crew.
  Stream<Crew?> streamCrew(String crewId);

  /// Subscribes to real-time updates of memberships for a specific crew.
  Stream<List<CrewMembership>> streamMembers(String crewId);

  /// Invites a user to a crew by their unique username.
  /// The implementation:
  /// 1. Fetches the crew to cache its current name on the invitation.
  /// 2. Uses the current authenticated user's uid, username, and display name
  ///    as inviter metadata.
  /// 3. Resolves the target username -> uid.
  /// 4. Rejects users who are already members or already invited.
  /// 5. Writes the CrewInvitation document.
  Future<void> inviteUser(String crewId, String username);

  /// Subscribes to real-time updates of pending invitations for a specific crew.
  Stream<List<CrewInvitation>> streamPendingInvitationsForCrew(String crewId);

  /// Subscribes to real-time updates of invitations sent to the current user.
  Stream<List<CrewInvitation>> streamReceivedInvitations();

  /// Accepts a crew invitation by id.
  /// The implementation creates a CrewMembership for the current user as
  /// 'member' and deletes the CrewInvitation atomically. It rejects missing
  /// invitations, invitations for another user, and invalid invitation data.
  Future<void> acceptInvitation(String invitationId);

  /// Rejects or revokes a crew invitation by deleting the invitation document.
  /// Recipient rejection and owner revocation both use this same boundary method.
  Future<void> rejectInvitation(String invitationId);

  /// Updates the crew name. Only callable by the owner (enforced by firestore rules).
  /// The implementation rejects trimmed names shorter than 3 characters or
  /// longer than 50 characters.
  Future<void> updateCrewName(String crewId, String name);

  /// Deletes the crew. Only callable by the owner.
  /// Note: Cascading deletion of memberships and invitations is done client-side in a batch.
  Future<void> deleteCrew(String crewId);

  /// Leaves a crew. A member removes their own membership.
  /// The implementation uses the current authenticated user, throws
  /// 'crew-not-found' if the crew is missing, and prevents the owner from
  /// leaving directly by throwing 'owner-cannot-leave-crew'.
  Future<void> leaveCrew(String crewId);

  /// Removes a member from a crew. Only callable by the owner.
  /// The implementation deletes the target user's membership after ensuring the
  /// target user is not the crew owner; owner authorization is enforced by
  /// Firestore rules.
  Future<void> removeMember(String crewId, String userId);
}
```
