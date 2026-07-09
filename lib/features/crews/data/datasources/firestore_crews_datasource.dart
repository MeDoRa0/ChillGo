import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/crew.dart';
import '../../domain/entities/crew_membership.dart';
import '../../domain/entities/crew_invitation.dart';

class FirestoreCrewsDatasource {
  static const int _firestoreBatchWriteLimit = 500;
  static const int _deleteCrewBatchMaxAttempts = 3;

  final FirebaseFirestore firestore;

  FirestoreCrewsDatasource({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _crews =>
      firestore.collection('crews');
  CollectionReference<Map<String, dynamic>> get _memberships =>
      firestore.collection('crew_memberships');
  CollectionReference<Map<String, dynamic>> get _invitations =>
      firestore.collection('crew_invitations');
  CollectionReference<Map<String, dynamic>> get _usernames =>
      firestore.collection('usernames');
  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  /// Creates a new crew and the owner membership atomically.
  Future<String> createCrew({
    required String name,
    required String ownerId,
  }) async {
    final crewRef = _crews.doc();
    final crewId = crewRef.id;
    final now = DateTime.now().toUtc().toIso8601String();
    final membershipId = '${crewId}_$ownerId';

    final ownerProfile = await _requireUserProfile(ownerId);

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
      ...ownerProfile,
    });

    await batch.commit();
    return crewId;
  }

  Stream<List<Crew>> streamCrewsForUser(String userId) {
    return _memberships.where('userId', isEqualTo: userId).snapshots().asyncMap(
      (membSnap) async {
        final crewIds = membSnap.docs
            .map((doc) => _readString(doc.data(), 'crewId'))
            .whereType<String>()
            .toSet()
            .toList();
        if (crewIds.isEmpty) return <Crew>[];

        final crewDocs = await Future.wait([
          for (final crewId in crewIds) _crews.doc(crewId).get(),
        ]);

        return crewDocs
            .where((doc) => doc.exists)
            .map((doc) => Crew.fromMap(doc.data() ?? {}, doc.id))
            .toList();
      },
    );
  }

  String? _readString(Map<String, dynamic>? data, String field) {
    final value = data?[field];
    if (value is! String || value.isEmpty) return null;
    return value;
  }

