import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/crew.dart';
import '../../domain/entities/crew_membership.dart';
import '../../domain/entities/crew_invitation.dart';

class FirestoreCrewsDatasource {
  final FirebaseFirestore firestore;

  FirestoreCrewsDatasource({required this.firestore});

  CollectionReference get _crews => firestore.collection('crews');
  CollectionReference get _memberships =>
      firestore.collection('crew_memberships');
  CollectionReference get _invitations =>
      firestore.collection('crew_invitations');
  CollectionReference get _usernames => firestore.collection('usernames');
  CollectionReference get _users => firestore.collection('users');

  /// Creates a new crew and the owner membership atomically.
  Future<String> createCrew({
    required String name,
    required String ownerId,
  }) async {
    final crewRef = _crews.doc();
    final crewId = crewRef.id;
    final now = DateTime.now().toUtc().toIso8601String();
    final membershipId = '${crewId}_$ownerId';

    // Fetch owner profile for denormalized membership fields
    final userDoc = await _users.doc(ownerId).get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};

    final batch = firestore.batch();

    batch.set(crewRef, {
      'id': crewId,
      'name': name.trim(),
      'ownerId': ownerId,
      'createdAt': now,
    });

    batch.set(_memberships.doc(membershipId), {
      'id': membershipId,
      'crewId': crewId,
      'userId': ownerId,
      'role': 'owner',
      'joinedAt': now,
      'username': userData['username'] as String? ?? '',
      'displayName': userData['displayName'] as String? ?? '',
      'avatarUrl': userData['avatarUrl'],
    });

    await batch.commit();
    return crewId;
  }

  Stream<List<Crew>> streamCrewsForUser(String userId) {
    return _memberships.where('userId', isEqualTo: userId).snapshots().asyncMap(
      (membSnap) async {
        final crewIds = membSnap.docs
            .map((d) => (d.data() as Map)['crewId'] as String)
            .toList();
        if (crewIds.isEmpty) return <Crew>[];

        final crewDocs = <QueryDocumentSnapshot>[];
        for (var start = 0; start < crewIds.length; start += 30) {
          final end = (start + 30).clamp(0, crewIds.length);
          final batchIds = crewIds.sublist(start, end);
          final crewSnap = await _crews
              .where(FieldPath.documentId, whereIn: batchIds)
              .get();
          crewDocs.addAll(crewSnap.docs);
        }

        return crewDocs
            .map((d) => Crew.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList();
      },
    );
  }

  Stream<Crew?> streamCrew(String crewId) {
    return _crews.doc(crewId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Crew.fromMap(snap.data() as Map<String, dynamic>, snap.id);
    });
  }

  Stream<List<CrewMembership>> streamMembers(String crewId) {
    return _memberships
        .where('crewId', isEqualTo: crewId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => CrewMembership.fromMap(
                  d.data() as Map<String, dynamic>,
                  d.id,
                ),
              )
              .toList(),
        );
  }

  Stream<List<CrewInvitation>> streamPendingInvitationsForCrew(String crewId) {
    return _invitations
        .where('crewId', isEqualTo: crewId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => CrewInvitation.fromMap(
                  d.data() as Map<String, dynamic>,
                  d.id,
                ),
              )
              .toList(),
        );
  }

  Stream<List<CrewInvitation>> streamReceivedInvitations(String userId) {
    return _invitations
        .where('invitedUserId', isEqualTo: userId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => CrewInvitation.fromMap(
                  d.data() as Map<String, dynamic>,
                  d.id,
                ),
              )
              .toList(),
        );
  }

  /// Verifies username exists and returns uid. Throws descriptive exceptions.
  Future<String> resolveUsername(String username) async {
    final doc = await _usernames.doc(username.toLowerCase().trim()).get();
    if (!doc.exists) throw Exception('username-not-found');
    return (doc.data() as Map<String, dynamic>)['uid'] as String;
  }

  Future<bool> isMember(String crewId, String userId) async {
    final doc = await _memberships.doc('${crewId}_$userId').get();
    return doc.exists;
  }

  Future<bool> isInvited(String crewId, String userId) async {
    final doc = await _invitations.doc('${crewId}_$userId').get();
    return doc.exists;
  }

  /// Sends an invitation. Throws if user not found, already a member, or already invited.
  Future<void> inviteUser({
    required String crewId,
    required String inviterUid,
    required String inviterUsername,
    required String inviterDisplayName,
    required String crewName,
    required String targetUsername,
  }) async {
    final normalized = targetUsername.toLowerCase().trim();
    final targetUid = await resolveUsername(normalized);

    if (await isMember(crewId, targetUid)) {
      throw Exception('already-a-member');
    }
    if (await isInvited(crewId, targetUid)) {
      throw Exception('already-invited');
    }

    final invitationId = '${crewId}_$targetUid';
    // Capture the *normalized* username so the pending-invitations UI can
    // show `@alice` instead of the Firebase UID we stored on invitedUserId.
    await _invitations.doc(invitationId).set({
      'id': invitationId,
      'crewId': crewId,
      'invitedUserId': targetUid,
      'invitedByUserId': inviterUid,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'crewName': crewName,
      'invitedByUsername': inviterUsername,
      'invitedByDisplayName': inviterDisplayName,
      'invitedUsername': normalized,
    });
  }

  /// Accepts an invitation: creates membership + deletes invitation atomically.
  Future<void> acceptInvitation({
    required String invitationId,
    required String userId,
  }) async {
    final invDoc = await _invitations.doc(invitationId).get();
    if (!invDoc.exists) throw Exception('invitation-not-found');
    final invitation = CrewInvitation.fromMap(
      invDoc.data() as Map<String, dynamic>,
      invDoc.id,
    );
    if (invitation.invitedUserId != userId) {
      throw Exception('invitation-user-mismatch');
    }
    if (invitation.crewId.isEmpty) {
      throw Exception('invalid-invitation');
    }

    // Fetch user profile for denormalized fields
    final userDoc = await _users.doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    final crewId = invitation.crewId;
    final membershipId = '${crewId}_$userId';
    final now = DateTime.now().toUtc().toIso8601String();

    final batch = firestore.batch();
    batch.set(_memberships.doc(membershipId), {
      'id': membershipId,
      'crewId': crewId,
      'userId': userId,
      'role': 'member',
      'joinedAt': now,
      'username': userData['username'] as String? ?? '',
      'displayName': userData['displayName'] as String? ?? '',
      'avatarUrl': userData['avatarUrl'],
    });
    batch.delete(_invitations.doc(invitationId));
    await batch.commit();
  }

  /// Rejects/revokes an invitation: simply deletes the invitation document.
  Future<void> rejectInvitation(String invitationId) async {
    await _invitations.doc(invitationId).delete();
  }

  Future<void> updateCrewName(String crewId, String name) async {
    await _crews.doc(crewId).update({'name': name.trim()});
  }

  /// Deletes the crew and all associated memberships and invitations atomically.
  Future<void> deleteCrew(String crewId) async {
    final batch = firestore.batch();

    final memberships = await _memberships
        .where('crewId', isEqualTo: crewId)
        .get();
    for (final doc in memberships.docs) {
      batch.delete(doc.reference);
    }

    final invitations = await _invitations
        .where('crewId', isEqualTo: crewId)
        .get();
    for (final doc in invitations.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_crews.doc(crewId));
    await batch.commit();
  }

  Future<void> removeMember(String crewId, String userId) async {
    await _memberships.doc('${crewId}_$userId').delete();
  }
}
