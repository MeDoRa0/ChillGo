import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:chillgo/features/crews/presentation/blocs/crews_list/crews_list_cubit.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';

class MockCrewRepository extends Mock implements CrewRepository {}

final _fakeCrew = Crew(
  id: 'crew1',
  name: 'Weekend Hikers',
  ownerId: 'alice',
  createdAt: DateTime.utc(2026, 7, 1),
);

void main() {
  late MockCrewRepository mockRepo;

  setUp(() {
    mockRepo = MockCrewRepository();
  });

  group('CrewsListCubit', () {
    blocTest<CrewsListCubit, CrewsListState>(
      'emits [CrewsListLoading, CrewsListLoaded] when stream emits crews',
      build: () {
        when(
          () => mockRepo.streamCrews(),
        ).thenAnswer((_) => Stream.value([_fakeCrew]));
        return CrewsListCubit(crewRepository: mockRepo);
      },
      act: (cubit) => cubit.loadCrews(),
      expect: () => <CrewsListState>[
        const CrewsListLoading(),
        CrewsListLoaded([_fakeCrew]),
      ],
    );

    blocTest<CrewsListCubit, CrewsListState>(
      'emits [CrewsListLoading, CrewsListError] when stream emits error',
      build: () {
        when(
          () => mockRepo.streamCrews(),
        ).thenAnswer((_) => Stream.error(Exception('Firestore error')));
        return CrewsListCubit(crewRepository: mockRepo);
      },
      act: (cubit) => cubit.loadCrews(),
      expect: () => <dynamic>[const CrewsListLoading(), isA<CrewsListError>()],
    );

    blocTest<CrewsListCubit, CrewsListState>(
      'emits [CrewsListLoading, CrewsListLoaded, CrewCreating, CrewCreated] '
      'when createCrew succeeds',
      build: () {
        when(
          () => mockRepo.streamCrews(),
        ).thenAnswer((_) => Stream.value([_fakeCrew]));
        when(() => mockRepo.createCrew(any())).thenAnswer((_) async => 'crew1');
        when(() => mockRepo.inviteUser(any(), any())).thenAnswer((_) async {});
        return CrewsListCubit(crewRepository: mockRepo);
      },
      act: (cubit) async {
        cubit.loadCrews();
        await Future<void>.delayed(Duration.zero);
        await cubit.createCrew('Weekend Hikers');
      },
      expect: () => <dynamic>[
        const CrewsListLoading(),
        CrewsListLoaded([_fakeCrew]),
        isA<CrewCreating>().having((state) => state.crews, 'crews', [
          _fakeCrew,
        ]),
        isA<CrewCreated>()
            .having((state) => state.crewId, 'crewId', 'crew1')
            .having(
              (state) => state.failedInviteUsernames,
              'failed invites',
              isEmpty,
            )
            .having(
              (state) => state.crews.single.name,
              'crew name',
              'Weekend Hikers',
            ),
      ],
    );

    blocTest<CrewsListCubit, CrewsListState>(
      'creates crew and invites selected usernames',
      build: () {
        when(
          () => mockRepo.streamCrews(),
        ).thenAnswer((_) => Stream.value([_fakeCrew]));
        when(() => mockRepo.createCrew(any())).thenAnswer((_) async => 'crew1');
        when(() => mockRepo.inviteUser(any(), any())).thenAnswer((_) async {});
        return CrewsListCubit(crewRepository: mockRepo);
      },
      act: (cubit) async {
        cubit.loadCrews();
        await Future<void>.delayed(Duration.zero);
        await cubit.createCrewWithInvites('Weekend Hikers', ['bob_chill']);
      },
      expect: () => <dynamic>[
        const CrewsListLoading(),
        CrewsListLoaded([_fakeCrew]),
        isA<CrewCreating>().having((state) => state.crews, 'crews', [
          _fakeCrew,
        ]),
        isA<CrewCreated>()
            .having((state) => state.crewId, 'crewId', 'crew1')
            .having(
              (state) => state.failedInviteUsernames,
              'failed invites',
              isEmpty,
            )
            .having(
              (state) => state.crews.single.name,
              'crew name',
              'Weekend Hikers',
            ),
      ],
      verify: (_) {
        verify(() => mockRepo.createCrew('Weekend Hikers')).called(1);
        verify(() => mockRepo.inviteUser('crew1', 'bob_chill')).called(1);
      },
    );

    blocTest<CrewsListCubit, CrewsListState>(
      'emits CrewCreated with failed invite names when invites fail',
      build: () {
        when(() => mockRepo.streamCrews()).thenAnswer((_) => Stream.value([]));
        when(() => mockRepo.createCrew(any())).thenAnswer((_) async => 'crew2');
        when(
          () => mockRepo.inviteUser('crew2', 'bob_chill'),
        ).thenThrow(Exception('already-invited'));
        return CrewsListCubit(crewRepository: mockRepo);
      },
      act: (cubit) async {
        cubit.loadCrews();
        await Future<void>.delayed(Duration.zero);
        await cubit.createCrewWithInvites('Weekend Hikers', ['bob_chill']);
      },
      expect: () => <dynamic>[
        const CrewsListLoading(),
        const CrewsListLoaded([]),
        const CrewCreating([]),
        isA<CrewCreated>()
            .having((state) => state.crewId, 'crewId', 'crew2')
            .having((state) => state.crews, 'crews', isEmpty)
            .having((state) => state.failedInviteUsernames, 'failed invites', [
              'bob_chill',
            ]),
      ],
    );

    blocTest<CrewsListCubit, CrewsListState>(
      'emits [CrewCreating, CrewCreateError] when createCrew fails',
      build: () {
        when(() => mockRepo.streamCrews()).thenAnswer((_) => Stream.value([]));
        when(() => mockRepo.createCrew(any())).thenThrow(
          Exception('Crew name must be between 3 and 50 characters.'),
        );
        when(() => mockRepo.inviteUser(any(), any())).thenAnswer((_) async {});
        return CrewsListCubit(crewRepository: mockRepo);
      },
      act: (cubit) async {
        cubit.loadCrews();
        await Future<void>.delayed(Duration.zero);
        await cubit.createCrew('x');
      },
      expect: () => <dynamic>[
        const CrewsListLoading(),
        const CrewsListLoaded([]),
        const CrewCreating([]),
        isA<CrewCreateError>(),
      ],
    );

    test('usernameExists delegates to repository', () async {
      when(
        () => mockRepo.usernameExists('bob_chill'),
      ).thenAnswer((_) async => true);

      final cubit = CrewsListCubit(crewRepository: mockRepo);

      expect(await cubit.usernameExists('bob_chill'), isTrue);
      verify(() => mockRepo.usernameExists('bob_chill')).called(1);
      await cubit.close();
    });
  });
}
