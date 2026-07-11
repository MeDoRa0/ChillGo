import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/features/outings/presentation/cubit/outings_list/outings_list_cubit.dart';

import '../../outing_repository_fake.dart';

void main() {
  test('OutingsListCubit loads crew outings', () async {
    final repository = FakeOutingRepository(
      outings: [FakeOutingRepository.sampleOuting(id: 'outing-1')],
    );
    final cubit = OutingsListCubit(outingRepository: repository);

    cubit.load('crew-1');
    await expectLater(
      cubit.stream,
      emits(
        isA<OutingsListLoaded>()
            .having((state) => state.outings.single.id, 'outing id', 'outing-1')
            .having((state) => state.outings.single.crewId, 'crew id', 'crew-1'),
      ),
    );
    expect(repository.streamedCrewId, 'crew-1');
    await cubit.close();
  });

  test('OutingsListCubit emits stream errors through error state', () async {
    final repository = FakeOutingRepository(error: Exception('boom'));
    final cubit = OutingsListCubit(outingRepository: repository);

    cubit.load('crew-1');
    await expectLater(cubit.stream, emits(isA<OutingsListError>()));

    await cubit.close();
  });
}
