import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/outing.dart';
import '../../domain/entities/outing_participant.dart';
import '../../domain/entities/outing_status.dart';
import '../../domain/entities/attendance_status.dart';
import '../../domain/services/outing_lifecycle_policy.dart';
import '../models/outing_model.dart';
import '../models/outing_participant_model.dart';

class FirestoreOutingsDatasource {
  final FirebaseFirestore firestore;

  FirestoreOutingsDatasource({required this.firestore});

  CollectionReference<Map<String, dynamic>> get outings =>
      firestore.collection('outings');
  CollectionReference<Map<String, dynamic>> get participants =>
      firestore.collection('outing_participants');
  CollectionReference<Map<String, dynamic>> get memberships =>
      firestore.collection('crew_memberships');
  CollectionReference<Map<String, dynamic>> get crews =>
      firestore.collection('crews');
  CollectionReference<Map<String, dynamic>> get users =>
      firestore.collection('users');

  Future<String> createOuting({
    required String crewId,
    required String creatorUserId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required String locationText,
  }) async {
    await _requireCrewMember(crewId, creatorUserId);
    final creatorProfile = await _requireUserProfile(creatorUserId);
    final outingRef = outings.doc();
    final outingId = outingRef.id;
    final now = DateTime.now().toUtc();
    final participantId = _participantId(outingId, creatorUserId);
    final batch = firestore.batch();

    batch.set(outingRef, {
      'crewId': crewId,
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'scheduledAt': writeFirestoreTimestamp(scheduledAt),
      'locationText': locationText.trim(),
      'status': OutingStatus.draft.value,
      'createdByUserId': creatorUserId,
      'createdAt': writeFirestoreTimestamp(now),
      'updatedAt': writeFirestoreTimestamp(now),
      'agreementRoundSequence': 0,
    });

    batch.set(participants.doc(participantId), {
      'outingId': outingId,
      'crewId': crewId,
      'userId': creatorUserId,
      ...creatorProfile,
      'addedByUserId': creatorUserId,
      'addedAt': writeFirestoreTimestamp(now),
      'isCreatorParticipant': true,
      'attendanceStatus': AttendanceStatus.accepted.value,
      'respondedAt': writeFirestoreTimestamp(now),
    });

    await batch.commit();
    return outingId;
  }

  Stream<List<Outing>> streamCrewOutings(String crewId) {
    return outings.where('crewId', isEqualTo: crewId).snapshots().map((snap) {
      final values = <Outing>[];
      for (final doc in snap.docs) {
        final outing = _tryReadOuting(doc.data(), doc.id);
        if (outing != null) values.add(outing);
      }
      values.sort(_compareOutingsForList);
      return values;
    });
  }

