import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/notification_session_coordinator.dart';
import '../../../domain/entities/device_alert.dart';
import '../../../domain/entities/notification.dart';
import '../../../domain/entities/notification_preferences.dart';
import '../../../domain/repositories/notification_repository.dart';

class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState({
    this.loading = true,
    this.saving = false,
    this.preferences = const NotificationPreferences(),
    this.capability = DeviceAlertCapability.notDetermined,
    this.message,
  });

  final bool loading;
  final bool saving;
  final NotificationPreferences preferences;
  final DeviceAlertCapability capability;
  final String? message;

  NotificationPreferencesState copyWith({
    bool? loading,
    bool? saving,
    NotificationPreferences? preferences,
    DeviceAlertCapability? capability,
    String? message,
    bool clearMessage = false,
  }) => NotificationPreferencesState(
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    preferences: preferences ?? this.preferences,
    capability: capability ?? this.capability,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [
    loading,
    saving,
    preferences,
    capability,
    message,
  ];
}

class NotificationPreferencesCubit extends Cubit<NotificationPreferencesState> {
  NotificationPreferencesCubit({
    required this.repository,
    required this.sessionCoordinator,
  }) : super(const NotificationPreferencesState());

  final NotificationRepository repository;
  final NotificationSessionCoordinator sessionCoordinator;
  StreamSubscription<NotificationPreferences>? _subscription;

  Future<void> watch() async {
    await _subscription?.cancel();
    final capability = await sessionCoordinator.capability();
    emit(state.copyWith(capability: capability));
    _subscription = repository.watchPreferences().listen(
      (preferences) => emit(
        state.copyWith(
          loading: false,
          preferences: preferences,
          clearMessage: true,
        ),
      ),
      onError: (Object error) => emit(
        state.copyWith(
          loading: false,
          message: error is NotificationFailure
              ? error.message
              : 'Notification preferences are unavailable.',
        ),
      ),
    );
  }

  Future<void> setVotingUpdates(bool enabled) =>
      _save(state.preferences.copyWith(votingUpdatesEnabled: enabled));

  Future<void> setOutingChanges(bool enabled) =>
      _save(state.preferences.copyWith(outingChangesEnabled: enabled));

  Future<void> setArrivalAlerts(bool enabled) =>
      _save(state.preferences.copyWith(arrivalAlertsEnabled: enabled));

  Future<void> requestDeviceAlerts() async {
    final capability = await sessionCoordinator.requestPermission();
    emit(state.copyWith(capability: capability));
  }

  Future<void> _save(NotificationPreferences preferences) async {
    final previous = state.preferences;
    emit(
      state.copyWith(
        preferences: preferences,
        saving: true,
        clearMessage: true,
      ),
    );
    try {
      await repository.updatePreferences(preferences);
      emit(state.copyWith(saving: false));
    } catch (error) {
      emit(
        state.copyWith(
          preferences: previous,
          saving: false,
          message: error is NotificationFailure
              ? error.message
              : 'Could not save notification preferences.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
