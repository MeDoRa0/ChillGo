import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chillgo/features/voting/domain/repositories/agreement_repository.dart';
import 'package:chillgo/features/voting/domain/entities/agreement_command.dart';
import 'package:chillgo/features/voting/presentation/cubit/agreement_command/agreement_command_cubit.dart';

class MockRepo extends Mock implements AgreementRepository {}

AgreementCommand command(AgreementCommandStatus s) => AgreementCommand(
  id: 'c',
  type: AgreementCommandType.openRound,
  status: s,
  outingId: 'o',
  crewId: 'x',
  requestedByUserId: 'u',
  payload: const {},
  createdAt: DateTime.utc(2030),
  errorCode: s == AgreementCommandStatus.failed ? 'invalid_outing_state' : null,
  errorMessage: s == AgreementCommandStatus.failed ? 'Wrong state' : null,
);
void main() {
  late MockRepo repo;
  setUp(() => repo = MockRepo());
  blocTest<AgreementCommandCubit, AgreementCommandState>(
    'emits pending then success',
    build: () {
      when(() => repo.streamCommand('c')).thenAnswer(
        (_) => Stream.value(command(AgreementCommandStatus.succeeded)),
      );
      return AgreementCommandCubit(repository: repo);
    },
    act: (c) => c.run(() => Future.value('c')),
    expect: () => [
      isA<AgreementCommandPending>(),
      isA<AgreementCommandSucceeded>(),
    ],
  );
  blocTest<AgreementCommandCubit, AgreementCommandState>(
    'maps terminal failure',
    build: () {
      when(
        () => repo.streamCommand('c'),
      ).thenAnswer((_) => Stream.value(command(AgreementCommandStatus.failed)));
      return AgreementCommandCubit(repository: repo);
    },
    act: (c) => c.run(() => Future.value('c')),
    expect: () => [
      isA<AgreementCommandPending>(),
      isA<AgreementCommandFailed>(),
    ],
  );
}
