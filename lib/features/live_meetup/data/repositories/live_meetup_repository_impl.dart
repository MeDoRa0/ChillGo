import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../outings/domain/entities/attendance_status.dart';
import '../../../outings/domain/entities/outing_status.dart';
import '../../domain/entities/attendee_meetup_state.dart';
import '../../domain/entities/device_location_sample.dart';
import '../../domain/entities/geo_coordinate.dart';
import '../../domain/entities/live_location_session.dart';
import '../../domain/entities/live_meetup_snapshot.dart';
import '../../domain/entities/live_meetup_status.dart';
import '../../domain/repositories/live_meetup_repository.dart';
import '../../domain/services/live_meetup_access_policy.dart';
import '../../domain/services/live_location_freshness_policy.dart';
import '../../domain/services/trusted_clock.dart';
import '../../domain/entities/live_location.dart';
import '../../domain/entities/meetup_point.dart';
import '../datasources/firestore_live_meetup_datasource.dart';
import '../models/live_meetup_status_model.dart';

class LiveMeetupRepositoryImpl implements LiveMeetupRepository {
  LiveMeetupRepositoryImpl({
    required this.datasource,
    required this.clock,
    this.accessPolicy = const LiveMeetupAccessPolicy(),
  }) : freshnessPolicy = LiveLocationFreshnessPolicy(clock);

  final FirestoreLiveMeetupDatasource datasource;
  final TrustedClock clock;
  final LiveMeetupAccessPolicy accessPolicy;
  final LiveLocationFreshnessPolicy freshnessPolicy;

