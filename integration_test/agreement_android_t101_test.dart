import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:chillgo/firebase_options.dart';
import 'package:chillgo/features/outings/data/datasources/firestore_outings_datasource.dart';
import 'package:chillgo/features/outings/data/models/outing_model.dart';
import 'package:chillgo/features/outings/data/repositories/outing_repository_impl.dart';
import 'package:chillgo/features/outings/domain/entities/attendance_status.dart';
import 'package:chillgo/features/outings/domain/repositories/outing_repository.dart';
import 'package:chillgo/features/outings/presentation/widgets/interactive_outing_card.dart';
import 'package:chillgo/features/voting/domain/entities/agreement_category.dart';
import 'package:chillgo/features/voting/domain/repositories/agreement_repository.dart';
import 'package:chillgo/features/voting/data/datasources/firestore_agreement_datasource.dart';
import 'package:chillgo/features/voting/data/repositories/agreement_repository_impl.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'T101 Android emulator scenarios and performance',
    (tester) async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
      await _signIn('bob@android.test');

      final firestore = FirebaseFirestore.instance;
      String currentUid() => FirebaseAuth.instance.currentUser?.uid ?? '';
      final agreements = AgreementRepositoryImpl(
        datasource: FirestoreAgreementDatasource(firestore: firestore),
        currentUid: currentUid,
      );
      final outings = OutingRepositoryImpl(
        datasource: FirestoreOutingsDatasource(firestore: firestore),
        currentUid: currentUid,
        agreementCancel: (outingId, reason) async {
          await agreements.cancelOuting(outingId, reason);
        },
        agreementDelete: (outingId) async {
          await agreements.deleteOuting(outingId);
        },
      );

      await expectLater(
        outings.respondToOuting(
          outingId: 'android-delete-meeting',
          attendanceStatus: AttendanceStatus.declined,
        ),
        throwsA(anything),
      );

      final firstProposal = await _waitForTerminalCommand(
        await agreements.createLocationProposal(
          'android-performance',
          'Android Library',
        ),
      );
      final duplicateProposal = await _waitForTerminalCommand(
        await agreements.createLocationProposal(
          'android-performance',
          '  android library  ',
        ),
      );
      expect(firstProposal['status'], 'succeeded');
      expect(firstProposal['result']['reused'], false);
      expect(duplicateProposal['status'], 'succeeded');
      expect(duplicateProposal['result']['reused'], true);
      await expectLater(
        firestore
            .collection('agreement_proposals')
            .doc(firstProposal['result']['proposalId'] as String)
            .update({'locationText': 'Mutated'}),
        throwsA(isA<FirebaseException>()),
      );
      await expectLater(
        firestore
            .collection('agreement_votes')
            .where('roundId', isEqualTo: 'android-tie_1')
            .get(),
        throwsA(isA<FirebaseException>()),
      );
      final planningOuting = OutingModel.fromMap(
        (await firestore.collection('outings').doc('android-performance').get())
            .data()!,
        'android-performance',
      );
      await expectLater(
        outings.updateOutingDetails(
          outingId: planningOuting.id,
          title: planningOuting.title,
          description: planningOuting.description,
          scheduledAt: planningOuting.scheduledAt.add(const Duration(days: 1)),
          locationText: planningOuting.locationText,
        ),
        throwsA(anything),
      );

      final tiePreview = await _waitForTerminalCommand(
        await agreements.previewConfirmation('android-tie'),
      );
      expect(tiePreview['status'], 'succeeded');
      expect((tiePreview['result']['timeTiedProposalIds'] as List).length, 2);
      expect(tiePreview['result'].containsKey('voteCount'), false);
      final tieConfirmation = await _waitForTerminalCommand(
        await agreements.confirmRound(
          'android-tie',
          selectedTimeProposalId: 'android-tie-time-a',
        ),
      );
      expect(tieConfirmation['status'], 'succeeded');
      final reopened = await _waitForTerminalCommand(
        await agreements.reopenRound('android-tie', 'Android plan changed'),
      );
      expect(reopened['status'], 'succeeded');
      expect(
        (await firestore
                .collection('agreement_rounds')
                .doc('android-tie_1')
                .get())
            .data()?['status'],
        'superseded',
      );
      expect(
        (await firestore
                .collection('agreement_rounds')
                .doc(reopened['result']['roundId'] as String)
                .get())
            .data()?['status'],
        'open',
      );

      await FirebaseAuth.instance.signOut();
      await _signIn('carol@android.test');
      await outings.respondToOuting(
        outingId: 'android-eligibility',
        attendanceStatus: AttendanceStatus.declined,
      );
      await FirebaseAuth.instance.signOut();
      await _signIn('bob@android.test');
      final eligibilityConfirmation = await _waitForTerminalCommand(
        await agreements.confirmRound('android-eligibility'),
      );
      expect(eligibilityConfirmation['status'], 'succeeded');
      expect(
        eligibilityConfirmation['result']['selectedTimeProposalId'],
        'android-eligibility-time-a',
      );
      final eligibilityRound = await firestore
          .collection('agreement_rounds')
          .doc('android-eligibility_1')
          .get();
      expect(eligibilityRound.data()?['eligibleVoterCount'], 1);
      expect(eligibilityRound.data()?['timeVoteCount'], 1);

      final attendanceDurations = <Duration>[];
      for (var index = 0; index < 100; index += 1) {
        final status = index.isEven
            ? AttendanceStatus.declined
            : AttendanceStatus.accepted;
        final stopwatch = Stopwatch()..start();
        await outings.respondToOuting(
          outingId: 'android-performance',
          attendanceStatus: status,
        );
        await _waitForField(
          firestore
              .collection('outing_participants')
              .doc('android-performance_android-bob'),
          'attendanceStatus',
          status.value,
        );
        attendanceDurations.add(stopwatch.elapsed);
      }

      final voteDurations = <Duration>[];
      for (var index = 0; index < 100; index += 1) {
        final proposalId = index.isEven ? 'android-time-a' : 'android-time-b';
        final stopwatch = Stopwatch()..start();
        await agreements.castVote(
          'android-performance_1',
          AgreementCategory.time,
          proposalId,
        );
        await _waitForField(
          firestore
              .collection('agreement_votes')
              .doc('android-performance_1_time_android-bob'),
          'proposalId',
          proposalId,
        );
        voteDurations.add(stopwatch.elapsed);
      }

      final confirmationDurations = <Duration>[];
      for (var index = 0; index < 100; index += 1) {
        final stopwatch = Stopwatch()..start();
        final commandId = await agreements.confirmRound(
          'android-confirm-$index',
        );
        final command = await _waitForTerminalCommand(commandId);
        expect(command['status'], 'succeeded', reason: command.toString());
        confirmationDurations.add(stopwatch.elapsed);
      }

      debugPrint(
        'ANDROID_T101 attendance_p95_ms=${_p95(attendanceDurations)} '
        'vote_p95_ms=${_p95(voteDurations)} '
        'confirmation_cold_ms=${confirmationDurations.first.inMilliseconds} '
        'confirmation_warm_p95_ms=${_p95(confirmationDurations.skip(1).toList())}',
      );
      expect(_p95(attendanceDurations), lessThan(3000));
      expect(_p95(voteDurations), lessThan(3000));
      expect(_p95(confirmationDurations.skip(1).toList()), lessThan(3000));

      await FirebaseAuth.instance.signOut();
      await _signIn('alice@android.test');
      await expectLater(
        outings.deleteOuting(outingId: 'android-owner-check'),
        throwsA(anything),
      );
      await _showOutingCard(tester, outings, agreements, 'android-owner-check');
      await tester.tap(
        find.byKey(const ValueKey('outing-card-android-owner-check')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Remove outing'), findsNothing);
      await tester.tap(find.byTooltip('Close'));
      await tester.pump(const Duration(milliseconds: 300));

      await FirebaseAuth.instance.signOut();
      await _signIn('bob@android.test');
      for (final status in const [
        'draft',
        'planning',
        'confirmed',
        'meeting',
        'completed',
        'archived',
        'cancelled',
      ]) {
        final outingId = 'android-delete-$status';
        await _showOutingCard(tester, outings, agreements, outingId);
        await tester.tap(find.byKey(ValueKey('outing-card-$outingId')));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.text('Remove outing'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Remove permanently'));
        await _waitForDocumentDeletion(
          tester,
          firestore.collection('outings').doc(outingId),
        );
        for (final collection in const [
          'outing_participants',
          'agreement_rounds',
          'agreement_proposals',
          'agreement_votes',
          'agreement_results',
        ]) {
          await _expectNoAccessibleRecords(collection, outingId);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}

Future<void> _signIn(String email) async {
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: 'Android-T101-pass',
  );
}

Future<void> _waitForField(
  DocumentReference<Map<String, dynamic>> reference,
  String field,
  Object expected,
) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    final snapshot = await reference.get();
    if (snapshot.data()?[field] == expected) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('$field did not become $expected.');
}

Future<Map<String, dynamic>> _waitForTerminalCommand(String commandId) async {
  final reference = FirebaseFirestore.instance
      .collection('agreement_commands')
      .doc(commandId);
  for (var attempt = 0; attempt < 300; attempt += 1) {
    final command = (await reference.get()).data();
    if (command?['status'] == 'succeeded' || command?['status'] == 'failed') {
      return command!;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('Command $commandId did not complete.');
}

int _p95(List<Duration> durations) {
  final sorted = durations.map((value) => value.inMilliseconds).toList()
    ..sort();
  return sorted[((sorted.length * 0.95).ceil() - 1).clamp(
    0,
    sorted.length - 1,
  )];
}

Future<void> _showOutingCard(
  WidgetTester tester,
  OutingRepository outings,
  AgreementRepository agreements,
  String outingId,
) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('outings')
      .doc(outingId)
      .get();
  final outing = OutingModel.fromMap(snapshot.data()!, snapshot.id);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: InteractiveOutingCard(
          outing: outing,
          outingRepository: outings,
          agreementRepository: agreements,
          currentUserId: FirebaseAuth.instance.currentUser?.uid,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _waitForDocumentDeletion(
  WidgetTester tester,
  DocumentReference<Map<String, dynamic>> reference,
) async {
  for (var attempt = 0; attempt < 300; attempt += 1) {
    try {
      if (!(await reference.get()).exists) return;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return;
      rethrow;
    }
    await tester.pump(const Duration(milliseconds: 20));
  }
  fail('${reference.path} was not deleted.');
}

Future<void> _expectNoAccessibleRecords(
  String collection,
  String outingId,
) async {
  try {
    final leftovers = await FirebaseFirestore.instance
        .collection(collection)
        .where('outingId', isEqualTo: outingId)
        .get();
    expect(leftovers.docs, isEmpty, reason: '$collection for $outingId');
  } on FirebaseException catch (error) {
    if (error.code != 'permission-denied') rethrow;
  }
}
