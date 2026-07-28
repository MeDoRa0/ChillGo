import 'package:bloc_test/bloc_test.dart';
import 'package:chillgo/features/live_meetup/domain/entities/attendee_meetup_state.dart';
import 'package:chillgo/features/live_meetup/domain/entities/live_meetup_snapshot.dart';
import 'package:chillgo/features/live_meetup/domain/entities/live_meetup_status.dart';
import 'package:chillgo/features/live_meetup/domain/repositories/live_meetup_repository.dart';
import 'package:chillgo/features/live_meetup/presentation/cubit/live_meetup/live_meetup_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../live_meetup_test_helpers.dart';

void main() {
  late FakeLiveMeetupRepository repository;
  setUp(() => repository = FakeLiveMeetupRepository());
  tearDown(() => repository.close());

  blocTest<LiveMeetupCubit, LiveMeetupState>(
    'loads a snapshot and reports successful status submission',
    build: () => LiveMeetupCubit(repository: repository),
    act: (cubit) async {
      await cubit.watch('outing');
      repository.snapshots.add(
        LiveMeetupSnapshot(
          outingId: 'outing',
          crewId: 'crew',
          locationText: 'Cafe',
          attendees: const [
            AttendeeMeetupState(
              userId: 'user',
              displayName: 'User',
              username: 'user',
            ),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await cubit.setStatus(LiveMeetupStatus.arrived);
    },
    verify: (_) => expect(repository.submittedStatus, LiveMeetupStatus.arrived),
    expect: () => [
      isA<LiveMeetupState>().having(
        (state) => state.status,
        'status',
        LiveMeetupViewStatus.loading,
      ),
      isA<LiveMeetupState>().having(
        (state) => state.status,
        'status',
        LiveMeetupViewStatus.ready,
      ),
      isA<LiveMeetupState>().having(
        (state) => state.statusMutation,
        'mutation',
        StatusMutationState.submitting,
      ),
      isA<LiveMeetupState>().having(
        (state) => state.statusMutation,
        'mutation',
        StatusMutationState.succeeded,
      ),
    ],
  );

  blocTest<LiveMeetupCubit, LiveMeetupState>(
    'erases protected snapshot before access-lost state',
    build: () => LiveMeetupCubit(repository: repository),
    act: (cubit) async {
      await cubit.watch('outing');
      repository.snapshots.addError(const LiveMeetupAccessDenied());
    },
    wait: Duration.zero,
    expect: () => [
      isA<LiveMeetupState>(),
      isA<LiveMeetupState>()
          .having(
            (state) => state.status,
            'status',
            LiveMeetupViewStatus.accessLost,
          )
          .having((state) => state.snapshot, 'snapshot', isNull),
    ],
  );
}
