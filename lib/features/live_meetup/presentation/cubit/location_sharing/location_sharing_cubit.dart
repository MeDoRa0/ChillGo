import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/live_location_sharing_coordinator.dart';
import '../../../domain/repositories/live_meetup_repository.dart';

enum LocationSharingStatus {
  off,
  starting,
  transferConfirmation,
  active,
  paused,
  publishing,
  stopping,
  accessLost,
  failed,
}

class LocationSharingState extends Equatable {
  const LocationSharingState({
    this.status = LocationSharingStatus.off,
    this.failure,
  });
  final LocationSharingStatus status;
  final LiveMeetupFailure? failure;
  @override
  List<Object?> get props => [status, failure];
}

class LocationSharingCubit extends Cubit<LocationSharingState> {
  LocationSharingCubit({required this.coordinator})
    : super(const LocationSharingState()) {
    _subscription = coordinator.events.listen(_onEvent);
  }
  final LiveLocationSharingCoordinator coordinator;
  late final StreamSubscription<SharingEvent> _subscription;
  String? _outingId;
  bool _accessLost = false;

  Future<void> start(String outingId, {bool transferExisting = false}) async {
    if (_accessLost) return;
    _outingId = outingId;
    await coordinator.start(outingId, transferExisting: transferExisting);
  }

  Future<void> confirmTransfer() async {
    final outingId = _outingId;
    if (outingId != null) {
      await coordinator.start(outingId, transferExisting: true);
    }
  }

  Future<void> stop() async {
    final outingId = _outingId;
    if (outingId == null) return;
    emit(const LocationSharingState(status: LocationSharingStatus.stopping));
    await coordinator.stop(outingId);
  }

  void accessLost() {
    final outingId = _outingId;
    _outingId = null;
    _accessLost = true;
    if (outingId != null) unawaited(coordinator.stop(outingId));
    emit(const LocationSharingState(status: LocationSharingStatus.accessLost));
  }

  void _onEvent(SharingEvent event) {
    if (_accessLost) return;
    final status = switch (event.type) {
      SharingEventType.starting => LocationSharingStatus.starting,
      SharingEventType.active => LocationSharingStatus.active,
      SharingEventType.paused => LocationSharingStatus.paused,
      SharingEventType.published => LocationSharingStatus.active,
      SharingEventType.transferRequired =>
        LocationSharingStatus.transferConfirmation,
      SharingEventType.stopped => LocationSharingStatus.off,
      SharingEventType.failed => LocationSharingStatus.failed,
      SharingEventType.accessLost => LocationSharingStatus.accessLost,
    };
    emit(LocationSharingState(status: status, failure: event.failure));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
