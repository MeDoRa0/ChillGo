import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/live_meetup_snapshot.dart';
import '../../../domain/entities/live_meetup_status.dart';
import '../../../domain/repositories/live_meetup_repository.dart';

enum LiveMeetupViewStatus { initial, loading, ready, accessLost, failed }

enum StatusMutationState { idle, submitting, succeeded, superseded, failed }

class LiveMeetupState extends Equatable {
  const LiveMeetupState({
    this.status = LiveMeetupViewStatus.initial,
    this.snapshot,
    this.statusMutation = StatusMutationState.idle,
    this.failure,
  });
  final LiveMeetupViewStatus status;
  final LiveMeetupSnapshot? snapshot;
  final StatusMutationState statusMutation;
  final LiveMeetupFailure? failure;
  @override
  List<Object?> get props => [status, snapshot, statusMutation, failure];
}

class LiveMeetupCubit extends Cubit<LiveMeetupState> {
  LiveMeetupCubit({required this.repository}) : super(const LiveMeetupState());
  final LiveMeetupRepository repository;
  StreamSubscription<LiveMeetupSnapshot>? _subscription;
  String? _outingId;
  bool _accessLost = false;

  Future<void> watch(String outingId) async {
    _outingId = outingId;
    _accessLost = false;
    emit(const LiveMeetupState(status: LiveMeetupViewStatus.loading));
    await _subscription?.cancel();
    _subscription = repository
        .watchMeetup(outingId)
        .listen(
          (snapshot) {
            if (!_accessLost) {
              emit(
                LiveMeetupState(
                  status: LiveMeetupViewStatus.ready,
                  snapshot: snapshot,
                  statusMutation: state.statusMutation,
                  failure: state.statusMutation == StatusMutationState.failed
                      ? state.failure
                      : null,
                ),
              );
            }
          },
          onError: (Object error) {
            final failure = error is LiveMeetupFailure
                ? error
                : const LiveMeetupServiceFailure();
            if (failure is LiveMeetupAccessDenied ||
                failure is LiveMeetupAuthenticationFailure) {
              unawaited(_loseAccess(failure));
            } else {
              emit(
                LiveMeetupState(
                  status: state.snapshot == null
                      ? LiveMeetupViewStatus.failed
                      : LiveMeetupViewStatus.ready,
                  snapshot: state.snapshot,
                  failure: failure,
                ),
              );
            }
          },
        );
  }

  Future<void> setStatus(LiveMeetupStatus value) async {
    final outingId = _outingId;
    if (outingId == null || _accessLost) return;
    emit(
      LiveMeetupState(
        status: state.status,
        snapshot: state.snapshot,
        statusMutation: StatusMutationState.submitting,
      ),
    );
    try {
      final result = await repository.setStatus(outingId, value);
      if (_accessLost) return;
      emit(
        LiveMeetupState(
          status: state.status,
          snapshot: state.snapshot,
          statusMutation: result.status == LiveMeetupCommandStatus.superseded
              ? StatusMutationState.superseded
              : StatusMutationState.succeeded,
        ),
      );
    } on LiveMeetupFailure catch (failure) {
      if (failure is LiveMeetupAccessDenied) {
        await _loseAccess(failure);
      } else {
        emit(
          LiveMeetupState(
            status: state.status,
            snapshot: state.snapshot,
            statusMutation: StatusMutationState.failed,
            failure: failure,
          ),
        );
      }
    }
  }

  Future<void> _loseAccess(LiveMeetupFailure failure) {
    if (_accessLost) return Future.value();
    _accessLost = true;
    _outingId = null;
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    emit(
      LiveMeetupState(
        status: LiveMeetupViewStatus.accessLost,
        failure: failure,
      ),
    );
    return Future.value();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
