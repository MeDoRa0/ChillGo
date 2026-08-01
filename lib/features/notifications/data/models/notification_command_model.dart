import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationCommandStatus { pending, processing, succeeded, failed }

class NotificationCommandModel {
  const NotificationCommandModel({
    required this.id,
    required this.status,
    this.result,
    this.errorCode,
  });

  final String id;
  final NotificationCommandStatus status;
  final Map<String, dynamic>? result;
  final String? errorCode;

  bool get isTerminal =>
      status == NotificationCommandStatus.succeeded ||
      status == NotificationCommandStatus.failed;

  factory NotificationCommandModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) => NotificationCommandModel(
    id: id,
    status: switch (map['status']) {
      'pending' => NotificationCommandStatus.pending,
      'processing' => NotificationCommandStatus.processing,
      'succeeded' => NotificationCommandStatus.succeeded,
      'failed' => NotificationCommandStatus.failed,
      _ => throw const FormatException('Invalid notification command status.'),
    },
    result: map['result'] is Map
        ? Map<String, dynamic>.from(map['result'] as Map)
        : null,
    errorCode: map['errorCode'] as String?,
  );

  static Map<String, Object> pendingMap({
    required String type,
    required String requestedByUserId,
    required Map<String, Object> payload,
  }) => {
    'type': type,
    'requestedByUserId': requestedByUserId,
    'payload': payload,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  };
}
