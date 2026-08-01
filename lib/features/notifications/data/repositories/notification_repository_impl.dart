import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/device_alert.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/notification_page.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/firestore_notifications_datasource.dart';
import '../models/notification_command_model.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required this.datasource});

  final FirestoreNotificationsDatasource datasource;

  @override
  Stream<NotificationPage> watchNewest() => datasource
      .watchNewest()
      .map(
        (page) =>
            NotificationPage(items: page.items, nextCursor: page.nextCursor),
      )
      .transform(_protectingTransformer<NotificationPage>());

  @override
  Future<NotificationPage> loadOlder(NotificationCursor cursor) async {
    try {
      final page = await datasource.loadOlder(cursor);
      return NotificationPage(items: page.items, nextCursor: page.nextCursor);
    } on NotificationFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Stream<UnreadNotificationSummary> watchUnreadSummary() => datasource
      .watchSummary()
      .map<UnreadNotificationSummary>((summary) => summary)
      .transform(_protectingTransformer<UnreadNotificationSummary>());

  @override
  Future<void> markRead(String notificationId) async {
    final command = await _submit('mark_read', {
      'notificationId': notificationId,
    });
    _throwIfFailed(command);
  }

  @override
  Future<NotificationOpenResult> open(String notificationId) async {
    try {
      final command = await _submit('open', {'notificationId': notificationId});
      if (command.status == NotificationCommandStatus.failed) {
        return NotificationOpenResult.unavailable(
          _unavailableReason(command.errorCode),
        );
      }
      final target = command.result?['target'];
      if (target is! Map) {
        return const NotificationOpenResult.unavailable(
          NotificationUnavailableReason.serviceUnavailable,
        );
      }
      return NotificationOpenResult.opened(
        notificationTargetFromMap(Map<String, dynamic>.from(target)),
      );
    } on NotificationAuthenticationFailure {
      return const NotificationOpenResult.unavailable(
        NotificationUnavailableReason.signInRequired,
      );
    } on NotificationFailure {
      return const NotificationOpenResult.unavailable(
        NotificationUnavailableReason.serviceUnavailable,
      );
    } on FirebaseException {
      return const NotificationOpenResult.unavailable(
        NotificationUnavailableReason.serviceUnavailable,
      );
    } on FormatException {
      return const NotificationOpenResult.unavailable(
        NotificationUnavailableReason.serviceUnavailable,
      );
    }
  }

  @override
  Stream<NotificationPreferences> watchPreferences() => datasource
      .watchPreferences()
      .map<NotificationPreferences>((preferences) => preferences)
      .transform(_protectingTransformer<NotificationPreferences>());

  @override
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      await datasource.updatePreferences(preferences);
    } on NotificationFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> registerDevice(DeviceRegistrationTarget target) async {
    final command = await _submit('register_device', {
      'installationId': target.installationId,
      'token': target.token,
      'platform': target.platform.name,
      'permissionState': 'granted',
    });
    _throwIfFailed(command);
  }

  @override
  Future<void> unregisterDevice(String installationId) async {
    final command = await _submit('unregister_device', {
      'installationId': installationId,
    });
    _throwIfFailed(command);
  }

  @override
  void clearProtectedState() {}

  Future<NotificationCommandModel> _submit(
    String type,
    Map<String, Object> payload,
  ) async {
    try {
      return await datasource.submitCommand(type: type, payload: payload);
    } on NotificationFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw _mapError(error);
    }
  }

  void _throwIfFailed(NotificationCommandModel command) {
    if (command.status != NotificationCommandStatus.failed) return;
    throw switch (command.errorCode) {
      'unauthenticated' => const NotificationAuthenticationFailure(),
      'expired' => const NotificationExpiredFailure(),
      'unavailable' ||
      'not_found' ||
      'permission_denied' => const NotificationUnavailableFailure(),
      _ => const NotificationServiceFailure(),
    };
  }

  NotificationUnavailableReason _unavailableReason(String? code) =>
      switch (code) {
        'unauthenticated' => NotificationUnavailableReason.signInRequired,
        'expired' => NotificationUnavailableReason.expired,
        'unavailable' ||
        'not_found' ||
        'permission_denied' => NotificationUnavailableReason.unavailable,
        _ => NotificationUnavailableReason.serviceUnavailable,
      };

  StreamTransformer<T, T> _protectingTransformer<T>() =>
      StreamTransformer.fromHandlers(
        handleError: (Object error, StackTrace stack, EventSink<T> sink) {
          clearProtectedState();
          sink.addError(_mapError(error), stack);
        },
      );

  Object _mapError(Object error) {
    if (error is NotificationFailure) return error;
    if (error is FirebaseException) {
      return switch (error.code) {
        'unauthenticated' => const NotificationAuthenticationFailure(),
        'permission-denied' ||
        'not-found' => const NotificationUnavailableFailure(),
        _ => const NotificationServiceFailure(),
      };
    }
    return error;
  }
}
