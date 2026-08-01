import 'dart:async';

import 'package:chillgo/features/live_meetup/domain/entities/device_location_sample.dart';
import 'package:chillgo/features/live_meetup/domain/entities/geo_coordinate.dart';
import 'package:chillgo/features/live_meetup/domain/entities/live_location_session.dart';
import 'package:chillgo/features/live_meetup/domain/entities/live_meetup_snapshot.dart';
import 'package:chillgo/features/live_meetup/domain/entities/live_meetup_status.dart';
import 'package:chillgo/features/live_meetup/domain/repositories/live_meetup_repository.dart';
import 'package:chillgo/features/live_meetup/domain/services/device_location_service.dart';
import 'package:chillgo/features/live_meetup/domain/services/trusted_clock.dart';
import 'package:chillgo/features/live_meetup/domain/services/map_provider.dart';
import 'package:chillgo/features/live_meetup/domain/services/live_meetup_transition_service.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';

class FakeLiveMeetupRepository implements LiveMeetupRepository {
  final snapshots = StreamController<LiveMeetupSnapshot>.broadcast();
  LiveMeetupCommandResult nextResult = const LiveMeetupCommandResult(
    commandId: 'command',
    status: LiveMeetupCommandStatus.succeeded,
  );
  LiveMeetupFailure? nextFailure;
  LiveMeetupStatus? submittedStatus;
  int publishedLocations = 0;
  int starts = 0;
  int stops = 0;

  @override
  Stream<LiveMeetupSnapshot> watchMeetup(String outingId) => snapshots.stream;

  @override
  Future<LiveMeetupCommandResult> setStatus(
    String outingId,
    LiveMeetupStatus status,
  ) async {
    submittedStatus = status;
    if (nextFailure case final failure?) throw failure;
    return nextResult;
  }

  @override
  Future<LiveMeetupCommandResult> publishLocation(
    String outingId,
    LiveLocationSession session,
    DeviceLocationSample sample,
  ) async {
    publishedLocations++;
    return nextResult;
  }

  @override
  Future<LiveMeetupCommandResult> setMeetupPoint(
    String outingId,
    GeoCoordinate coordinate,
    String confirmedLocationText,
  ) async => nextResult;
  @override
  Future<LiveMeetupCommandResult> startSharing(
    String outingId,
    LiveLocationSession session, {
    required bool transferExisting,
  }) async {
    starts++;
    return nextResult;
  }

  @override
  Future<LiveMeetupCommandResult> stopSharing(
    String outingId,
    LiveLocationSession session,
  ) async {
    stops++;
    return nextResult;
  }

  @override
  Stream<MeetupPointPreparation> watchMeetupPointPreparation(String outingId) =>
      const Stream.empty();

  Future<void> close() => snapshots.close();
}

class FakeTrustedClock implements TrustedClock {
  FakeTrustedClock([DateTime? now]) : value = now ?? DateTime.utc(2026, 7, 27);
  DateTime value;
  @override
  bool get isEstablished => true;
  @override
  DateTime get now => value;
  @override
  Future<void> dispose() async {}
  @override
  Future<void> establish() async {}
  @override
  Future<void> refresh() async {}
}

class FakeDeviceLocationService implements DeviceLocationService {
  final samples = StreamController<DeviceLocationSample>.broadcast();
  Stream<DeviceLocationSample>? streamOverride;
  bool enabled = true;
  DeviceLocationPermission permission = DeviceLocationPermission.whileInUse;
  DeviceLocationSample currentSample = DeviceLocationSample(
    coordinate: GeoCoordinate(latitude: 30, longitude: 31),
    accuracyMeters: 10,
    acquiredAtMonotonic: Duration.zero,
  );
  int currentPositionCalls = 0;
  int stopCalls = 0;
  @override
  Future<DeviceLocationPermission> checkPermission() async => permission;
  @override
  Future<DeviceLocationSample> currentPosition() async {
    currentPositionCalls++;
    return currentSample;
  }

  @override
  Future<bool> isServiceEnabled() async => enabled;
  @override
  Future<DeviceLocationPermission> requestPermission() async => permission;
  @override
  Future<void> stop() async => stopCalls++;
  @override
  Stream<DeviceLocationSample> watchPositions() =>
      streamOverride ?? samples.stream;
}

class FakeMapProvider implements MapProvider {
  List<PlaceCandidate> results = const [];
  GeoCoordinate resolvedCoordinate = GeoCoordinate(latitude: 30, longitude: 31);
  @override
  bool get isConfigured => true;
  @override
  Future<String?> reverseLabel(GeoCoordinate coordinate) async => 'Test point';
  @override
  Future<List<PlaceCandidate>> search(
    String query, {
    required String sessionToken,
    GeoCoordinate? bias,
  }) async => results;
  @override
  Future<PlaceCandidate> resolvePlace(
    PlaceCandidate candidate, {
    required String sessionToken,
  }) async => candidate.withCoordinate(resolvedCoordinate);
}

class FakeLiveMeetupTransitionService implements LiveMeetupTransitionService {
  LiveMeetupTransitionResult nextResult = const LiveMeetupTransitionResult(
    transitionId: 'transition',
    status: LiveMeetupTransitionStatus.succeeded,
  );
  String? lastOperation;
  String? lastOutingId;
  String? lastCrewId;
  String? lastUserId;
  OutingStatus? lastOutingStatus;

  @override
  Future<LiveMeetupTransitionResult> declineAttendance(String outingId) async {
    lastOperation = 'change_attendance';
    lastOutingId = outingId;
    return nextResult;
  }

  @override
  Future<LiveMeetupTransitionResult> deleteCrew(String crewId) async {
    lastOperation = 'delete_crew';
    lastCrewId = crewId;
    return nextResult;
  }

  @override
  Future<LiveMeetupTransitionResult> endOuting(
    String outingId,
    OutingStatus targetStatus,
  ) async {
    lastOperation = 'end_outing';
    lastOutingId = outingId;
    lastOutingStatus = targetStatus;
    return nextResult;
  }

  @override
  Future<LiveMeetupTransitionResult> removeMembership(
    String crewId,
    String userId,
  ) async {
    lastOperation = 'remove_membership';
    lastCrewId = crewId;
    lastUserId = userId;
    return nextResult;
  }

  @override
  Future<LiveMeetupTransitionResult> removeParticipant(
    String outingId,
    String userId,
  ) async {
    lastOperation = 'remove_participant';
    lastOutingId = outingId;
    lastUserId = userId;
    return nextResult;
  }
}
