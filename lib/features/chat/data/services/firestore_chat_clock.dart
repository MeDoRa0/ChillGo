import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/chat_command.dart';
import '../../domain/services/chat_clock.dart';

class FirestoreChatClock implements ChatClock {
  FirestoreChatClock({
    required this.firestore,
    required this.currentUid,
    DateTime Function()? deviceNow,
    this.serverTimeProbe,
  }) : _deviceNow = deviceNow ?? DateTime.now;

  final FirebaseFirestore firestore;
  final String Function() currentUid;
  final DateTime Function() _deviceNow;
  final Future<DateTime> Function(String uid)? serverTimeProbe;
  Duration? _offset;
  final Set<DocumentReference<Map<String, dynamic>>> _probes = {};

  @override
  bool get isEstablished => _offset != null;

  @override
  DateTime get now {
    final offset = _offset;
    if (offset == null) throw const ChatNetworkFailure();
    return _deviceNow().toUtc().add(offset);
  }

  @override
  Future<void> establish() => _synchronize();

  @override
  Future<void> refresh() => _synchronize();

  Future<void> _synchronize() async {
    final uid = currentUid();
    if (uid.isEmpty) throw const ChatAuthenticationFailure();
    final started = _deviceNow().toUtc();
    try {
      final serverTime =
          await (serverTimeProbe?.call(uid) ?? _createProbe(uid));
      final finished = _deviceNow().toUtc();
      final midpoint = started.add(finished.difference(started) ~/ 2);
      _offset = serverTime.difference(midpoint);
    } on ChatFailure {
      rethrow;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') throw const ChatAccessDenied();
      throw const ChatNetworkFailure();
    }
  }

  Future<DateTime> _createProbe(String uid) async {
    final collection = firestore.collection('chat_time_probes');
    final ref = collection.doc('${uid}_${collection.doc().id}');
    _probes.add(ref);
    try {
      await firestore.runTransaction((transaction) async {
        transaction.set(ref, {
          'userId': uid,
          'requestedAt': FieldValue.serverTimestamp(),
        });
      });
      final snapshot = await ref.get(const GetOptions(source: Source.server));
      final serverTime = readFirestoreTimestamp(
        snapshot.data()?['requestedAt'],
      );
      if (serverTime == null) throw const ChatNetworkFailure();
      return serverTime;
    } finally {
      await _removeProbe(ref);
    }
  }

  Future<void> _removeProbe(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      await ref.delete();
    } catch (_) {
      // Scheduled cleanup removes abandoned probes.
    } finally {
      _probes.remove(ref);
    }
  }

  @override
  Future<void> dispose() async {
    await Future.wait(_probes.toList().map(_removeProbe));
  }
}
