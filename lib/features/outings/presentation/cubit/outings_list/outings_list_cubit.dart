import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/outing.dart';
import '../../../domain/repositories/outing_repository.dart';

abstract class OutingsListState extends Equatable {
  const OutingsListState();

  @override
  List<Object?> get props => [];
}

class OutingsListInitial extends OutingsListState {
  const OutingsListInitial();
}

class OutingsListLoading extends OutingsListState {
  const OutingsListLoading();
}

class OutingsListLoaded extends OutingsListState {
  final List<Outing> outings;

  const OutingsListLoaded(this.outings);

  @override
  List<Object?> get props => [outings];
}

class OutingsListError extends OutingsListState {
  final String message;

  const OutingsListError(this.message);

  @override
  List<Object?> get props => [message];
}

class OutingsListCubit extends Cubit<OutingsListState> {
  final OutingRepository outingRepository;
  StreamSubscription<List<Outing>>? _subscription;
  final Set<String> _cleanupRequestedOutingIds = {};

  OutingsListCubit({required this.outingRepository})
    : super(const OutingsListInitial());

  void load(String crewId) {
    emit(const OutingsListLoading());
    _subscription?.cancel();
    _subscription = outingRepository
        .streamCrewOutings(crewId)
        .listen(
          _acceptOutings,
          onError: (Object error) => emit(OutingsListError(error.toString())),
        );
  }

  void _acceptOutings(List<Outing> outings) {
    final now = DateTime.now();
    for (final outing in outings.where(
      (outing) => outing.isCleanupEligibleAt(now),
    )) {
      if (_cleanupRequestedOutingIds.add(outing.id)) {
        unawaited(_requestExpiryCleanup(outing.id));
      }
    }
    emit(
      OutingsListLoaded(
        outings.where((outing) => !outing.isOutdatedAt(now)).toList(),
      ),
    );
  }

  Future<void> _requestExpiryCleanup(String outingId) async {
    try {
      await outingRepository.requestExpiryCleanup(outingId: outingId);
    } catch (error, stackTrace) {
      if (!isClosed) addError(error, stackTrace);
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
