import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chillgo/features/voting/data/datasources/firestore_agreement_datasource.dart';
import 'package:chillgo/features/voting/data/models/agreement_proposal_model.dart';
import 'package:chillgo/features/voting/data/models/agreement_round_model.dart';
import 'package:chillgo/features/voting/data/models/agreement_vote_model.dart';
import 'package:chillgo/features/voting/data/repositories/agreement_repository_impl.dart';
import 'package:chillgo/features/voting/domain/entities/agreement_category.dart';
import 'package:chillgo/features/voting/domain/entities/agreement_command.dart';
import 'package:chillgo/features/voting/domain/entities/agreement_result.dart';
import 'package:chillgo/features/voting/domain/entities/agreement_round.dart';
import 'package:chillgo/features/live_meetup/domain/services/live_meetup_transition_service.dart';
import 'package:chillgo/features/outings/domain/entities/attendance_status.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';

class MockDatasource extends Mock implements FirestoreAgreementDatasource {}

class MockTransitionService extends Mock
    implements LiveMeetupTransitionService {}

void main() {
  late MockDatasource ds;
  late AgreementRepositoryImpl repo;
  late MockTransitionService transitionService;
  setUpAll(() => registerFallbackValue(AgreementCategory.time));
  setUp(
    () => {
      ds = MockDatasource(),
      transitionService = MockTransitionService(),
      repo = AgreementRepositoryImpl(
        datasource: ds,
        currentUid: () => 'u',
        transitionService: transitionService,
      ),
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

  test(
    'shares the rounds stream with the active-round vote listener',
    () async {
      final rounds = StreamController<List<AgreementRoundModel>>();
      final votes = StreamController<List<AgreementVoteModel>>();
      addTearDown(() async {
        await rounds.close();
        await votes.close();
      });
      when(() => ds.streamRounds('outing')).thenAnswer((_) => rounds.stream);
      when(
        () => ds.streamProposals('outing'),
      ).thenAnswer((_) => Stream.value(const <AgreementProposalModel>[]));
      when(
        () => ds.streamResults('outing'),
      ).thenAnswer((_) => Stream.value(const <AgreementResult>[]));
      when(
        () => ds.streamMyVotes('round', 'u'),
      ).thenAnswer((_) => votes.stream);

      final subscription = repo.streamAgreement('outing').listen((_) {});
      addTearDown(subscription.cancel);
      rounds.add([
        AgreementRoundModel(
          id: 'round',
          outingId: 'outing',
          crewId: 'crew',
          sequence: 1,
          status: AgreementRoundStatus.open,
          createdByUserId: 'u',
          createdAt: DateTime.utc(2026, 7, 30),
        ),
      ]);
      await pumpEventQueue();

      verify(() => ds.streamRounds('outing')).called(1);
      verify(() => ds.streamMyVotes('round', 'u')).called(1);
    },
  );

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

  test('routes accepted-to-declined attendance through cleanup', () async {
    when(
      () => ds.participantAttendance('o', 'u'),
    ).thenAnswer((_) async => 'accepted');
    when(() => transitionService.declineAttendance('o')).thenAnswer(
      (_) async => const LiveMeetupTransitionResult(
        transitionId: 'transition',
        status: LiveMeetupTransitionStatus.succeeded,
      ),
    );

    await repo.respondToOuting('o', AttendanceStatus.declined);

    verify(() => transitionService.declineAttendance('o')).called(1);
    verifyNever(() => ds.respondToOuting(any(), any(), any()));
  });

  test(
    'routes cancellation through cleanup and returns its transition id',
    () async {
      when(
        () => transitionService.endOuting('o', OutingStatus.cancelled),
      ).thenAnswer(
        (_) async => const LiveMeetupTransitionResult(
          transitionId: 'cancel-transition',
          status: LiveMeetupTransitionStatus.succeeded,
        ),
      );

      expect(
        await repo.cancelOuting('o', 'Weather changed'),
        'cancel-transition',
      );

      verify(
        () => transitionService.endOuting('o', OutingStatus.cancelled),
      ).called(1);
      verifyNever(
        () => ds.createCommand(
          type: 'cancel_outing',
          outingId: any(named: 'outingId'),
          uid: any(named: 'uid'),
          payload: any(named: 'payload'),
        ),
      );
    },
  );
}
