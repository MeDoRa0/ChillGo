import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/outing_status.dart';
import '../../../domain/repositories/outing_repository.dart';

abstract class OutingDetailState extends Equatable {
  const OutingDetailState();

  @override
  List<Object?> get props => [];
}

class OutingDetailInitial extends OutingDetailState {
  const OutingDetailInitial();
}

class OutingDetailLoading extends OutingDetailState {
  const OutingDetailLoading();
}

class OutingDetailLoaded extends OutingDetailState {
  final OutingDetail detail;
  final String? actionMessage;

  const OutingDetailLoaded(this.detail, {this.actionMessage});

  @override
  List<Object?> get props => [detail, actionMessage];
}

class OutingDetailError extends OutingDetailState {
  final String message;

  const OutingDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class OutingDetailCubit extends Cubit<OutingDetailState> {
  final OutingRepository outingRepository;
  StreamSubscription<OutingDetail?>? _subscription;
  OutingDetail? _currentDetail;

  OutingDetailCubit({required this.outingRepository})
    : super(const OutingDetailInitial());

  void load(String outingId) {
    emit(const OutingDetailLoading());
    _subscription?.cancel();
    _subscription = outingRepository.streamOutingDetail(outingId).listen(
      (detail) {
        if (detail == null) {
          emit(const OutingDetailError('Outing not found.'));
          return;
        }
        _currentDetail = detail;
        emit(OutingDetailLoaded(detail));
      },
      onError: (Object error) => emit(OutingDetailError(error.toString())),
    );
  }

  Future<void> addParticipant(String userId) async {
    await _runAction(
      () => outingRepository.addParticipant(
        outingId: _requireDetail().outing.id,
        userId: userId,
      ),
      'Participant added.',
    );
  }

  Future<void> removeParticipant(String userId) async {
    await _runAction(
      () => outingRepository.removeParticipant(
        outingId: _requireDetail().outing.id,
        userId: userId,
      ),
      'Participant removed.',
    );
  }

  Future<void> changeStatus(OutingStatus status) async {
    await _runAction(
      () => outingRepository.changeLifecycleStatus(
        outingId: _requireDetail().outing.id,
        nextStatus: status,
      ),
      'Status updated.',
    );
  }

  Future<void> _runAction(Future<void> Function() action, String message) async {
    try {
      await action();
      final detail = _currentDetail;
      if (detail != null) {
        emit(OutingDetailLoaded(detail, actionMessage: message));
      }
    } catch (error) {
      final detail = _currentDetail;
      if (detail != null) {
        emit(OutingDetailLoaded(detail, actionMessage: error.toString()));
      } else {
        emit(OutingDetailError(error.toString()));
      }
    }
  }

  OutingDetail _requireDetail() {
    final detail = _currentDetail;
    if (detail == null) throw Exception('outing-not-loaded');
    return detail;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
