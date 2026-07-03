import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/crew_invitation.dart';
import '../../../domain/repositories/crew_repository.dart';

// --- State ---
abstract class InvitationsState extends Equatable {
  const InvitationsState();
  @override
  List<Object?> get props => [];
}

class InvitationsInitial extends InvitationsState {
  const InvitationsInitial();
}

class InvitationsLoading extends InvitationsState {
  const InvitationsLoading();
}

class InvitationsLoaded extends InvitationsState {
  final List<CrewInvitation> invitations;
  const InvitationsLoaded(this.invitations);
  @override
  List<Object?> get props => [invitations];
}

class InvitationsError extends InvitationsState {
  final String message;
  const InvitationsError(this.message);
  @override
  List<Object?> get props => [message];
}

class InvitationActionInProgress extends InvitationsState {
  const InvitationActionInProgress();
}

class InvitationActionError extends InvitationsState {
  final String message;
  const InvitationActionError(this.message);
  @override
  List<Object?> get props => [message];
}

// --- Cubit ---
class InvitationsCubit extends Cubit<InvitationsState> {
  final CrewRepository crewRepository;
  StreamSubscription<List<CrewInvitation>>? _sub;
  List<CrewInvitation> _currentInvitations = [];

  InvitationsCubit({required this.crewRepository})
    : super(const InvitationsInitial());

  void loadInvitations() {
    emit(const InvitationsLoading());
    _sub?.cancel();
    _sub = crewRepository.streamReceivedInvitations().listen(
      (invitations) {
        _currentInvitations = invitations;
        emit(InvitationsLoaded(invitations));
      },
      onError: (Object e) {
        emit(InvitationsError(e.toString()));
      },
    );
  }

  Future<void> acceptInvitation(String invitationId) async {
    emit(const InvitationActionInProgress());
    try {
      await crewRepository.acceptInvitation(invitationId);
      _currentInvitations = _withoutInvitation(invitationId);
      emit(InvitationsLoaded(_currentInvitations));
    } catch (e) {
      emit(InvitationActionError(e.toString()));
    }
  }

  Future<void> rejectInvitation(String invitationId) async {
    emit(const InvitationActionInProgress());
    try {
      await crewRepository.rejectInvitation(invitationId);
      _currentInvitations = _withoutInvitation(invitationId);
      emit(InvitationsLoaded(_currentInvitations));
    } catch (e) {
      emit(InvitationActionError(e.toString()));
    }
  }

  List<CrewInvitation> _withoutInvitation(String invitationId) {
    return _currentInvitations
        .where((invitation) => invitation.id != invitationId)
        .toList(growable: false);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
