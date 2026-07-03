import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/crew.dart';
import '../../../domain/entities/crew_membership.dart';
import '../../../domain/entities/crew_invitation.dart';
import '../../../domain/repositories/crew_repository.dart';

// --- State ---
abstract class CrewDetailState extends Equatable {
  const CrewDetailState();
  @override
  List<Object?> get props => [];
}

class CrewDetailInitial extends CrewDetailState {
  const CrewDetailInitial();
}

class CrewDetailLoading extends CrewDetailState {
  const CrewDetailLoading();
}

class CrewDetailLoaded extends CrewDetailState {
  final Crew crew;
  final List<CrewMembership> members;
  final List<CrewInvitation> pendingInvitations;
  const CrewDetailLoaded({
    required this.crew,
    required this.members,
    required this.pendingInvitations,
  });
  @override
  List<Object?> get props => [crew, members, pendingInvitations];
}

class CrewDetailError extends CrewDetailState {
  final String message;
  const CrewDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class CrewDetailActionInProgress extends CrewDetailState {
  const CrewDetailActionInProgress();
}

class CrewDetailActionError extends CrewDetailState {
  final String message;
  const CrewDetailActionError(this.message);
  @override
  List<Object?> get props => [message];
}

class CrewDeleted extends CrewDetailState {
  const CrewDeleted();
}

// --- Cubit ---
class CrewDetailCubit extends Cubit<CrewDetailState> {
  final CrewRepository crewRepository;

  StreamSubscription<Crew?>? _crewSub;
  StreamSubscription<List<CrewMembership>>? _membersSub;
  StreamSubscription<List<CrewInvitation>>? _invitationsSub;

  Crew? _crew;
  List<CrewMembership> _members = [];
  List<CrewInvitation> _pendingInvitations = [];
  String? _crewId;

  CrewDetailCubit({required this.crewRepository})
    : super(const CrewDetailInitial());

  void loadCrew(String crewId) {
    _crewId = crewId;
    emit(const CrewDetailLoading());

    _crewSub?.cancel();
    _crewSub = crewRepository.streamCrew(crewId).listen((crew) {
      _crew = crew;
      _emitLoaded();
    }, onError: (Object e) => emit(CrewDetailError(e.toString())));

    _membersSub?.cancel();
    _membersSub = crewRepository.streamMembers(crewId).listen((members) {
      _members = members;
      _emitLoaded();
    }, onError: (Object e) => emit(CrewDetailError(e.toString())));

    _invitationsSub?.cancel();
    _invitationsSub = crewRepository
        .streamPendingInvitationsForCrew(crewId)
        .listen((invitations) {
          _pendingInvitations = invitations;
          _emitLoaded();
        }, onError: (Object e) => emit(CrewDetailError(e.toString())));
  }

  void _emitLoaded() {
    final crew = _crew;
    if (crew == null) return;
    emit(
      CrewDetailLoaded(
        crew: crew,
        members: _members,
        pendingInvitations: _pendingInvitations,
      ),
    );
  }

  Future<void> inviteUser(String username) async {
    if (_crewId == null) return;
    emit(const CrewDetailActionInProgress());
    try {
      await crewRepository.inviteUser(_crewId!, username);
      _emitLoaded();
    } on Exception catch (e) {
      final msg = _mapInviteError(e.toString());
      emit(CrewDetailActionError(msg));
    }
  }

  Future<void> updateCrewName(String name) async {
    if (_crewId == null) return;
    emit(const CrewDetailActionInProgress());
    try {
      await crewRepository.updateCrewName(_crewId!, name);
      _emitLoaded();
    } catch (e) {
      emit(CrewDetailActionError(e.toString()));
    }
  }

  Future<void> deleteCrew() async {
    if (_crewId == null) return;
    emit(const CrewDetailActionInProgress());
    try {
      await crewRepository.deleteCrew(_crewId!);
      emit(const CrewDeleted());
    } catch (e) {
      emit(CrewDetailActionError(e.toString()));
    }
  }

  Future<void> leaveCrew() async {
    if (_crewId == null) return;
    emit(const CrewDetailActionInProgress());
    try {
      await crewRepository.leaveCrew(_crewId!);
      emit(const CrewDeleted());
    } catch (e) {
      emit(CrewDetailActionError(e.toString()));
    }
  }

  Future<void> removeMember(String userId) async {
    if (_crewId == null) return;
    emit(const CrewDetailActionInProgress());
    try {
      await crewRepository.removeMember(_crewId!, userId);
      _emitLoaded();
    } catch (e) {
      emit(CrewDetailActionError(e.toString()));
    }
  }

  /// Owner-only: revoke a pending invitation by deleting its document.
  /// This delegates to [CrewRepository.rejectInvitation] — the operation is
  /// identical, but exposed under a domain-meaningful name at the cubit
  /// layer so the screen code stays readable.
  Future<void> revokeInvitation(String invitationId) async {
    emit(const CrewDetailActionInProgress());
    try {
      await crewRepository.rejectInvitation(invitationId);
      _emitLoaded();
    } catch (e) {
      emit(CrewDetailActionError(e.toString()));
    }
  }

  String _mapInviteError(String raw) {
    if (raw.contains('username-not-found')) return 'Username not found.';
    if (raw.contains('already-a-member')) return 'User is already a member.';
    if (raw.contains('already-invited')) {
      return 'User already has a pending invitation.';
    }
    return raw;
  }

  @override
  Future<void> close() {
    _crewSub?.cancel();
    _membersSub?.cancel();
    _invitationsSub?.cancel();
    return super.close();
  }
}
