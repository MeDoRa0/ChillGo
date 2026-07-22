import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chillgo/features/voting/data/datasources/firestore_agreement_datasource.dart';
import 'package:chillgo/features/voting/data/repositories/agreement_repository_impl.dart';
import 'package:chillgo/features/voting/domain/entities/agreement_category.dart';
import 'package:chillgo/features/voting/domain/entities/agreement_command.dart';

class MockDatasource extends Mock implements FirestoreAgreementDatasource {}

void main() {
  late MockDatasource ds;
  late AgreementRepositoryImpl repo;
  setUpAll(() => registerFallbackValue(AgreementCategory.time));
  setUp(
    () => {
      ds = MockDatasource(),
      repo = AgreementRepositoryImpl(datasource: ds, currentUid: () => 'u'),
    },
  );
  test('commands use allowlisted normalized payloads', () async {
    when(
      () => ds.createCommand(
        type: any(named: 'type'),
        outingId: any(named: 'outingId'),
        uid: any(named: 'uid'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async => 'cmd');
    expect(await repo.createLocationProposal('o', '  City Cafe  '), 'cmd');
    verify(
      () => ds.createCommand(
        type: 'create_proposal',
        outingId: 'o',
        uid: 'u',
        payload: {'category': 'location', 'locationText': 'City Cafe'},
      ),
    ).called(1);
  });
  test('rejects invalid proposals and reasons locally', () async {
    expect(
      () => repo.createLocationProposal('o', ''),
      throwsA(isA<AgreementValidationFailure>()),
    );
    expect(
      () => repo.createTimeProposal(
        'o',
        DateTime.now().subtract(const Duration(minutes: 1)),
      ),
      throwsA(isA<AgreementValidationFailure>()),
    );
    expect(
      () => repo.reopenRound('o', 'x'),
      throwsA(isA<AgreementValidationFailure>()),
    );
  });
  test('uses predictable private vote operations', () async {
    when(
      () => ds.castVote(
        roundId: any(named: 'roundId'),
        category: any(named: 'category'),
        proposalId: any(named: 'proposalId'),
        uid: any(named: 'uid'),
      ),
    ).thenAnswer((_) async {});
    when(() => ds.withdrawVote(any(), any(), any())).thenAnswer((_) async {});
    await repo.castVote('r', AgreementCategory.time, 'p');
    await repo.withdrawVote('r', AgreementCategory.time);
    verify(
      () => ds.castVote(
        roundId: 'r',
        category: AgreementCategory.time,
        proposalId: 'p',
        uid: 'u',
      ),
    ).called(1);
    verify(() => ds.withdrawVote('r', AgreementCategory.time, 'u')).called(1);
  });

  test('dispatches creator removal through delete_outing', () async {
    when(
      () => ds.createCommand(
        type: any(named: 'type'),
        outingId: any(named: 'outingId'),
        uid: any(named: 'uid'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async => 'delete-command');

    expect(await repo.deleteOuting('o'), 'delete-command');
    verify(
      () => ds.createCommand(
        type: 'delete_outing',
        outingId: 'o',
        uid: 'u',
        payload: const {},
      ),
    ).called(1);
  });

  test('dispatches expiry cleanup through expire_outing', () async {
    when(
      () => ds.createCommand(
        type: any(named: 'type'),
        outingId: any(named: 'outingId'),
        uid: any(named: 'uid'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async => 'expiry-command');

    expect(await repo.requestOutingExpiry('o'), 'expiry-command');
    verify(
      () => ds.createCommand(
        type: 'expire_outing',
        outingId: 'o',
        uid: 'u',
        payload: const {},
      ),
    ).called(1);
  });
}
