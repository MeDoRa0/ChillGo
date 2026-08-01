import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/notification.dart';
import '../../domain/entities/notification_preferences.dart';
import '../models/notification_command_model.dart';
import '../models/notification_model.dart';
import '../models/notification_preferences_model.dart';
import '../models/notification_summary_model.dart';

class FirestoreNotificationsDatasource {
  FirestoreNotificationsDatasource({
    required this.firestore,
    required this.functions,
    required this.currentUid,
    this.commandTimeout = const Duration(seconds: 20),
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;
  final String Function() currentUid;
  final Duration commandTimeout;
  final DateTime Function() now;

  Stream<NotificationDataPage> watchNewest() {
    late StreamController<NotificationDataPage> controller;
    StreamSubscription<NotificationSummaryModel>? summarySubscription;
    var refreshSequence = 0;

    Future<void> refreshPage() async {
      final sequence = ++refreshSequence;
      try {
        final page = await _fetchPage();
        if (sequence == refreshSequence && !controller.isClosed) {
          controller.add(page);
        }
      } catch (error, stack) {
        if (sequence == refreshSequence && !controller.isClosed) {
          controller.addError(error, stack);
        }
      }
    }

    controller = StreamController<NotificationDataPage>(
      onListen: () {
        summarySubscription = watchSummary().listen(
          (_) => unawaited(refreshPage()),
          onError: controller.addError,
        );
      },
      onCancel: () => summarySubscription?.cancel(),
    );
    return controller.stream;
  }

  Future<NotificationDataPage> loadOlder(NotificationCursor cursor) =>
      _fetchPage(cursor);

  Stream<NotificationSummaryModel> watchSummary() {
    final uid = _requireUid();
    return firestore
        .collection('notification_summaries')
        .doc(uid)
        .snapshots()
        .map((snapshot) => NotificationSummaryModel.fromMap(snapshot.data()));
  }

  Stream<NotificationPreferencesModel> watchPreferences() {
    final uid = _requireUid();
    return firestore
        .collection('notification_preferences')
        .doc(uid)
        .snapshots()
        .map(
          (snapshot) => NotificationPreferencesModel.fromMap(snapshot.data()),
        );
  }

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    final uid = _requireUid();
    await firestore
        .collection('notification_preferences')
        .doc(uid)
        .set(NotificationPreferencesModel.toMap(preferences));
  }

  Future<NotificationCommandModel> submitCommand({
    required String type,
    required Map<String, Object> payload,
  }) async {
    final uid = _requireUid();
    final commandRef = firestore.collection('notification_commands').doc();
    await commandRef.set(
      NotificationCommandModel.pendingMap(
        type: type,
        requestedByUserId: uid,
        payload: payload,
      ),
    );
    try {
      return await commandRef
          .snapshots()
          .where((snapshot) => snapshot.exists)
          .map(
            (snapshot) =>
                NotificationCommandModel.fromMap(snapshot.data()!, snapshot.id),
          )
          .firstWhere((command) => command.isTerminal)
          .timeout(commandTimeout);
    } on TimeoutException {
      throw const NotificationServiceFailure();
    }
  }

  Future<NotificationDataPage> _fetchPage([NotificationCursor? cursor]) async {
    _requireUid();
    final response = await functions
        .httpsCallable('notificationCenterPage')
        .call({
          if (cursor != null)
            'cursor': {
              'createdAt': cursor.createdAt.toUtc().toIso8601String(),
              'notificationId': cursor.notificationId,
            },
        });
    if (response.data is! Map) throw const NotificationServiceFailure();
    final payload = Map<String, dynamic>.from(response.data as Map);
    final rawItems = payload['items'];
    if (rawItems is! List) throw const NotificationServiceFailure();
    return NotificationDataPage(
      items: _availableModels(rawItems.whereType<Map>()),
      nextCursor: _cursorFromPayload(payload['nextCursor']),
    );
  }

  List<NotificationModel> _availableModels(Iterable<Map> rawItems) {
    final current = now().toUtc();
    final models = <NotificationModel>[];
    for (final rawItem in rawItems) {
      try {
        final notificationMap = Map<String, dynamic>.from(rawItem);
        final notificationId = notificationMap.remove('id');
        if (notificationId is! String) continue;
        final model = NotificationModel.fromMap(
          notificationMap,
          notificationId,
        );
        if (!model.isExpiredAt(current)) models.add(model);
      } on FormatException {
        // Malformed trusted output is omitted instead of exposing partial data.
      }
    }
    return models;
  }

  NotificationCursor? _cursorFromPayload(Object? rawCursor) {
    if (rawCursor is! Map) return null;
    final cursorMap = Map<String, dynamic>.from(rawCursor);
    final createdAt = DateTime.tryParse(
      cursorMap['createdAt'] as String? ?? '',
    );
    final notificationId = cursorMap['notificationId'];
    if (createdAt == null || notificationId is! String) return null;
    return NotificationCursor(
      createdAt: createdAt.toUtc(),
      notificationId: notificationId,
    );
  }

  String _requireUid() {
    final uid = currentUid();
    if (uid.isEmpty) throw const NotificationAuthenticationFailure();
    return uid;
  }
}

class NotificationDataPage {
  const NotificationDataPage({required this.items, this.nextCursor});

  final List<NotificationModel> items;
  final NotificationCursor? nextCursor;
}
