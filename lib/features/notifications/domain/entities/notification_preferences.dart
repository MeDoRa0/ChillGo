import 'package:equatable/equatable.dart';

class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.votingUpdatesEnabled = true,
    this.outingChangesEnabled = true,
    this.arrivalAlertsEnabled = true,
  });
  final bool votingUpdatesEnabled;
  final bool outingChangesEnabled;
  final bool arrivalAlertsEnabled;
  NotificationPreferences copyWith({
    bool? votingUpdatesEnabled,
    bool? outingChangesEnabled,
    bool? arrivalAlertsEnabled,
  }) => NotificationPreferences(
    votingUpdatesEnabled: votingUpdatesEnabled ?? this.votingUpdatesEnabled,
    outingChangesEnabled: outingChangesEnabled ?? this.outingChangesEnabled,
    arrivalAlertsEnabled: arrivalAlertsEnabled ?? this.arrivalAlertsEnabled,
  );
  @override
  List<Object?> get props => [
    votingUpdatesEnabled,
    outingChangesEnabled,
    arrivalAlertsEnabled,
  ];
}
