import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chillgo/features/crews/presentation/blocs/crew_detail/crew_detail_cubit.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/entities/crew_invitation.dart';
import 'package:chillgo/features/crews/domain/entities/crew_membership.dart';
import 'package:chillgo/features/crews/domain/entities/crew_role.dart';

class MockCrewRepository extends Mock implements CrewRepository {}

const _crewId = 'crew1';

final _fakeCrew = Crew(
  id: _crewId,
  name: 'Weekend Hikers',
  ownerId: 'alice',
  createdAt: DateTime.utc(2026, 7, 1),
);

final _fakeMembers = [
  CrewMembership(
    id: 'crew1_alice',
    crewId: _crewId,
    userId: 'alice',
    role: CrewRole.owner,
    joinedAt: DateTime.utc(2026, 7, 1),
    username: 'alice_cool',
    displayName: 'Alice',
  ),
];

final _fakeBobMembership = CrewMembership(
  id: 'crew1_bob',
  crewId: _crewId,
  userId: 'bob',
  role: CrewRole.member,
  joinedAt: DateTime.utc(2026, 7, 2),
  username: 'bob_chill',
  displayName: 'Bob',
);

final _fakeInvitation = CrewInvitation(
  id: 'crew1_bob',
  crewId: _crewId,
  invitedUserId: 'bob',
  invitedByUserId: 'alice',
  createdAt: DateTime.utc(2026, 7, 2),
  crewName: 'Weekend Hikers',
  invitedByUsername: 'alice_cool',
  invitedByDisplayName: 'Alice',
  invitedUsername: 'bob_chill',
);

