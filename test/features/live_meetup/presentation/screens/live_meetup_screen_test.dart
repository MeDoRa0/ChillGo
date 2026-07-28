import 'dart:async';

import 'package:chillgo/features/live_meetup/domain/entities/attendee_meetup_state.dart';
import 'package:chillgo/features/live_meetup/domain/entities/live_meetup_snapshot.dart';
import 'package:chillgo/features/live_meetup/domain/repositories/live_meetup_repository.dart';
import 'package:chillgo/features/live_meetup/presentation/cubit/live_meetup/live_meetup_cubit.dart';
import 'package:chillgo/features/live_meetup/presentation/screens/live_meetup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chillgo/features/live_meetup/data/services/live_location_sharing_coordinator.dart';
import 'package:chillgo/features/live_meetup/presentation/cubit/location_sharing/location_sharing_cubit.dart';
import 'package:chillgo/features/live_meetup/presentation/cubit/meetup_point_editor/meetup_point_editor_cubit.dart';

import '../../live_meetup_test_helpers.dart';

class _Coordinator extends Mock implements LiveLocationSharingCoordinator {}

void main() {
  testWidgets('shows all status groups including Not Updated', (tester) async {
    final repository = FakeLiveMeetupRepository();
    addTearDown(repository.close);
    final cubit = LiveMeetupCubit(repository: repository);
    final deviceLocation = FakeDeviceLocationService();
    final coordinator = LiveLocationSharingCoordinator(
      repository: repository,
      locationService: deviceLocation,
    );
    final sharingCubit = LocationSharingCubit(coordinator: coordinator);
    final editorCubit = MeetupPointEditorCubit(
      repository: repository,
      mapProvider: FakeMapProvider(),
    );
    addTearDown(() async {
      await cubit.close();
      await sharingCubit.close();
      await editorCubit.close();
      await coordinator.dispose();
      await deviceLocation.samples.close();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: sharingCubit),
            BlocProvider.value(value: editorCubit),
          ],
          child: const LiveMeetupScreen(outingId: 'outing'),
        ),
      ),
    );
    await cubit.watch('outing');
    repository.snapshots.add(
      LiveMeetupSnapshot(
        outingId: 'outing',
        crewId: 'crew',
        locationText: 'Cafe',
        attendees: const [
          AttendeeMeetupState(
            userId: 'user',
            displayName: 'Alice',
            username: 'alice',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('live-meetup-status-selector')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('start-location-sharing')), findsOneWidget);
    expect(find.textContaining('Sharing is off by default'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Not Updated'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Getting Ready'), findsWidgets);
    expect(find.text('On My Way'), findsWidgets);
    expect(find.text('Arrived'), findsWidgets);
    expect(find.text('Not Updated'), findsOneWidget);
  });

  testWidgets(
    'clears protected UI and local sharing capability before access-lost UI',
    (tester) async {
      final repository = FakeLiveMeetupRepository();
      final cubit = LiveMeetupCubit(repository: repository);
      final events = StreamController<SharingEvent>.broadcast();
      final coordinator = _Coordinator();
      when(() => coordinator.events).thenAnswer((_) => events.stream);
      when(
        () => coordinator.start(
          any(),
          transferExisting: any(named: 'transferExisting'),
        ),
      ).thenAnswer((_) async {});
      when(() => coordinator.stop(any())).thenAnswer((_) async {});
      final sharingCubit = LocationSharingCubit(coordinator: coordinator);
      final editorCubit = MeetupPointEditorCubit(
        repository: repository,
        mapProvider: FakeMapProvider(),
      );
      addTearDown(() async {
        await cubit.close();
        await sharingCubit.close();
        await editorCubit.close();
        await repository.close();
        await events.close();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cubit),
              BlocProvider.value(value: sharingCubit),
              BlocProvider.value(value: editorCubit),
            ],
            child: const LiveMeetupScreen(outingId: 'outing'),
          ),
        ),
      );
      await cubit.watch('outing');
      repository.snapshots.add(
        LiveMeetupSnapshot(
          outingId: 'outing',
          crewId: 'crew',
          locationText: 'Private Cafe',
          attendees: const [
            AttendeeMeetupState(
              userId: 'alice',
              displayName: 'Alice',
              username: 'alice',
            ),
          ],
        ),
      );
      await tester.pump();
      await sharingCubit.start('outing');
      repository.snapshots.addError(const LiveMeetupAccessDenied());

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Live Meetup is no longer available.'), findsOneWidget);
      expect(find.text('Private Cafe'), findsNothing);
      expect(find.text('Alice'), findsNothing);
      expect(
        find.byKey(const Key('live-meetup-status-selector')),
        findsNothing,
      );
      expect(sharingCubit.state.status, LocationSharingStatus.accessLost);
      expect(editorCubit.state.status, MeetupPointEditorStatus.unavailable);
      verify(() => coordinator.stop('outing')).called(1);
    },
  );
}
