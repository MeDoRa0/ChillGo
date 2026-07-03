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
      'emits [CrewsListLoading, CrewsListLoaded, CrewCreating, CrewsListLoaded] '
      'when createCrew succeeds',
      build: () {
        when(
          () => mockRepo.streamCrews(),
        ).thenAnswer((_) => Stream.value([_fakeCrew]));
        when(() => mockRepo.createCrew(any())).thenAnswer((_) async => 'crew1');
        return CrewsListCubit(crewRepository: mockRepo);
      },
      act: (cubit) async {
        cubit.loadCrews();
        await Future<void>.delayed(Duration.zero);
        await cubit.createCrew('Weekend Hikers');
      },
      expect: () => <CrewsListState>[
        const CrewsListLoading(),
        CrewsListLoaded([_fakeCrew]),
        const CrewCreating(),
        const CrewCreated('crew1'),
      ],
    );

    blocTest<CrewsListCubit, CrewsListState>(
      'emits [CrewCreating, CrewCreateError] when createCrew fails',
      build: () {
        when(() => mockRepo.streamCrews()).thenAnswer((_) => Stream.value([]));
        when(() => mockRepo.createCrew(any())).thenThrow(
          Exception('Crew name must be between 3 and 50 characters.'),
        );
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
        const CrewCreating(),
        isA<CrewCreateError>(),
      ],
    );
  });
}
