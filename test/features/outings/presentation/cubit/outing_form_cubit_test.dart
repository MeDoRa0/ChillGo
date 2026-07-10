import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';
import 'package:chillgo/features/outings/presentation/cubit/outing_form/outing_form_cubit.dart';

import '../../outing_repository_fake.dart';

void main() {
  group('OutingFormCubit', () {
    test('emits success after create', () async {
      final repository = FakeOutingRepository(createdOutingId: 'outing-1');
      final cubit = OutingFormCubit(outingRepository: repository);

      await cubit.createOuting(
        crewId: 'crew-1',
        title: 'Friday Cafe',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        locationText: 'City Center Cafe',
      );

      expect(cubit.state, const OutingFormSuccess('outing-1'));
      await cubit.close();
    });

    test('emits failure when repository throws', () async {
      final repository = FakeOutingRepository(error: Exception('boom'));
      final cubit = OutingFormCubit(outingRepository: repository);

      await cubit.createOuting(
        crewId: 'crew-1',
        title: 'No',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        locationText: 'Cafe',
      );

      expect(cubit.state, isA<OutingFormFailure>());
      await cubit.close();
    });

    test('supports edit and cancel commands', () async {
      final repository = FakeOutingRepository(createdOutingId: 'outing-1');
      final cubit = OutingFormCubit(outingRepository: repository);
      final outing = FakeOutingRepository.sampleOuting(
        id: 'outing-1',
        status: OutingStatus.draft,
      );
      final scheduledAt = DateTime.now().add(const Duration(days: 2));

      await cubit.updateOuting(
        outing: outing,
        title: 'Updated',
        scheduledAt: scheduledAt,
        locationText: 'Park',
      );
      expect(cubit.state, const OutingFormSuccess('outing-1'));
      expect(repository.updatedOutingId, 'outing-1');
      expect(repository.updatedTitle, 'Updated');
      expect(repository.updatedScheduledAt, scheduledAt);
      expect(repository.updatedLocationText, 'Park');

      await cubit.cancelOuting(outingId: 'outing-1', reason: 'Bad weather');
      expect(cubit.state, const OutingFormSuccess('outing-1'));
      expect(repository.cancelledOutingId, 'outing-1');
      expect(repository.cancelledReason, 'Bad weather');
      await cubit.close();
    });
  });
}
