import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chillgo/features/outings/domain/entities/outing.dart';
import 'package:chillgo/features/outings/domain/entities/outing_participant.dart';
import 'package:chillgo/features/outings/data/datasources/firestore_outings_datasource.dart';
import 'package:chillgo/features/outings/data/repositories/outing_repository_impl.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';

import '../../outing_repository_fake.dart';

class MockFirestoreOutingsDatasource extends Mock
    implements FirestoreOutingsDatasource {}

void main() {
  late MockFirestoreOutingsDatasource datasource;
  late OutingRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(OutingStatus.draft);
  });

  setUp(() {
    datasource = MockFirestoreOutingsDatasource();
    repository = OutingRepositoryImpl(
      datasource: datasource,
      currentUid: () => 'user-1',
    );
  });

  group('createOuting', () {
    test('validates required fields', () async {
      await expectLater(
        repository.createOuting(
          crewId: 'crew-1',
          title: 'No',
          scheduledAt: DateTime.now().add(const Duration(days: 1)),
          locationText: 'Cafe',
        ),
        _throwsExceptionContaining('Title must be between 3 and 80 characters.'),
      );
      verifyNever(
        () => datasource.createOuting(
          crewId: any(named: 'crewId'),
          creatorUserId: any(named: 'creatorUserId'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          scheduledAt: any(named: 'scheduledAt'),
          locationText: any(named: 'locationText'),
        ),
      );
    });

    test('delegates valid create with current uid', () async {
      when(
        () => datasource.createOuting(
          crewId: any(named: 'crewId'),
          creatorUserId: any(named: 'creatorUserId'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          scheduledAt: any(named: 'scheduledAt'),
          locationText: any(named: 'locationText'),
        ),
      ).thenAnswer((_) async => 'outing-1');

      final id = await repository.createOuting(
        crewId: 'crew-1',
        title: 'Friday Cafe',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        locationText: 'City Center Cafe',
      );

      expect(id, 'outing-1');
      verify(
        () => datasource.createOuting(
          crewId: 'crew-1',
          creatorUserId: 'user-1',
          title: 'Friday Cafe',
          description: null,
          scheduledAt: any(named: 'scheduledAt'),
          locationText: 'City Center Cafe',
        ),
      ).called(1);
    });

    test('requires current uid', () async {
      final repo = OutingRepositoryImpl(
        datasource: datasource,
        currentUid: () => '',
      );

      await expectLater(
        repo.createOuting(
          crewId: 'crew-1',
          title: 'Friday Cafe',
          scheduledAt: DateTime.now().add(const Duration(days: 1)),
          locationText: 'Cafe',
        ),
        _throwsExceptionContaining('auth-user-required'),
      );
    });
  });

  group('streamOutingDetail', () {
    test('emits updates from outing and participant streams', () async {
      final outingController = StreamController<Outing?>();
      final participantsController = StreamController<List<OutingParticipant>>();
      when(() => datasource.streamOuting('outing-1'))
          .thenAnswer((_) => outingController.stream);
      when(() => datasource.streamParticipants('outing-1'))
          .thenAnswer((_) => participantsController.stream);

      final emitted = <String>[];
      final subscription = repository.streamOutingDetail('outing-1').listen(
            (detail) => emitted.add(
              '${detail?.outing.title}:${detail?.participants.length}',
            ),
          );

      outingController.add(FakeOutingRepository.sampleOuting(title: 'First'));
      participantsController.add([FakeOutingRepository.sampleParticipant()]);
      await Future<void>.delayed(Duration.zero);
      participantsController.add([
        FakeOutingRepository.sampleParticipant(),
        FakeOutingRepository.sampleParticipant().copyWith(userId: 'user-2'),
      ]);
      await Future<void>.delayed(Duration.zero);
      outingController.add(FakeOutingRepository.sampleOuting(title: 'Second'));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, ['First:1', 'First:2', 'Second:2']);

      await subscription.cancel();
      await outingController.close();
      await participantsController.close();
    });
  });

  group('management operations', () {
    setUp(() {
      when(() => datasource.getOuting(any())).thenAnswer(
        (_) async => FakeOutingRepository.sampleOuting(id: 'outing-1'),
      );
      when(() => datasource.isCrewOwner('crew-1', 'user-1'))
          .thenAnswer((_) async => false);
      when(
        () => datasource.updateOutingDetails(
          outingId: any(named: 'outingId'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          scheduledAt: any(named: 'scheduledAt'),
          locationText: any(named: 'locationText'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => datasource.cancelOuting(
          outingId: any(named: 'outingId'),
          cancelledReason: any(named: 'cancelledReason'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => datasource.addParticipant(
          outingId: any(named: 'outingId'),
          userId: any(named: 'userId'),
          addedByUserId: any(named: 'addedByUserId'),
        ),
      ).thenAnswer((_) async => FakeOutingRepository.sampleParticipant());
      when(
        () => datasource.removeParticipant(
          outingId: any(named: 'outingId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => datasource.changeLifecycleStatus(
          outingId: any(named: 'outingId'),
          nextStatus: any(named: 'nextStatus'),
        ),
      ).thenAnswer((_) async {});
    });

    test('updates active outing details', () async {
      await repository.updateOutingDetails(
        outingId: 'outing-1',
        title: 'Updated Cafe',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        locationText: 'Park',
      );

      verify(
        () => datasource.updateOutingDetails(
          outingId: 'outing-1',
          title: 'Updated Cafe',
          description: null,
          scheduledAt: any(named: 'scheduledAt'),
          locationText: 'Park',
        ),
      ).called(1);
    });

    test('rejects cancelling without useful reason', () async {
      await expectLater(
        repository.cancelOuting(outingId: 'outing-1', cancelledReason: 'no'),
        _throwsExceptionContaining(
          'Cancellation reason must be between 3 and 200 characters.',
        ),
      );
      verifyNever(
        () => datasource.cancelOuting(
          outingId: any(named: 'outingId'),
          cancelledReason: any(named: 'cancelledReason'),
        ),
      );
    });

    test('adds and removes participants', () async {
      await repository.addParticipant(outingId: 'outing-1', userId: 'user-2');
      await repository.removeParticipant(outingId: 'outing-1', userId: 'user-2');

      verify(
        () => datasource.addParticipant(
          outingId: 'outing-1',
          userId: 'user-2',
          addedByUserId: 'user-1',
        ),
      ).called(1);
      verify(
        () => datasource.removeParticipant(outingId: 'outing-1', userId: 'user-2'),
      ).called(1);
    });

    test('delegates valid lifecycle transition', () async {
      await repository.changeLifecycleStatus(
        outingId: 'outing-1',
        nextStatus: OutingStatus.planning,
      );

      verify(
        () => datasource.changeLifecycleStatus(
          outingId: 'outing-1',
          nextStatus: OutingStatus.planning,
        ),
      ).called(1);
    });

    test('rejects invalid lifecycle transition', () async {
      await expectLater(
        repository.changeLifecycleStatus(
          outingId: 'outing-1',
          nextStatus: OutingStatus.archived,
        ),
        _throwsExceptionContaining('invalid-lifecycle-transition'),
      );
    });

    test('rejects participant removal from cancelled outings', () async {
      when(() => datasource.getOuting(any())).thenAnswer(
        (_) async => FakeOutingRepository.sampleOuting(
          id: 'outing-1',
          status: OutingStatus.cancelled,
        ),
      );

      await expectLater(
        repository.removeParticipant(outingId: 'outing-1', userId: 'user-2'),
        _throwsExceptionContaining('participant-removal-blocked'),
      );
      verifyNever(
        () => datasource.removeParticipant(
          outingId: any(named: 'outingId'),
          userId: any(named: 'userId'),
        ),
      );
    });
  });
}

Matcher _throwsExceptionContaining(String message) {
  return throwsA(
    isA<Exception>().having((error) => error.toString(), 'message', contains(message)),
  );
}
