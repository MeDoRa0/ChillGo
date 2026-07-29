import 'dart:async';

import 'package:chillgo/features/live_meetup/data/services/live_location_sharing_coordinator.dart';
import 'package:chillgo/features/live_meetup/domain/repositories/live_meetup_repository.dart';
import 'package:chillgo/features/live_meetup/presentation/cubit/location_sharing/location_sharing_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Coordinator extends Mock implements LiveLocationSharingCoordinator {}

void main() {
  late _Coordinator coordinator;
  late StreamController<SharingEvent> events;

  setUp(() {
    coordinator = _Coordinator();
    events = StreamController<SharingEvent>.broadcast();
    when(() => coordinator.events).thenAnswer((_) => events.stream);
    when(
      () => coordinator.start(
        any(),
        transferExisting: any(named: 'transferExisting'),
      ),
    ).thenAnswer((_) async {});
    when(() => coordinator.stop(any())).thenAnswer((_) async {});
  });

  tearDown(() => events.close());

  test(
    'sharing stays off until explicit start and exposes transfer flow',
    () async {
      final cubit = LocationSharingCubit(coordinator: coordinator);
      addTearDown(cubit.close);
      expect(cubit.state.status, LocationSharingStatus.off);
      await cubit.start('outing');
      verify(
        () => coordinator.start('outing', transferExisting: false),
      ).called(1);
      events.add(
        const SharingEvent(
          SharingEventType.transferRequired,
          failure: LiveMeetupTransferRequired(),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, LocationSharingStatus.transferConfirmation);
      await cubit.confirmTransfer();
      verify(
        () => coordinator.start('outing', transferExisting: true),
      ).called(1);
    },
  );

  test(
    'active, paused, stopped, and access-lost events are terminal-safe',
    () async {
      final cubit = LocationSharingCubit(coordinator: coordinator);
      addTearDown(cubit.close);
      await cubit.start('outing');
      events.add(const SharingEvent(SharingEventType.active));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, LocationSharingStatus.active);
      events.add(const SharingEvent(SharingEventType.paused));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, LocationSharingStatus.paused);
      await cubit.stop();
      verify(() => coordinator.stop('outing')).called(1);
      events.add(
        const SharingEvent(
          SharingEventType.accessLost,
          failure: LiveMeetupAccessDenied(),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, LocationSharingStatus.accessLost);
    },
  );
}
