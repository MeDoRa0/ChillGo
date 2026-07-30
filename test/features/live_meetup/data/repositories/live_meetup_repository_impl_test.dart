import 'dart:async';

import 'package:chillgo/features/live_meetup/data/datasources/firestore_live_meetup_datasource.dart';
import 'package:chillgo/features/live_meetup/data/models/live_meetup_status_model.dart';
import 'package:chillgo/features/live_meetup/data/repositories/live_meetup_repository_impl.dart';
import 'package:chillgo/features/live_meetup/domain/entities/live_meetup_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chillgo/features/live_meetup/domain/entities/live_location.dart';
import 'package:chillgo/features/live_meetup/domain/entities/meetup_point.dart';

import '../../live_meetup_test_helpers.dart';

class _Datasource extends Mock implements FirestoreLiveMeetupDatasource {}

void main() {
  test(
    'joins accepted roster with status and emits Not Updated attendees',
    () async {
      final datasource = _Datasource();
      final access = StreamController<LiveMeetupAccessSnapshot>();
      final rosters = StreamController<List<Map<String, dynamic>>>();
      final statuses = StreamController<List<LiveMeetupStatusModel>>();
      final locations = StreamController<List<LiveLocation>>();
      final points = StreamController<MeetupPoint?>();
      addTearDown(() async {
        await access.close();
        await rosters.close();
        await statuses.close();
        await locations.close();
        await points.close();
      });
      when(
        () => datasource.watchAccess('outing'),
      ).thenAnswer((_) => access.stream);
      when(
        () => datasource.watchAcceptedRoster('outing'),
      ).thenAnswer((_) => rosters.stream);
      when(
        () => datasource.watchStatuses('outing'),
      ).thenAnswer((_) => statuses.stream);
      when(
        () => datasource.watchLocations('outing'),
      ).thenAnswer((_) => locations.stream);
      when(
        () => datasource.watchMeetupPoint('outing'),
      ).thenAnswer((_) => points.stream);
      final repository = LiveMeetupRepositoryImpl(
        datasource: datasource,
        clock: FakeTrustedClock(),
      );
      final first = repository.watchMeetup('outing').first;
      final outing = {
        'crewId': 'crew',
        'status': 'meeting',
        'locationText': 'Cafe',
      };
      access.add(
        LiveMeetupAccessSnapshot(
          outing: outing,
          participant: const {'attendanceStatus': 'accepted'},
          isCrewMember: true,
        ),
      );
      rosters.add([
        {
          'outingId': 'outing',
          'crewId': 'crew',
          'userId': 'alice',
          'displayName': 'Alice',
          'username': 'alice',
        },
        {
          'outingId': 'outing',
          'crewId': 'crew',
          'userId': 'bob',
          'displayName': 'Bob',
          'username': 'bob',
        },
      ]);
      statuses.add([
        LiveMeetupStatusModel(
          outingId: 'outing',
          crewId: 'crew',
          userId: 'alice',
          value: LiveMeetupStatus.arrived,
          acceptedAt: DateTime.utc(2026, 7, 27),
          acceptedCommandId: 'command',
        ),
      ]);
      locations.add(const []);
      points.add(null);
      final snapshot = await first;
      expect(snapshot.attendees.first.status, LiveMeetupStatus.arrived);
      expect(snapshot.attendees.last.status, isNull);
      verifyNever(() => datasource.watchOuting('outing'));
    },
  );
}