void main() {
  late MockCrewRepository mockRepo;

  setUp(() {
    mockRepo = MockCrewRepository();
    when(
      () => mockRepo.streamCrew(_crewId),
    ).thenAnswer((_) => Stream.value(_fakeCrew));
    when(
      () => mockRepo.streamMembers(_crewId),
    ).thenAnswer((_) => Stream.value(_fakeMembers));
    when(
      () => mockRepo.streamPendingInvitationsForCrew(_crewId),
    ).thenAnswer((_) => Stream.value([]));
  });

  // Helper: load streams then perform an action and verify terminal state
  Future<void> loadAndAct(
    CrewDetailCubit cubit,
    Future<void> Function() action,
  ) async {
    cubit.loadCrew(_crewId);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await action();
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  void expectActionSuccess(CrewDetailCubit cubit, CrewDetailAction action) {
    expect(cubit.state, isA<CrewDetailActionSuccess>());
    expect((cubit.state as CrewDetailActionSuccess).action, action);
  }

  // ─── US1: Loading ──────────────────────────────────────────────────────────
  group('CrewDetailCubit - US1 loading', () {
    test('final state is CrewDetailLoaded with crew and members', () async {
      final cubit = CrewDetailCubit(crewRepository: mockRepo);
      cubit.loadCrew(_crewId);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(cubit.state, isA<CrewDetailLoaded>());
      final loaded = cubit.state as CrewDetailLoaded;
      expect(loaded.crew.id, _crewId);
      expect(loaded.members, _fakeMembers);
      await cubit.close();
    });

    test('first emitted state is CrewDetailLoading', () async {
      final states = <CrewDetailState>[];
      final cubit = CrewDetailCubit(crewRepository: mockRepo);
      cubit.stream.listen(states.add);
      cubit.loadCrew(_crewId);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(states.first, isA<CrewDetailLoading>());
      await cubit.close();
    });

    test('emits CrewDeleted when crew stream emits null', () async {
      final controller = StreamController<Crew?>();
      when(
        () => mockRepo.streamCrew(_crewId),
      ).thenAnswer((_) => controller.stream);
      final cubit = CrewDetailCubit(crewRepository: mockRepo);
      cubit.loadCrew(_crewId);

      controller.add(_fakeCrew);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state, isA<CrewDetailLoaded>());

      controller.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state, isA<CrewDeleted>());

      await controller.close();
      await cubit.close();
    });

    test('stream refreshes emit loaded data without action success', () async {
      final controller = StreamController<Crew?>();
      when(
        () => mockRepo.streamCrew(_crewId),
      ).thenAnswer((_) => controller.stream);
      final cubit = CrewDetailCubit(crewRepository: mockRepo);
      cubit.loadCrew(_crewId);

      controller.add(_fakeCrew);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state, isA<CrewDetailLoaded>());
      expect(cubit.state, isNot(isA<CrewDetailActionSuccess>()));

      controller.add(_fakeCrew.copyWith(name: 'Weekend Trekkers'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state, isA<CrewDetailLoaded>());
      expect(cubit.state, isNot(isA<CrewDetailActionSuccess>()));

      await controller.close();
      await cubit.close();
    });
  });

  // ─── US2: Inviting Members ────────────────────────────────────────────────
  group('CrewDetailCubit - US2 invite', () {
    test('final state is CrewDetailLoaded after successful invite', () async {
      when(
        () => mockRepo.inviteUser(_crewId, 'bob_chill'),
      ).thenAnswer((_) async {});
      final cubit = CrewDetailCubit(crewRepository: mockRepo);
      await loadAndAct(cubit, () => cubit.inviteUser('bob_chill'));
      expect(cubit.state, isA<CrewDetailLoaded>());
      expectActionSuccess(cubit, CrewDetailAction.inviteUser);
      await cubit.close();
    });

    test(
      'final state is CrewDetailActionError on username-not-found',
      () async {
        when(
          () => mockRepo.inviteUser(_crewId, 'nobody'),
        ).thenThrow(Exception('username-not-found'));
        final cubit = CrewDetailCubit(crewRepository: mockRepo);
        await loadAndAct(cubit, () => cubit.inviteUser('nobody'));
        expect(cubit.state, isA<CrewDetailActionError>());
        expect(
          (cubit.state as CrewDetailActionError).message,
          'Username not found.',
        );
        await cubit.close();
      },
    );

    test('final state is CrewDetailActionError on already-a-member', () async {
      when(
        () => mockRepo.inviteUser(_crewId, 'alice_cool'),
      ).thenThrow(Exception('already-a-member'));
      final cubit = CrewDetailCubit(crewRepository: mockRepo);
      await loadAndAct(cubit, () => cubit.inviteUser('alice_cool'));
      expect(cubit.state, isA<CrewDetailActionError>());
      expect(
        (cubit.state as CrewDetailActionError).message,
        'User is already a member.',
      );
      await cubit.close();
    });

    test('final state is CrewDetailActionError on already-invited', () async {
      when(
        () => mockRepo.inviteUser(_crewId, 'bob_chill'),
      ).thenThrow(Exception('already-invited'));
      final cubit = CrewDetailCubit(crewRepository: mockRepo);
      await loadAndAct(cubit, () => cubit.inviteUser('bob_chill'));
      expect(cubit.state, isA<CrewDetailActionError>());
      expect(
        (cubit.state as CrewDetailActionError).message,
        'User already has a pending invitation.',
      );
      await cubit.close();
    });
  });

  // ─── US4: Edit name / Delete crew ─────────────────────────────────────────
  group('CrewDetailCubit - US4 edit and delete', () {
    test('final state is CrewDetailLoaded after updateCrewName', () async {
      when(
        () => mockRepo.updateCrewName(_crewId, 'New Name'),
      ).thenAnswer((_) async {});
      final cubit = CrewDetailCubit(crewRepository: mockRepo);
      await loadAndAct(cubit, () => cubit.updateCrewName('New Name'));
      expect(cubit.state, isA<CrewDetailLoaded>());
      expectActionSuccess(cubit, CrewDetailAction.updateCrewName);
      expect((cubit.state as CrewDetailActionSuccess).crew.name, 'New Name');
      await cubit.close();
    });

    test('final state is CrewDeleted after deleteCrew', () async {
      when(() => mockRepo.deleteCrew(_crewId)).thenAnswer((_) async {});
      final cubit = CrewDetailCubit(crewRepository: mockRepo);
      await loadAndAct(cubit, () => cubit.deleteCrew());
      expect(cubit.state, isA<CrewDeleted>());
      await cubit.close();
    });

    test(
      'final state is CrewDetailActionError when deleteCrew fails',
      () async {
        when(
          () => mockRepo.deleteCrew(_crewId),
        ).thenThrow(Exception('permission-denied'));
        final cubit = CrewDetailCubit(crewRepository: mockRepo);
        await loadAndAct(cubit, () => cubit.deleteCrew());
        expect(cubit.state, isA<CrewDetailActionError>());
        await cubit.close();
      },
    );
  });

  // ─── US5: Leave / Remove members ──────────────────────────────────────────
  group('CrewDetailCubit - US5 leave and remove', () {
    test('final state is CrewDeleted after leaveCrew', () async {
      when(() => mockRepo.leaveCrew(_crewId)).thenAnswer((_) async {});
      final cubit = CrewDetailCubit(crewRepository: mockRepo);
      await loadAndAct(cubit, () => cubit.leaveCrew());
      expect(cubit.state, isA<CrewDeleted>());
      await cubit.close();
    });

    test('final state is CrewDetailLoaded after removeMember', () async {
      when(
        () => mockRepo.streamMembers(_crewId),
      ).thenAnswer((_) => Stream.value([..._fakeMembers, _fakeBobMembership]));
      when(
        () => mockRepo.removeMember(_crewId, 'bob'),
      ).thenAnswer((_) async {});
      final cubit = CrewDetailCubit(crewRepository: mockRepo);
      await loadAndAct(cubit, () => cubit.removeMember('bob'));
      expect(cubit.state, isA<CrewDetailLoaded>());
      expectActionSuccess(cubit, CrewDetailAction.removeMember);
      expect(
        (cubit.state as CrewDetailActionSuccess).members,
        isNot(contains(_fakeBobMembership)),
      );
      await cubit.close();
    });
  });

  // ─── US2: Revoking pending invitations ────────────────────────────────────
  group('CrewDetailCubit - US2 revoke', () {
    test(
      'final state is CrewDetailLoaded after revoking an invitation',
      () async {
        when(
          () => mockRepo.streamPendingInvitationsForCrew(_crewId),
        ).thenAnswer((_) => Stream.value([_fakeInvitation]));
        when(
          () => mockRepo.rejectInvitation('crew1_bob'),
        ).thenAnswer((_) async {});
        final cubit = CrewDetailCubit(crewRepository: mockRepo);
        await loadAndAct(cubit, () => cubit.revokeInvitation('crew1_bob'));
        expect(cubit.state, isA<CrewDetailLoaded>());
        expectActionSuccess(cubit, CrewDetailAction.revokeInvitation);
        expect(
          (cubit.state as CrewDetailActionSuccess).pendingInvitations,
          isNot(contains(_fakeInvitation)),
        );
        verify(() => mockRepo.rejectInvitation('crew1_bob')).called(1);
        await cubit.close();
      },
    );

    test('final state is CrewDetailActionError when revoke fails', () async {
      when(
        () => mockRepo.rejectInvitation('crew1_bob'),
      ).thenThrow(Exception('permission-denied'));
      final cubit = CrewDetailCubit(crewRepository: mockRepo);
      await loadAndAct(cubit, () => cubit.revokeInvitation('crew1_bob'));
      expect(cubit.state, isA<CrewDetailActionError>());
      await cubit.close();
    });
  });
}
