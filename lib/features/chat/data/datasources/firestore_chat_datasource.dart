import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/firestore_timestamp.dart';
import '../../../outings/domain/entities/outing_status.dart';
import '../../domain/entities/chat_command.dart';
import '../../domain/entities/chat_message_cursor.dart';
import '../../domain/services/chat_clock.dart';
import '../models/chat_command_model.dart';
import '../models/chat_message_model.dart';
import '../models/chat_read_state_model.dart';

class ChatAccessSnapshot {
  const ChatAccessSnapshot({
    required this.crewId,
    required this.status,
    required this.isCrewMember,
    required this.isParticipant,
    required this.deletionPending,
  });
  final String crewId;
  final OutingStatus status;
  final bool isCrewMember;
  final bool isParticipant;
  final bool deletionPending;
}

class FirestoreChatDatasource {
  FirestoreChatDatasource({
    required this.firestore,
    required this.currentUid,
    required this.clock,
  });

  final FirebaseFirestore firestore;
  final String Function() currentUid;
  final ChatClock clock;

  String newDocumentId() => firestore.collection('chat_commands').doc().id;

  DateTime get _retentionCutoff =>
      clock.now.subtract(const Duration(hours: 24));

  Query<Map<String, dynamic>> _historyQuery(String outingId, int limit) {
    if (limit < 1 || limit > 50) throw RangeError.range(limit, 1, 50, 'limit');
    return firestore
        .collection('chat_messages')
        .where('outingId', isEqualTo: outingId)
        .where(
          'acceptedAt',
          isGreaterThan: writeFirestoreTimestamp(_retentionCutoff),
        )
        .orderBy('acceptedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit);
  }

  Stream<List<ChatMessageModel>> watchLatest(String outingId, int limit) =>
      _historyQuery(outingId, limit).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
            .toList(growable: false),
      );

  Future<List<ChatMessageModel>> loadOlder(
    String outingId,
    ChatMessageCursor before,
    int limit,
  ) async {
    final snapshot = await _historyQuery(outingId, limit)
        .startAfter([
          writeFirestoreTimestamp(before.acceptedAt),
          before.messageId,
        ])
        .get(const GetOptions(source: Source.server));
    return snapshot.docs
        .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
  }

  Future<String> createSendCommand({
    required String outingId,
    required String clientMessageId,
    required String text,
  }) async {
    final uid = currentUid();
    if (uid.isEmpty) throw const ChatAuthenticationFailure();
    final commandRef = firestore.collection('chat_commands').doc();
    await firestore.runTransaction((transaction) async {
      final outingRef = firestore.collection('outings').doc(outingId);
      final outing = await transaction.get(outingRef);
      if (!outing.exists) throw const ChatAccessDenied();
      final data = outing.data()!;
      final crewId = data['crewId'];
      if (crewId is! String || crewId.isEmpty) throw const ChatAccessDenied();
      transaction.set(
        commandRef,
        ChatCommandModel.pendingMap(
          outingId: outingId,
          crewId: crewId,
          userId: uid,
          clientMessageId: clientMessageId,
          text: text,
          createdAt: FieldValue.serverTimestamp(),
        ),
      );
    });
    return commandRef.id;
  }

