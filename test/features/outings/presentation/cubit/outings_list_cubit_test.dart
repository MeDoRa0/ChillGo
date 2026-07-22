import 'dart:async';

import 'package:chillgo/features/outings/domain/entities/outing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/features/outings/presentation/cubit/outings_list/outings_list_cubit.dart';

import '../../outing_repository_fake.dart';

void main() {
  test('OutingsListCubit loads crew outings', () async {
    final upcomingOuting = FakeOutingRepository.sampleOuting(
      id: 'outing-1',
    ).copyWith(scheduledAt: DateTime.now().add(const Duration(days: 1)));
    final repository = FakeOutingRepository(outings: [upcomingOuting]);
    final cubit = OutingsListCubit(outingRepository: repository);

    cubit.load('crew-1');
    await expectLater(
      cubit.stream,
      emits(
        isA<OutingsListLoaded>()
            .having((state) => state.outings.single.id, 'outing id', 'outing-1')
            .having(
              (state) => state.outings.single.crewId,
              'crew id',
              'crew-1',
            ),
      ),
    );
    expect(repository.streamedCrewId, 'crew-1');
    await cubit.close();
  });

  test(
    'OutingsListCubit hides outdated outings and signals after 12 hours',
    () async {
      final now = DateTime.now();
      final outdatedOuting = FakeOutingRepository.sampleOuting(
        id: 'outdated',
      ).copyWith(scheduledAt: now.subtract(const Duration(hours: 13)));
      final recentOuting = FakeOutingRepository.sampleOuting(
        id: 'recent',
      ).copyWith(scheduledAt: now.subtract(const Duration(hours: 11)));
      final upcomingOuting = FakeOutingRepository.sampleOuting(
        id: 'upcoming',
      ).copyWith(scheduledAt: now.add(const Duration(days: 1)));
      final repository = FakeOutingRepository(
        outings: [outdatedOuting, recentOuting, upcomingOuting],
      );
      final cubit = OutingsListCubit(outingRepository: repository);

      cubit.load('crew-1');
      await expectLater(
        cubit.stream,
        emits(
          isA<OutingsListLoaded>().having(
            (state) => state.outings.map((outing) => outing.id),
            'outing ids',
            ['upcoming'],
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.expiryCleanupOutingIds, ['outdated']);
      await cubit.close();
    },
  );

  test('OutingsListCubit emits stream errors through error state', () async {
    final repository = FakeOutingRepository(error: Exception('boom'));
    final cubit = OutingsListCubit(outingRepository: repository);

    cubit.load('crew-1');
    await expectLater(cubit.stream, emits(isA<OutingsListError>()));

    await cubit.close();
  });

  test(
    'OutingsListCubit signals each eligible outing once per session',
    () async {
      final outingsController = StreamController<List<Outing>>();
      final eligibleOuting = FakeOutingRepository.sampleOuting(id: 'eligible')
          .copyWith(
            scheduledAt: DateTime.now().subtract(const Duration(hours: 13)),
          );
      final repository = FakeOutingRepository(
        crewOutingsStream: outingsController.stream,
      );
      final cubit = OutingsListCubit(outingRepository: repository);

      cubit.load('crew-1');
      outingsController.add([eligibleOuting]);
      await Future<void>.delayed(Duration.zero);
      outingsController.add([eligibleOuting]);
      await Future<void>.delayed(Duration.zero);

      expect(repository.expiryCleanupOutingIds, ['eligible']);
      await cubit.close();
      await outingsController.close();
    },
  );
}
