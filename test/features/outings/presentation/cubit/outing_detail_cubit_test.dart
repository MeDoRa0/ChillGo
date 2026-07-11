import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';
import 'package:chillgo/features/outings/presentation/cubit/outing_detail/outing_detail_cubit.dart';

import '../../outing_repository_fake.dart';

void main() {
  test('OutingDetailCubit loads detail and runs status command', () async {
    final repository = FakeOutingRepository(
      detail: FakeOutingRepository.sampleDetail(),
    );
    final cubit = OutingDetailCubit(outingRepository: repository);

    cubit.load('outing-1');
    await expectLater(
      cubit.stream,
      emits(
        isA<OutingDetailLoaded>()
            .having((state) => state.detail.outing.id, 'outing id', 'outing-1')
            .having(
              (state) => state.detail.participants.single.userId,
              'participant user id',
              'user-1',
            ),
      ),
    );

    await cubit.changeStatus(OutingStatus.planning);
    expect(repository.changedStatusOutingId, 'outing-1');
    expect(repository.changedStatus, OutingStatus.planning);
    await cubit.close();
  });

  test('OutingDetailCubit emits stream errors through error state', () async {
    final repository = FakeOutingRepository(error: Exception('boom'));
    final cubit = OutingDetailCubit(outingRepository: repository);

    cubit.load('outing-1');
    await expectLater(cubit.stream, emits(isA<OutingDetailError>()));

    await cubit.close();
  });

  test('OutingDetailCubit deletes the loaded outing', () async {
    final repository = FakeOutingRepository(
      detail: FakeOutingRepository.sampleDetail(),
    );
    final cubit = OutingDetailCubit(outingRepository: repository);

    cubit.load('outing-1');
    await cubit.stream.firstWhere((state) => state is OutingDetailLoaded);

    expect(await cubit.deleteOuting(), isTrue);
    expect(repository.deletedOutingId, 'outing-1');
    await cubit.close();
  });
}