  @override
  Stream<LiveMeetupSnapshot> watchMeetup(String outingId) {
    late StreamController<LiveMeetupSnapshot> controller;
    StreamSubscription? accessSubscription;
    StreamSubscription? rosterSubscription;
    StreamSubscription? statusSubscription;
    StreamSubscription? locationSubscription;
    StreamSubscription? pointSubscription;
    Timer? expiryTimer;
    Map<String, dynamic>? outing;
    List<Map<String, dynamic>>? roster;
    List<LiveMeetupStatusModel>? statuses;
    List<LiveLocation>? locations;
    MeetupPoint? meetupPoint;
    bool pointLoaded = false;
    bool allowed = false;
    bool protecting = false;

    void emit() {
      if (!allowed ||
          outing == null ||
          roster == null ||
          statuses == null ||
          locations == null ||
          !pointLoaded) {
        return;
      }
      expiryTimer?.cancel();
      final crewId = outing!['crewId'];
      final locationText = outing!['locationText'];
      if (crewId is! String || locationText is! String) {
        controller.addError(const LiveMeetupAccessDenied());
        return;
      }
      final statusByUser = {
        for (final status in statuses!)
          if (status.outingId == outingId && status.crewId == crewId)
            status.userId: status,
      };
      final freshLocations = freshnessPolicy.fresh(locations!);
      final locationByUser = {
        for (final location in freshLocations)
          if (location.outingId == outingId && location.crewId == crewId)
            location.userId: location,
      };
      final attendees = <AttendeeMeetupState>[];
      for (final participant in roster!) {
        final userId = participant['userId'];
        final displayName = participant['displayName'];
        final username = participant['username'];
        if (userId is! String ||
            displayName is! String ||
            username is! String ||
            participant['crewId'] != crewId) {
          continue;
        }
        final status = statusByUser[userId];
        attendees.add(
          AttendeeMeetupState(
            userId: userId,
            displayName: displayName,
            username: username,
            avatarUrl: participant['avatarUrl'] as String?,
            status: status?.value,
            statusAcceptedAt: status?.acceptedAt,
            location: locationByUser[userId],
          ),
        );
      }
      controller.add(
        LiveMeetupSnapshot(
          outingId: outingId,
          crewId: crewId,
          locationText: locationText,
          attendees: attendees,
          meetupPoint:
              meetupPoint?.outingId == outingId &&
                  meetupPoint?.crewId == crewId &&
                  meetupPoint?.locationTextSnapshot == locationText
              ? meetupPoint
              : null,
        ),
      );
      final next = freshnessPolicy.durationUntilNextExpiry(freshLocations);
      if (next != null) expiryTimer = Timer(next, emit);
    }

    Future<void> protect(Object error, StackTrace stack) {
      if (protecting) return Future.value();
      protecting = true;
      allowed = false;
      outing = null;
      roster = null;
      statuses = null;
      locations = null;
      meetupPoint = null;
      pointLoaded = false;
      expiryTimer?.cancel();
      final subscriptions = [
        accessSubscription,
        rosterSubscription,
        statusSubscription,
        locationSubscription,
        pointSubscription,
      ].whereType<StreamSubscription>();
      accessSubscription = null;
      rosterSubscription = null;
      statusSubscription = null;
      locationSubscription = null;
      pointSubscription = null;
      for (final subscription in subscriptions) {
        unawaited(subscription.cancel());
      }
      controller.addError(_mapError(error), stack);
      return Future.value();
    }

    controller = StreamController<LiveMeetupSnapshot>(
      onListen: () {
        if (!clock.isEstablished) {
          unawaited(
            clock.establish().catchError((Object error, StackTrace stack) {
              return protect(error, stack);
            }),
          );
        }
        accessSubscription = datasource.watchAccess(outingId).listen((
          snapshot,
        ) {
          final access = accessPolicy.participantAccess(
            outingStatus: OutingStatus.fromValue(snapshot.outing['status']),
            attendanceStatus: AttendanceStatus.fromValue(
              snapshot.participant['attendanceStatus'] as String,
            ),
            isCrewMember: snapshot.isCrewMember,
            isParticipant: true,
            cleanupPending:
                snapshot.outing['liveMeetupCleanupPending'] == true ||
                snapshot.participant['liveMeetupCleanupPending'] == true,
            deletionPending: snapshot.outing['deletionPending'] == true,
          );
          if (access == LiveMeetupAccess.denied) {
            unawaited(
              protect(const LiveMeetupAccessDenied(), StackTrace.current),
            );
            return;
          }
          outing = snapshot.outing;
          allowed = true;
          emit();
        }, onError: protect);
        rosterSubscription = datasource.watchAcceptedRoster(outingId).listen((
          value,
        ) {
          roster = value;
          emit();
        }, onError: protect);
        statusSubscription = datasource.watchStatuses(outingId).listen((value) {
          statuses = value;
          emit();
        }, onError: protect);
        locationSubscription = datasource.watchLocations(outingId).listen((
          value,
        ) {
          locations = value;
          if (clock.isEstablished) emit();
        }, onError: protect);
        pointSubscription = datasource.watchMeetupPoint(outingId).listen((
          value,
        ) {
          meetupPoint = value;
          pointLoaded = true;
          emit();
        }, onError: protect);
      },
      onCancel: () async {
        await accessSubscription?.cancel();
        await rosterSubscription?.cancel();
        await statusSubscription?.cancel();
        await locationSubscription?.cancel();
        await pointSubscription?.cancel();
        expiryTimer?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<LiveMeetupCommandResult> setStatus(
    String outingId,
    LiveMeetupStatus status,
  ) => datasource.submit(
    outingId: outingId,
    type: 'set_status',
    payload: {'value': status.value},
  );

  @override
  Future<LiveMeetupCommandResult> startSharing(
    String outingId,
    LiveLocationSession session, {
    required bool transferExisting,
  }) => datasource.submit(
    outingId: outingId,
    type: 'start_sharing',
    payload: {
      'sessionId': session.sessionId,
      'sessionToken': session.sessionToken,
      'deviceSessionId': session.deviceSessionId,
      'transferExisting': transferExisting,
    },
  );

  @override
  Future<LiveMeetupCommandResult> publishLocation(
    String outingId,
    LiveLocationSession session,
    DeviceLocationSample sample,
  ) => datasource.submit(
    outingId: outingId,
    type: 'publish_location',
    payload: {
      'sessionId': session.sessionId,
      'sessionToken': session.sessionToken,
      'latitude': sample.coordinate.latitude,
      'longitude': sample.coordinate.longitude,
      'accuracyMeters': sample.accuracyMeters,
      'sampleAgeMillis': 0,
    },
  );

  @override
  Future<LiveMeetupCommandResult> stopSharing(
    String outingId,
    LiveLocationSession session,
  ) => datasource.submit(
    outingId: outingId,
    type: 'stop_sharing',
    payload: {
      'sessionId': session.sessionId,
      'sessionToken': session.sessionToken,
    },
  );

  @override
  Future<LiveMeetupCommandResult> setMeetupPoint(
    String outingId,
    GeoCoordinate coordinate,
    String confirmedLocationText,
  ) => datasource.submit(
    outingId: outingId,
    type: 'set_meetup_point',
    payload: {
      'latitude': coordinate.latitude,
      'longitude': coordinate.longitude,
      'locationTextSnapshot': confirmedLocationText,
    },
  );

  @override
  Stream<MeetupPointPreparation> watchMeetupPointPreparation(String outingId) =>
      _watchPreparation(outingId);

  Stream<MeetupPointPreparation> _watchPreparation(String outingId) {
    late StreamController<MeetupPointPreparation> controller;
    StreamSubscription? outingSubscription;
    StreamSubscription? pointSubscription;
    String? locationText;
    MeetupPoint? point;
    bool pointLoaded = false;

    void emit() {
      final text = locationText;
      if (text != null && pointLoaded) {
        controller.add(
          MeetupPointPreparation(
            locationText: text,
            point: point?.locationTextSnapshot == text ? point : null,
          ),
        );
      }
    }

    controller = StreamController<MeetupPointPreparation>(
      onListen: () {
        outingSubscription = datasource.watchOuting(outingId).listen((outing) {
          final value = outing['locationText'];
          if (value is! String || value.isEmpty) {
            controller.addError(const LiveMeetupAccessDenied());
            return;
          }
          locationText = value;
          emit();
        }, onError: controller.addError);
        pointSubscription = datasource.watchMeetupPoint(outingId).listen((
          value,
        ) {
          point = value;
          pointLoaded = true;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await outingSubscription?.cancel();
        await pointSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  LiveMeetupFailure _mapError(Object error) {
    if (error is LiveMeetupFailure) return error;
    if (error is FirebaseException &&
        [
          'permission-denied',
          'unauthenticated',
          'not-found',
        ].contains(error.code)) {
      return const LiveMeetupAccessDenied();
    }
    if (error is FirebaseException &&
        ['unavailable', 'deadline-exceeded', 'aborted'].contains(error.code)) {
      return const LiveMeetupOfflineFailure();
    }
    return const LiveMeetupServiceFailure();
  }
}