  Stream<Crew?> streamCrew(String crewId) {
    return _crews.doc(crewId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Crew.fromMap(snap.data() ?? {}, snap.id);
    });
  }

  Stream<List<CrewMembership>> streamMembers(String crewId) {
    return _memberships
        .where('crewId', isEqualTo: crewId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CrewMembership.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Stream<List<CrewInvitation>> streamPendingInvitationsForCrew(String crewId) {
    return _invitations
        .where('crewId', isEqualTo: crewId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CrewInvitation.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Stream<List<CrewInvitation>> streamReceivedInvitations(String userId) {
    return _invitations
        .where('invitedUserId', isEqualTo: userId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CrewInvitation.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  /// Verifies username exists and returns uid. Throws descriptive exceptions.
  Future<String> resolveUsername(String username) async {
    final doc = await _usernames.doc(username.toLowerCase().trim()).get();
    if (!doc.exists) throw Exception('username-not-found');
    return (doc.data() as Map<String, dynamic>)['uid'] as String;
  }

  Future<bool> usernameExists(String username) async {
    final normalized = username.toLowerCase().trim();
    if (normalized.isEmpty || normalized.contains(RegExp(r'\s'))) {
      return false;
    }
    final doc = await _usernames.doc(normalized).get();
    return doc.exists;
  }

  Future<bool> isMember(String crewId, String userId) async {
    final doc = await _memberships.doc('${crewId}_$userId').get();
    return doc.exists;
  }

  Future<bool> isInvited(String crewId, String userId) async {
    final doc = await _invitations.doc('${crewId}_$userId').get();
    return doc.exists;
  }

  /// Sends an invitation after resolving the target username and inviter profile.
  Future<void> inviteUser({
    required String crewId,
    required String inviterUid,
    required String crewName,
    required String targetUsername,
  }) async {
    final normalized = targetUsername.toLowerCase().trim();
    final targetUid = await resolveUsername(normalized);
    final inviterProfile = await _requireUserProfile(inviterUid);

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
      'invitedByUsername': inviterProfile['username'],
      'invitedByDisplayName': inviterProfile['displayName'],
      'invitedUsername': normalized,
    });
  }

  /// Accepts an invitation: creates membership + deletes invitation atomically.
  Future<void> acceptInvitation({
    required String invitationId,
    required String userId,
  }) async {
    final invitationRef = _invitations.doc(invitationId);
    final userRef = _users.doc(userId);

    await firestore.runTransaction<void>((transaction) async {
      final invitationDoc = await transaction.get(invitationRef);
      if (!invitationDoc.exists) throw Exception('invitation-not-found');
      final invitation = CrewInvitation.fromMap(
        invitationDoc.data() as Map<String, dynamic>,
        invitationDoc.id,
      );
      if (invitation.invitedUserId != userId) {
        throw Exception('invitation-user-mismatch');
      }
      if (invitation.crewId.isEmpty) {
        throw Exception('invalid-invitation');
      }

      final userDoc = await transaction.get(userRef);
      final userData = _profilePayloadFromData(userDoc.data());
      final crewId = invitation.crewId;
      final membershipId = '${crewId}_$userId';
      final membershipRef = _memberships.doc(membershipId);
      final now = DateTime.now().toUtc().toIso8601String();

      transaction.set(membershipRef, {
        'id': membershipId,
        'crewId': crewId,
        'userId': userId,
        'role': 'member',
        'joinedAt': now,
        ...userData,
      });
      transaction.delete(invitationRef);
    });
  }

  /// Rejects/revokes an invitation: simply deletes the invitation document.
  Future<void> rejectInvitation(String invitationId) async {
    await _invitations.doc(invitationId).delete();
  }

  Future<void> updateCrewName(String crewId, String name) async {
    await _crews.doc(crewId).update({'name': name.trim()});
  }

  /// Deletes the crew and all associated memberships and invitations.
  Future<void> deleteCrew(String crewId) async {
    final memberships = await _memberships
        .where('crewId', isEqualTo: crewId)
        .get();
    final invitations = await _invitations
        .where('crewId', isEqualTo: crewId)
        .get();

    final documentsToDelete = <DocumentReference>[
      ...memberships.docs.map((doc) => doc.reference),
      ...invitations.docs.map((doc) => doc.reference),
      _crews.doc(crewId),
    ];

    final totalChunkCount =
        (documentsToDelete.length / _firestoreBatchWriteLimit).ceil();
    var committedChunkCount = 0;

    for (
      var chunkStart = 0;
      chunkStart < documentsToDelete.length;
      chunkStart += _firestoreBatchWriteLimit
    ) {
      final chunkEnd = chunkStart + _firestoreBatchWriteLimit;
      final chunkDocuments = documentsToDelete.sublist(
        chunkStart,
        chunkEnd > documentsToDelete.length
            ? documentsToDelete.length
            : chunkEnd,
      );

      for (var attempt = 1; attempt <= _deleteCrewBatchMaxAttempts; attempt++) {
        final batch = firestore.batch();
        for (final document in chunkDocuments) {
          batch.delete(document);
        }

        try {
          await batch.commit();
          committedChunkCount++;
          break;
        } on FirebaseException catch (error, stackTrace) {
          if (attempt == _deleteCrewBatchMaxAttempts) {
            Error.throwWithStackTrace(
              CrewDeletePartialFailureException(
                crewId: crewId,
                committedChunkCount: committedChunkCount,
                failedChunkNumber: committedChunkCount + 1,
                totalChunkCount: totalChunkCount,
                remainingDocumentCount: documentsToDelete.length - chunkStart,
                cause: error,
              ),
              stackTrace,
            );
          }
        }
      }
    }
  }

  Future<void> removeMember(String crewId, String userId) async {
    await _memberships.doc('${crewId}_$userId').delete();
  }

  Future<Map<String, dynamic>> _requireUserProfile(String userId) async {
    final userDoc = await _users.doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('profile-required');
    }
    return _profilePayloadFromData(userDoc.data());
  }

  Map<String, dynamic> _profilePayloadFromData(Map<String, dynamic>? data) {
    final username = data?['username'] as String?;
    final displayName = data?['displayName'] as String?;
    if (username == null ||
        username.isEmpty ||
        displayName == null ||
        displayName.isEmpty) {
      throw Exception('profile-required');
    }

    return {
      'username': username,
      'displayName': displayName,
      if (data?['avatarUrl'] != null) 'avatarUrl': data?['avatarUrl'],
    };
  }
}

class CrewDeletePartialFailureException implements Exception {
  final String crewId;
  final int committedChunkCount;
  final int failedChunkNumber;
  final int totalChunkCount;
  final int remainingDocumentCount;
  final FirebaseException cause;

  CrewDeletePartialFailureException({
    required this.crewId,
    required this.committedChunkCount,
    required this.failedChunkNumber,
    required this.totalChunkCount,
    required this.remainingDocumentCount,
    required this.cause,
  });

  @override
  String toString() {
    return 'CrewDeletePartialFailureException('
        'crewId: $crewId, '
        'committedChunkCount: $committedChunkCount, '
        'failedChunkNumber: $failedChunkNumber, '
        'totalChunkCount: $totalChunkCount, '
        'remainingDocumentCount: $remainingDocumentCount, '
        'cause: $cause'
        ')';
  }
}
