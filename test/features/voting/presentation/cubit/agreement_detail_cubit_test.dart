import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chillgo/features/voting/domain/repositories/agreement_repository.dart';
import 'package:chillgo/features/voting/presentation/cubit/agreement_detail/agreement_detail_cubit.dart';

class MockRepo extends Mock implements AgreementRepository {}

void main() {
  blocTest<AgreementDetailCubit, AgreementDetailState>(
    'streams sealed agreement detail',
    build: () {
      final repo = MockRepo();
      when(
        () => repo.streamAgreement('o'),
      ).thenAnswer((_) => Stream.value(const AgreementDetail()));
      return AgreementDetailCubit(repository: repo);
    },
    act: (c) => c.watch('o'),
    expect: () => [isA<AgreementDetailLoading>(), isA<AgreementDetailLoaded>()],
  );
}
