import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notification_preferences.dart';

class NotificationPreferencesModel extends NotificationPreferences {
  const NotificationPreferencesModel({
    super.votingUpdatesEnabled,
    super.outingChangesEnabled,
    super.arrivalAlertsEnabled,
  });

  factory NotificationPreferencesModel.fromMap(Map<String, dynamic>? map) =>
      NotificationPreferencesModel(
        votingUpdatesEnabled: map?['votingUpdatesEnabled'] as bool? ?? true,
        outingChangesEnabled: map?['outingChangesEnabled'] as bool? ?? true,
        arrivalAlertsEnabled: map?['arrivalAlertsEnabled'] as bool? ?? true,
      );

  static Map<String, Object> toMap(NotificationPreferences preferences) => {
    'votingUpdatesEnabled': preferences.votingUpdatesEnabled,
    'outingChangesEnabled': preferences.outingChangesEnabled,
    'arrivalAlertsEnabled': preferences.arrivalAlertsEnabled,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
