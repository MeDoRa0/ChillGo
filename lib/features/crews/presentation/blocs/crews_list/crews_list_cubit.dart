import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/crew.dart';
import '../../../domain/repositories/crew_repository.dart';

// --- State ---
abstract class CrewsListState extends Equatable {
  const CrewsListState();
  @override
  List<Object?> get props => [];
}

class CrewsListInitial extends CrewsListState {
  const CrewsListInitial();
}

class CrewsListLoading extends CrewsListState {
  const CrewsListLoading();
}

class CrewsListLoaded extends CrewsListState {
  final List<Crew> crews;
  const CrewsListLoaded(this.crews);
  @override
  List<Object?> get props => [crews];
}

class CrewsListError extends CrewsListState {
  final String message;
  const CrewsListError(this.message);
  @override
  List<Object?> get props => [message];
}

class CrewCreating extends CrewsListState {
  final List<Crew> crews;
  const CrewCreating(this.crews);
  @override
  List<Object?> get props => [crews];
}

class CrewCreated extends CrewsListState {
  final String crewId;
  final List<Crew> crews;
  final List<String> failedInviteUsernames;

  const CrewCreated(
    this.crewId,
    this.crews, {
    this.failedInviteUsernames = const [],
  });

  @override
  List<Object?> get props => [crewId, crews, failedInviteUsernames];
}

class CrewCreateError extends CrewsListState {
  final String message;
  const CrewCreateError(this.message);
  @override
  List<Object?> get props => [message];
}

// --- Cubit ---
class CrewsListCubit extends Cubit<CrewsListState> {
  final CrewRepository crewRepository;
  StreamSubscription<List<Crew>>? _crewsSub;
  List<Crew> _currentCrews = [];
  bool _isCreating = false;

  CrewsListCubit({required this.crewRepository})
    : super(const CrewsListInitial());

  void loadCrews() {
    emit(const CrewsListLoading());
    _crewsSub?.cancel();
    _crewsSub = crewRepository.streamCrews().listen(
      (crews) {
        _currentCrews = crews;
        emit(CrewsListLoaded(crews));
      },
      onError: (Object e) {
        emit(CrewsListError(e.toString()));
      },
    );
  }

  Future<void> createCrew(String name) async {
    await createCrewWithInvites(name, const []);
  }

  Future<void> createCrewWithInvites(
    String name,
    List<String> usernames,
  ) async {
    if (_isCreating) return;
    _isCreating = true;
    emit(CrewCreating(_currentCrews));
    try {
      final crewId = await crewRepository.createCrew(name);
      final failedInviteUsernames = await _inviteSelectedUsernames(
        crewId,
        usernames,
      );
      emit(
        CrewCreated(
          crewId,
          _currentCrews,
          failedInviteUsernames: failedInviteUsernames,
        ),
      );
    } catch (e) {
      emit(CrewCreateError(e.toString()));
    } finally {
      _isCreating = false;
    }
  }

  Future<bool> usernameExists(String username) {
    return crewRepository.usernameExists(username);
  }

  Future<List<String>> _inviteSelectedUsernames(
    String crewId,
    List<String> usernames,
  ) async {
    final failedInviteUsernames = <String>[];
    for (final username in usernames) {
      try {
        await crewRepository.inviteUser(crewId, username);
      } catch (_) {
        // The crew already exists; surface invite failures without undoing it.
        failedInviteUsernames.add(username);
      }
    }
    return failedInviteUsernames;
  }

  @override
  Future<void> close() {
    _crewsSub?.cancel();
    return super.close();
  }
}
