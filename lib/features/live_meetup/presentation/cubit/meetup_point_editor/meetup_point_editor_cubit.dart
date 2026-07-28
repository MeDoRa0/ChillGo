import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/meetup_point.dart';
import '../../../domain/repositories/live_meetup_repository.dart';
import '../../../domain/services/map_provider.dart';

enum MeetupPointEditorStatus {
  initial,
  loading,
  ready,
  searching,
  saving,
  saved,
  unavailable,
  failed,
}

class MeetupPointEditorState extends Equatable {
  const MeetupPointEditorState({
    this.status = MeetupPointEditorStatus.initial,
    this.locationText,
    this.point,
    this.results = const [],
    this.selection,
    this.confirmed = false,
    this.failure,
  });
  final MeetupPointEditorStatus status;
  final String? locationText;
  final MeetupPoint? point;
  final List<PlaceCandidate> results;
  final PlaceCandidate? selection;
  final bool confirmed;
  final LiveMeetupFailure? failure;
  @override
  List<Object?> get props => [
    status,
    locationText,
    point,
    results,
    selection,
    confirmed,
    failure,
  ];
}

class MeetupPointEditorCubit extends Cubit<MeetupPointEditorState> {
  MeetupPointEditorCubit({required this.repository, required this.mapProvider})
    : super(const MeetupPointEditorState());
  final LiveMeetupRepository repository;
  final MapProvider mapProvider;
  StreamSubscription<MeetupPointPreparation>? _subscription;
  String? _outingId;

  Future<void> watch(String outingId) async {
    _outingId = outingId;
    emit(const MeetupPointEditorState(status: MeetupPointEditorStatus.loading));
    await _subscription?.cancel();
    _subscription = repository
        .watchMeetupPointPreparation(outingId)
        .listen(
          (preparation) => emit(
            MeetupPointEditorState(
              status: MeetupPointEditorStatus.ready,
              locationText: preparation.locationText,
              point: preparation.point,
            ),
          ),
          onError: (Object error) {
            emit(
              MeetupPointEditorState(
                status: error is LiveMeetupAccessDenied
                    ? MeetupPointEditorStatus.unavailable
                    : MeetupPointEditorStatus.failed,
                failure: error is LiveMeetupFailure
                    ? error
                    : const LiveMeetupServiceFailure(),
              ),
            );
          },
        );
  }

  Future<void> search(String query) async {
    emit(
      MeetupPointEditorState(
        status: MeetupPointEditorStatus.searching,
        locationText: state.locationText,
        point: state.point,
      ),
    );
    try {
      final results = await mapProvider.search(query);
      emit(
        MeetupPointEditorState(
          status: MeetupPointEditorStatus.ready,
          locationText: state.locationText,
          point: state.point,
          results: results,
        ),
      );
    } on LiveMeetupFailure catch (failure) {
      emit(
        MeetupPointEditorState(
          status: MeetupPointEditorStatus.failed,
          locationText: state.locationText,
          point: state.point,
          failure: failure,
        ),
      );
    }
  }

  void select(PlaceCandidate candidate) {
    emit(
      MeetupPointEditorState(
        status: MeetupPointEditorStatus.ready,
        locationText: state.locationText,
        point: state.point,
        results: state.results,
        selection: candidate,
      ),
    );
  }

  void confirm(bool value) {
    emit(
      MeetupPointEditorState(
        status: state.status,
        locationText: state.locationText,
        point: state.point,
        results: state.results,
        selection: state.selection,
        confirmed: value,
      ),
    );
  }

  Future<void> save() async {
    final outingId = _outingId;
    final selection = state.selection;
    final locationText = state.locationText;
    if (outingId == null ||
        selection == null ||
        locationText == null ||
        !state.confirmed) {
      return;
    }
    emit(
      MeetupPointEditorState(
        status: MeetupPointEditorStatus.saving,
        locationText: locationText,
        point: state.point,
        selection: selection,
        confirmed: true,
      ),
    );
    try {
      await repository.setMeetupPoint(
        outingId,
        selection.coordinate,
        locationText,
      );
      emit(
        MeetupPointEditorState(
          status: MeetupPointEditorStatus.saved,
          locationText: locationText,
          point: state.point,
          selection: selection,
          confirmed: true,
        ),
      );
    } on LiveMeetupFailure catch (failure) {
      emit(
        MeetupPointEditorState(
          status: MeetupPointEditorStatus.failed,
          locationText: locationText,
          point: state.point,
          selection: selection,
          failure: failure,
        ),
      );
    }
  }

  Future<void> accessLost() async {
    _outingId = null;
    await _subscription?.cancel();
    _subscription = null;
    emit(
      const MeetupPointEditorState(status: MeetupPointEditorStatus.unavailable),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
