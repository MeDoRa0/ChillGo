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
  const CrewCreating();
}

class CrewCreated extends CrewsListState {
  final String crewId;
  const CrewCreated(this.crewId);
  @override
  List<Object?> get props => [crewId];
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

  CrewsListCubit({required this.crewRepository})
    : super(const CrewsListInitial());

  void loadCrews() {
    emit(const CrewsListLoading());
    _crewsSub?.cancel();
    _crewsSub = crewRepository.streamCrews().listen(
      (crews) {
        emit(CrewsListLoaded(crews));
      },
      onError: (Object e) {
        emit(CrewsListError(e.toString()));
      },
    );
  }

  Future<void> createCrew(String name) async {
    emit(const CrewCreating());
    try {
      final crewId = await crewRepository.createCrew(name);
      emit(CrewCreated(crewId));
    } catch (e) {
      emit(CrewCreateError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _crewsSub?.cancel();
    return super.close();
  }
}