  Stream<ChatCommand?> watchCommand(String commandId) => firestore
      .collection('chat_commands')
      .doc(commandId)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? ChatCommandModel.fromMap(snapshot.data()!, snapshot.id)
            : null,
      );

  Stream<ChatReadStateModel?> watchMyReadState(String outingId) {
    final uid = currentUid();
    if (uid.isEmpty) return Stream.error(const ChatAuthenticationFailure());
    return _myReadStateQuery(outingId, uid).snapshots().map(
      (snapshot) => snapshot.docs.isNotEmpty
          ? ChatReadStateModel.fromMap(snapshot.docs.single.data())
          : null,
    );
  }

  Query<Map<String, dynamic>> _myReadStateQuery(String outingId, String uid) =>
      firestore
          .collection('chat_read_states')
          .where('outingId', isEqualTo: outingId)
          .where('userId', isEqualTo: uid)
          .limit(1);

  Future<void> markReadThrough({
    required String outingId,
    required String crewId,
    required ChatMessageModel message,
  }) async {
    final uid = currentUid();
    if (uid.isEmpty) throw const ChatAuthenticationFailure();
    final ref = firestore
        .collection('chat_read_states')
        .doc('${outingId}_$uid');
    try {
      // A direct set lets Rules atomically distinguish the initial create from
      // a monotonic update without first reading a document that may not exist.
      await ref.set(_readStatePayload(outingId, crewId, uid, message));
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      if (!await _isReadAlreadyAdvanced(outingId, uid, message.cursor)) rethrow;
      // Another session already advanced this private cursor as far or farther.
    }
  }

  Map<String, dynamic> _readStatePayload(
    String outingId,
    String crewId,
    String uid,
    ChatMessageModel message,
  ) => {
    'outingId': outingId,
    'crewId': crewId,
    'userId': uid,
    'readThroughAcceptedAt': writeFirestoreTimestamp(message.acceptedAt),
    'readThroughMessageId': message.id,
    'cursorExpiresAt': writeFirestoreTimestamp(message.expiresAt),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Future<bool> _isReadAlreadyAdvanced(
    String outingId,
    String uid,
    ChatMessageCursor requestedCursor,
  ) async {
    final snapshot = await _myReadStateQuery(
      outingId,
      uid,
    ).get(const GetOptions(source: Source.server));
    if (snapshot.docs.isEmpty) return false;
    final storedState = ChatReadStateModel.fromMap(snapshot.docs.single.data());
    return !requestedCursor.isAfter(storedState.cursor);
  }

  Future<int> unreadCount({
    required String outingId,
    ChatMessageCursor? after,
  }) async {
    final uid = currentUid();
    if (uid.isEmpty) throw const ChatAuthenticationFailure();
    final cutoff = _retentionCutoff;
    final effectiveAfter = after != null && after.acceptedAt.isAfter(cutoff)
        ? after
        : null;
    final base = firestore
        .collection('chat_messages')
        .where('outingId', isEqualTo: outingId);
    final all = await _countAfter(base, effectiveAfter, cutoff);
    final own = await _countAfter(
      base.where('authorUserId', isEqualTo: uid),
      effectiveAfter,
      cutoff,
    );
    return (all - own).clamp(0, 5000);
  }

  Future<int> _countAfter(
    Query<Map<String, dynamic>> base,
    ChatMessageCursor? after,
    DateTime cutoff,
  ) async {
    if (after == null) return _countSince(base, cutoff);
    return _countAfterCursor(base, after);
  }

  Future<int> _countSince(
    Query<Map<String, dynamic>> base,
    DateTime cutoff,
  ) async {
    final available = await base
        .where('acceptedAt', isGreaterThan: writeFirestoreTimestamp(cutoff))
        .limit(5000)
        .count()
        .get();
    return available.count ?? 0;
  }

  Future<int> _countAfterCursor(
    Query<Map<String, dynamic>> base,
    ChatMessageCursor after,
  ) async {
    final timestamp = writeFirestoreTimestamp(after.acceptedAt);
    final later = await base
        .where('acceptedAt', isGreaterThan: timestamp)
        .limit(5000)
        .count()
        .get();
    final tied = await base
        .where('acceptedAt', isEqualTo: timestamp)
        .orderBy(FieldPath.documentId)
        .startAfter([after.messageId])
        .limit(5000)
        .count()
        .get();
    return ((later.count ?? 0) + (tied.count ?? 0)).clamp(0, 5000);
  }

  Stream<ChatAccessSnapshot> watchAccess(String outingId) {
    final uid = currentUid();
    if (uid.isEmpty) return Stream.error(const ChatAuthenticationFailure());
    late StreamController<ChatAccessSnapshot> controller;
    StreamSubscription? outingSubscription;
    StreamSubscription? membershipSubscription;
    StreamSubscription? participantSubscription;
    Map<String, dynamic>? outingData;
    bool? membership;
    bool? participant;

    void emitIfReady() {
      final data = outingData;
      if (data == null || membership == null || participant == null) return;
      controller.add(
        ChatAccessSnapshot(
          crewId: data['crewId'] as String,
          status: OutingStatus.fromValue(data['status']),
          isCrewMember: membership!,
          isParticipant: participant!,
          deletionPending: data['deletionPending'] == true,
        ),
      );
    }

    controller = StreamController<ChatAccessSnapshot>(
      onListen: () {
        outingSubscription = firestore
            .collection('outings')
            .doc(outingId)
            .snapshots()
            .listen((outing) async {
              if (!outing.exists) {
                controller.addError(const ChatAccessDenied());
                return;
              }
              final data = outing.data()!;
              final crewId = data['crewId'] as String;
              outingData = data;
              await membershipSubscription?.cancel();
              await participantSubscription?.cancel();
              membershipSubscription = firestore
                  .collection('crew_memberships')
                  .doc('${crewId}_$uid')
                  .snapshots()
                  .listen((value) {
                    membership = value.exists;
                    emitIfReady();
                  }, onError: controller.addError);
              participantSubscription = firestore
                  .collection('outing_participants')
                  .doc('${outingId}_$uid')
                  .snapshots()
                  .listen((value) {
                    participant = value.exists;
                    emitIfReady();
                  }, onError: controller.addError);
            }, onError: controller.addError);
      },
      onCancel: () async {
        await outingSubscription?.cancel();
        await membershipSubscription?.cancel();
        await participantSubscription?.cancel();
      },
    );
    return controller.stream;
  }
}
