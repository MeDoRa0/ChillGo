import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/entities/crew_membership.dart';
import 'package:chillgo/features/crews/domain/entities/crew_role.dart';
import 'package:chillgo/features/crews/data/datasources/firestore_crews_datasource.dart';
import 'package:chillgo/features/crews/data/repositories/crew_repository_impl.dart';

class MockFirestoreCrewsDatasource extends Mock
    implements FirestoreCrewsDatasource {}

const _uid = 'alice';
const _username = 'alice_cool';
const _displayName = 'Alice';

CrewRepositoryImpl _makeRepo(FirestoreCrewsDatasource ds) => CrewRepositoryImpl(
  datasource: ds,
  currentUid: () => _uid,
  currentUsername: () => _username,
  currentDisplayName: () => _displayName,
);

final _fakeCrew = Crew(
  id: 'crew1',
  name: 'Weekend Hikers',
  ownerId: _uid,
  createdAt: DateTime.utc(2026, 7, 1),
);

final _fakeMembership = CrewMembership(
  id: 'crew1_$_uid',
  crewId: 'crew1',
  userId: _uid,
  role: CrewRole.owner,
  joinedAt: DateTime.utc(2026, 7, 1),
  username: _username,
  displayName: _displayName,
);

void main() {
  late MockFirestoreCrewsDatasource mockDs;
  late CrewRepositoryImpl repo;

  setUp(() {
    mockDs = MockFirestoreCrewsDatasource();
    repo = _makeRepo(mockDs);
  });

  // ─── US1: Creating a Crew and Listing Members ─────────────────────────────

  group('US1 - createCrew', () {
    test('delegates to datasource with valid name', () async {
      when(
        () => mockDs.createCrew(
          name: any(named: 'name'),
          ownerId: any(named: 'ownerId'),
        ),
      ).thenAnswer((_) async => 'crew1');

      final crewId = await repo.createCrew('Weekend Hikers');

      verify(
        () => mockDs.createCrew(name: 'Weekend Hikers', ownerId: _uid),
      ).called(1);
      expect(crewId, 'crew1');
    });

    test('throws when name is too short', () async {
      expect(() => repo.createCrew('ab'), throwsException);
      verifyNever(
        () => mockDs.createCrew(
          name: any(named: 'name'),
          ownerId: any(named: 'ownerId'),
        ),
      );
    });

    test('throws when name is too long (> 50 chars)', () async {
      final longName = 'A' * 51;
      expect(() => repo.createCrew(longName), throwsException);
    });
  });

  group('US1 - streamCrews', () {
    test('returns crews stream for current user', () {
      when(
        () => mockDs.streamCrewsForUser(_uid),
      ).thenAnswer((_) => Stream.value([_fakeCrew]));

      expect(repo.streamCrews(), emits([_fakeCrew]));
    });
  });

  group('US1 - streamMembers', () {
    test('delegates to datasource', () {
      when(
        () => mockDs.streamMembers('crew1'),
      ).thenAnswer((_) => Stream.value([_fakeMembership]));

      expect(repo.streamMembers('crew1'), emits([_fakeMembership]));
    });
  });

  // ─── US2: Inviting Members by Username ────────────────────────────────────

  group('US2 - inviteUser', () {
    setUp(() {
      when(
        () => mockDs.streamCrew('crew1'),
      ).thenAnswer((_) => Stream.value(_fakeCrew));
    });

    test('calls datasource with correct params when all checks pass', () async {
      when(
        () => mockDs.inviteUser(
          crewId: any(named: 'crewId'),
          inviterUid: any(named: 'inviterUid'),
          inviterUsername: any(named: 'inviterUsername'),
          inviterDisplayName: any(named: 'inviterDisplayName'),
          crewName: any(named: 'crewName'),
          targetUsername: any(named: 'targetUsername'),
        ),
      ).thenAnswer((_) async {});

      await repo.inviteUser('crew1', 'bob_chill');

      verify(
        () => mockDs.inviteUser(
          crewId: 'crew1',
          inviterUid: _uid,
          inviterUsername: _username,
          inviterDisplayName: _displayName,
          crewName: 'Weekend Hikers',
          targetUsername: 'bob_chill',
        ),
      ).called(1);
    });

    test('propagates username-not-found exception', () async {
      when(
        () => mockDs.inviteUser(
          crewId: any(named: 'crewId'),
          inviterUid: any(named: 'inviterUid'),
          inviterUsername: any(named: 'inviterUsername'),
          inviterDisplayName: any(named: 'inviterDisplayName'),
          crewName: any(named: 'crewName'),
          targetUsername: any(named: 'targetUsername'),
        ),
      ).thenThrow(Exception('username-not-found'));

      expect(() => repo.inviteUser('crew1', 'nobody'), throwsException);
    });

    test('propagates already-a-member exception', () async {
      when(
        () => mockDs.inviteUser(
          crewId: any(named: 'crewId'),
          inviterUid: any(named: 'inviterUid'),
          inviterUsername: any(named: 'inviterUsername'),
          inviterDisplayName: any(named: 'inviterDisplayName'),
          crewName: any(named: 'crewName'),
          targetUsername: any(named: 'targetUsername'),
        ),
      ).thenThrow(Exception('already-a-member'));

      expect(() => repo.inviteUser('crew1', 'alice_cool'), throwsException);
    });

    test('propagates already-invited exception', () async {
      when(
        () => mockDs.inviteUser(
          crewId: any(named: 'crewId'),
          inviterUid: any(named: 'inviterUid'),
          inviterUsername: any(named: 'inviterUsername'),
          inviterDisplayName: any(named: 'inviterDisplayName'),
          crewName: any(named: 'crewName'),
          targetUsername: any(named: 'targetUsername'),
        ),
      ).thenThrow(Exception('already-invited'));

      expect(() => repo.inviteUser('crew1', 'bob_chill'), throwsException);
    });
  });

  // ─── US3: Accepting / Rejecting Invitations ───────────────────────────────

  group('US3 - acceptInvitation', () {
    test(
      'delegates invitation id and current user without parsing crewId',
      () async {
        when(
          () => mockDs.acceptInvitation(
            invitationId: any(named: 'invitationId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async {});

        await repo.acceptInvitation('crew_with_underscore_bob');

        verify(
          () => mockDs.acceptInvitation(
            invitationId: 'crew_with_underscore_bob',
            userId: _uid,
          ),
        ).called(1);
      },
    );
  });

  group('US3 - rejectInvitation', () {
    test('delegates to datasource', () async {
      when(() => mockDs.rejectInvitation(any())).thenAnswer((_) async {});

      await repo.rejectInvitation('crew1_bob');

      verify(() => mockDs.rejectInvitation('crew1_bob')).called(1);
    });
  });

  // ─── US4: Editing and Deleting Crews ──────────────────────────────────────

  group('US4 - updateCrewName', () {
    test('delegates to datasource with valid name', () async {
      when(() => mockDs.updateCrewName(any(), any())).thenAnswer((_) async {});

      await repo.updateCrewName('crew1', 'New Name');

      verify(() => mockDs.updateCrewName('crew1', 'New Name')).called(1);
    });

    test('throws when new name is too short', () async {
      expect(() => repo.updateCrewName('crew1', 'ab'), throwsException);
    });
  });

  group('US4 - deleteCrew', () {
    test('delegates to datasource', () async {
      when(() => mockDs.deleteCrew(any())).thenAnswer((_) async {});

      await repo.deleteCrew('crew1');

      verify(() => mockDs.deleteCrew('crew1')).called(1);
    });
  });

  // ─── US5: Member Management ───────────────────────────────────────────────

  group('US5 - leaveCrew', () {
    test('calls removeMember with current user uid', () async {
      when(() => mockDs.streamCrew('crew2')).thenAnswer(
        (_) => Stream.value(_fakeCrew.copyWith(id: 'crew2', ownerId: 'owner')),
      );
      when(() => mockDs.removeMember(any(), any())).thenAnswer((_) async {});

      await repo.leaveCrew('crew2');

      verify(() => mockDs.removeMember('crew2', _uid)).called(1);
    });

    test(
      'throws and does not remove membership when current user is owner',
      () async {
        when(
          () => mockDs.streamCrew('crew1'),
        ).thenAnswer((_) => Stream.value(_fakeCrew));

        expect(() => repo.leaveCrew('crew1'), throwsException);
        verifyNever(() => mockDs.removeMember(any(), any()));
      },
    );
  });

  group('US5 - removeMember', () {
    test('delegates to datasource', () async {
      when(() => mockDs.removeMember(any(), any())).thenAnswer((_) async {});

      await repo.removeMember('crew1', 'bob');

      verify(() => mockDs.removeMember('crew1', 'bob')).called(1);
    });
  });
}