  Stream<Outing?> streamOuting(String outingId) {
    return outings.doc(outingId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return _tryReadOuting(snap.data() ?? {}, snap.id);
    });
  }

  Stream<List<OutingParticipant>> streamParticipants(String outingId) {
    return participants.where('outingId', isEqualTo: outingId).snapshots().map((
      snap,
    ) {
      final values = <OutingParticipant>[];
      for (final doc in snap.docs) {
        final participant = _tryReadParticipant(doc.data(), doc.id);
        if (participant != null) values.add(participant);
      }
      values.sort((a, b) => a.addedAt.compareTo(b.addedAt));
      return values;
    });
  }

  Future<Outing?> getOuting(String outingId) async {
    final snap = await outings.doc(outingId).get();
    if (!snap.exists) return null;
    return OutingModel.fromMap(snap.data() ?? {}, snap.id);
  }

  Future<void> updateOutingDetails({
    required String outingId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required String locationText,
  }) async {
    final ref = outings.doc(outingId);
    await firestore.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      final status = OutingStatus.fromValue(snap.data()?['status']);
      if (!status.isEditable) throw Exception('outing-not-editable');
      transaction.update(ref, {
        'title': title.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim()
        else
          'description': FieldValue.delete(),
        if (status == OutingStatus.draft)
          'scheduledAt': writeFirestoreTimestamp(scheduledAt),
        if (status == OutingStatus.draft) 'locationText': locationText.trim(),
        'updatedAt': writeFirestoreTimestamp(DateTime.now()),
      });
    });
  }

  Future<void> cancelOuting({
    required String outingId,
    required String cancelledReason,
  }) async {
    final now = writeFirestoreTimestamp(DateTime.now());
    final ref = outings.doc(outingId);
    await firestore.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      final status = OutingStatus.fromValue(snap.data()?['status']);
      if (!status.isCancellable) throw Exception('outing-not-cancellable');
      transaction.update(ref, {
        'status': OutingStatus.cancelled.value,
        'cancelledReason': cancelledReason.trim(),
        'cancelledAt': now,
        'updatedAt': now,
      });
    });
  }

  Future<void> deleteOuting(String outingId) async {
    final participantSnapshots = await participants
        .where('outingId', isEqualTo: outingId)
        .get();
    final batch = firestore.batch();

    for (final participant in participantSnapshots.docs) {
      batch.delete(participant.reference);
    }
    batch.delete(outings.doc(outingId));
    await batch.commit();
  }

  Future<OutingParticipant> addParticipant({
    required String outingId,
    required String userId,
    required String addedByUserId,
  }) async {
    final outing = await _requireOuting(outingId);
    await _requireCrewMember(outing.crewId, userId);
    final profile = await _requireUserProfile(userId);
    final participantId = _participantId(outingId, userId);
    final now = writeFirestoreTimestamp(DateTime.now());
    final ref = participants.doc(participantId);

    final payload = {
      'outingId': outingId,
      'crewId': outing.crewId,
      'userId': userId,
      ...profile,
      'addedByUserId': addedByUserId,
      'addedAt': now,
      'isCreatorParticipant': false,
      'attendanceStatus': AttendanceStatus.invited.value,
      'respondedAt': null,
    };
    await ref.set(payload);
    return OutingParticipantModel.fromMap(payload, participantId);
  }

  Future<void> removeParticipant({
    required String outingId,
    required String userId,
  }) async {
    final outingRef = outings.doc(outingId);
    final participantRef = participants.doc(_participantId(outingId, userId));
    await firestore.runTransaction((transaction) async {
      final snap = await transaction.get(outingRef);
      final status = OutingStatus.fromValue(snap.data()?['status']);
      if (status.isHistorical) throw Exception('participant-removal-blocked');
      transaction.delete(participantRef);
    });
  }

  Future<void> respondToOuting({
    required String outingId,
    required String userId,
    required AttendanceStatus attendanceStatus,
  }) async {
    if (attendanceStatus == AttendanceStatus.invited) {
      throw ArgumentError.value(attendanceStatus, 'attendanceStatus');
    }
    final outingRef = outings.doc(outingId);
    final participantRef = participants.doc(_participantId(outingId, userId));
    final participantExists = await _participantExists(outingId, userId);
    await firestore.runTransaction((transaction) async {
      final outingSnap = await transaction.get(outingRef);
      if (!outingSnap.exists) throw Exception('outing-not-found');
      final status = OutingStatus.fromValue(outingSnap.data()?['status']);
      if (status == OutingStatus.meeting || status.isHistorical) {
        throw Exception('attendance-response-closed');
      }
      final responseFields = {
        'attendanceStatus': attendanceStatus.value,
        'respondedAt': FieldValue.serverTimestamp(),
      };
      if (participantExists) {
        transaction.update(participantRef, responseFields);
        return;
      }
      final userProfile = _profilePayload(
        await transaction.get(users.doc(userId)),
      );
      transaction.set(participantRef, {
        'outingId': outingId,
        'crewId': outingSnap.data()?['crewId'],
        'userId': userId,
        ...userProfile,
        'addedByUserId': userId,
        'addedAt': FieldValue.serverTimestamp(),
        'isCreatorParticipant': false,
        ...responseFields,
      });
    });
  }

  Future<bool> _participantExists(String outingId, String userId) async {
    final snapshot = await participants
        .where('outingId', isEqualTo: outingId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> changeLifecycleStatus({
    required String outingId,
    required OutingStatus nextStatus,
  }) async {
    final now = writeFirestoreTimestamp(DateTime.now());
    final ref = outings.doc(outingId);
    await firestore.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      final currentStatus = OutingStatus.fromValue(snap.data()?['status']);
      if (!OutingLifecyclePolicy().canTransition(currentStatus, nextStatus)) {
        throw Exception('invalid-lifecycle-transition');
      }
      transaction.update(ref, {
        'status': nextStatus.value,
        'updatedAt': now,
        if (nextStatus == OutingStatus.archived) 'archivedAt': now,
      });
    });
  }

  Future<bool> isCrewOwner(String crewId, String userId) async {
    final crew = await crews.doc(crewId).get();
    return crew.exists && crew.data()?['ownerId'] == userId;
  }

  Future<void> _requireCrewMember(String crewId, String userId) async {
    final snap = await memberships.doc('${crewId}_$userId').get();
    if (!snap.exists) throw Exception('crew-membership-required');
  }

  Future<Outing> _requireOuting(String outingId) async {
    final outing = await getOuting(outingId);
    if (outing == null) throw Exception('outing-not-found');
    return outing;
  }

  Future<Map<String, dynamic>> _requireUserProfile(String userId) async {
    return _profilePayload(await users.doc(userId).get());
  }

  Map<String, dynamic> _profilePayload(
    DocumentSnapshot<Map<String, dynamic>> userDoc,
  ) {
    final data = userDoc.data();
    final username = data?['username'] as String?;
    final displayName = data?['displayName'] as String?;
    if (!userDoc.exists ||
        username == null ||
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

  String _participantId(String outingId, String userId) =>
      '${outingId}_$userId';

  int _compareOutingsForList(Outing a, Outing b) {
    if (a.status.isHistorical != b.status.isHistorical) {
      return a.status.isHistorical ? 1 : -1;
    }
    if (!a.status.isHistorical) {
      return a.scheduledAt.compareTo(b.scheduledAt);
    }
    return b.scheduledAt.compareTo(a.scheduledAt);
  }

  Outing? _tryReadOuting(Map<String, dynamic> data, String docId) {
    try {
      return OutingModel.fromMap(data, docId);
    } catch (error, stackTrace) {
      developer.log(
        'Skipping malformed outing document $docId',
        name: 'FirestoreOutingsDatasource',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  OutingParticipant? _tryReadParticipant(
    Map<String, dynamic> data,
    String docId,
  ) {
    try {
      return OutingParticipantModel.fromMap(data, docId);
    } catch (error, stackTrace) {
      developer.log(
        'Skipping malformed outing participant document $docId',
        name: 'FirestoreOutingsDatasource',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
