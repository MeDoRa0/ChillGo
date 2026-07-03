import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:chillgo/features/crews/presentation/blocs/invitations/invitations_cubit.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/crews/domain/entities/crew_invitation.dart';

class MockCrewRepository extends Mock implements CrewRepository {}

final _fakeInvitation = CrewInvitation(
  id: 'crew1_bob',
  crewId: 'crew1',
  invitedUserId: 'bob',
  invitedByUserId: 'alice',
  createdAt: DateTime.utc(2026, 7, 1),
  crewName: 'Weekend Hikers',
  invitedByUsername: 'alice_cool',
  invitedByDisplayName: 'Alice',
);

void main() {
  late MockCrewRepository mockRepo;

  setUp(() {
    mockRepo = MockCrewRepository();
  });

  group('InvitationsCubit', () {
    blocTest<InvitationsCubit, InvitationsState>(
      'emits [InvitationsLoading, InvitationsLoaded] when stream emits invitations',
      build: () {
        when(
          () => mockRepo.streamReceivedInvitations(),
        ).thenAnswer((_) => Stream.value([_fakeInvitation]));
        return InvitationsCubit(crewRepository: mockRepo);
      },
      act: (cubit) => cubit.loadInvitations(),
      expect: () => <InvitationsState>[
        const InvitationsLoading(),
        InvitationsLoaded([_fakeInvitation]),
      ],
    );

    blocTest<InvitationsCubit, InvitationsState>(
      'emits [InvitationsLoading, InvitationsError] when stream emits error',
      build: () {
        when(
          () => mockRepo.streamReceivedInvitations(),
        ).thenAnswer((_) => Stream.error(Exception('Network error')));
        return InvitationsCubit(crewRepository: mockRepo);
      },
      act: (cubit) => cubit.loadInvitations(),
      expect: () => <dynamic>[
        const InvitationsLoading(),
        isA<InvitationsError>(),
      ],
    );

    blocTest<InvitationsCubit, InvitationsState>(
      'optimistically removes invitation after accepting invitation',
      build: () {
        when(
          () => mockRepo.streamReceivedInvitations(),
        ).thenAnswer((_) => Stream.value([_fakeInvitation]));
        when(() => mockRepo.acceptInvitation(any())).thenAnswer((_) async {});
        return InvitationsCubit(crewRepository: mockRepo);
      },
      act: (cubit) async {
        cubit.loadInvitations();
        await Future<void>.delayed(Duration.zero);
        await cubit.acceptInvitation('crew1_bob');
      },
      expect: () => <InvitationsState>[
        const InvitationsLoading(),
        InvitationsLoaded([_fakeInvitation]),
        const InvitationActionInProgress(),
        const InvitationsLoaded([]),
      ],
    );

    blocTest<InvitationsCubit, InvitationsState>(
      'optimistically removes invitation after rejecting invitation',
      build: () {
        when(
          () => mockRepo.streamReceivedInvitations(),
        ).thenAnswer((_) => Stream.value([_fakeInvitation]));
        when(() => mockRepo.rejectInvitation(any())).thenAnswer((_) async {});
        return InvitationsCubit(crewRepository: mockRepo);
      },
      act: (cubit) async {
        cubit.loadInvitations();
        await Future<void>.delayed(Duration.zero);
        await cubit.rejectInvitation('crew1_bob');
      },
      expect: () => <InvitationsState>[
        const InvitationsLoading(),
        InvitationsLoaded([_fakeInvitation]),
        const InvitationActionInProgress(),
        const InvitationsLoaded([]),
      ],
    );

    blocTest<InvitationsCubit, InvitationsState>(
      'emits [InvitationActionInProgress, InvitationActionError] when accept fails',
      build: () {
        when(
          () => mockRepo.streamReceivedInvitations(),
        ).thenAnswer((_) => Stream.value([_fakeInvitation]));
        when(
          () => mockRepo.acceptInvitation(any()),
        ).thenThrow(Exception('accept-failed'));
        return InvitationsCubit(crewRepository: mockRepo);
      },
      act: (cubit) async {
        cubit.loadInvitations();
        await Future<void>.delayed(Duration.zero);
        await cubit.acceptInvitation('crew1_bob');
      },
      expect: () => <dynamic>[
        const InvitationsLoading(),
        InvitationsLoaded([_fakeInvitation]),
        const InvitationActionInProgress(),
        isA<InvitationActionError>(),
      ],
    );
  });
}
