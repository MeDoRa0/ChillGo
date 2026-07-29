import 'dart:async';
import 'dart:math';

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
  resolving,
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
    this.query = '',
    this.results = const [],
    this.selection,
    this.confirmed = false,
    this.failure,
  });
  final MeetupPointEditorStatus status;
  final String? locationText;
  final MeetupPoint? point;
  final String query;
  final List<PlaceCandidate> results;
  final PlaceCandidate? selection;
  final bool confirmed;
  final LiveMeetupFailure? failure;
  @override
  List<Object?> get props => [
    status,
    locationText,
    point,
    query,
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
  String? _searchSessionToken;
  int _searchSequence = 0;
  static final Random _random = Random.secure();

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
    final trimmedQuery = query.trim();
    final searchSequence = ++_searchSequence;
    if (trimmedQuery.length < 3) {
      _searchSessionToken = null;
      emit(
        MeetupPointEditorState(
          status: MeetupPointEditorStatus.ready,
          locationText: state.locationText,
          point: state.point,
          query: trimmedQuery,
        ),
      );
      return;
    }
    final sessionToken = _searchSessionToken ??= _newSessionToken();
    emit(
      MeetupPointEditorState(
        status: MeetupPointEditorStatus.searching,
        locationText: state.locationText,
        point: state.point,
        query: trimmedQuery,
      ),
    );
    try {
      final results = await mapProvider.search(
        trimmedQuery,
        sessionToken: sessionToken,
      );
      if (isClosed || searchSequence != _searchSequence) return;
      emit(
        MeetupPointEditorState(
          status: MeetupPointEditorStatus.ready,
          locationText: state.locationText,
          point: state.point,
          query: trimmedQuery,
          results: results,
        ),
      );
    } on LiveMeetupFailure catch (failure) {
      if (isClosed || searchSequence != _searchSequence) return;
      emit(
        MeetupPointEditorState(
          status: MeetupPointEditorStatus.failed,
          locationText: state.locationText,
          point: state.point,
          query: trimmedQuery,
          failure: failure,
        ),
      );
    }
  }

  Future<void> select(PlaceCandidate candidate) async {
    final sessionToken = _searchSessionToken;
    if (sessionToken == null) return;
    final searchSequence = ++_searchSequence;
    emit(
      MeetupPointEditorState(
        status: MeetupPointEditorStatus.resolving,
        locationText: state.locationText,
        point: state.point,
        query: state.query,
        results: state.results,
        selection: candidate,
      ),
    );
    try {
      final resolved = await mapProvider.resolvePlace(
        candidate,
        sessionToken: sessionToken,
      );
      if (isClosed || searchSequence != _searchSequence) return;
      _searchSessionToken = null;
      emit(
        MeetupPointEditorState(
          status: MeetupPointEditorStatus.ready,
          locationText: state.locationText,
          point: state.point,
          query: state.query,
          results: state.results,
          selection: resolved,
        ),
      );
    } on LiveMeetupFailure catch (failure) {
      if (isClosed || searchSequence != _searchSequence) return;
      emit(
        MeetupPointEditorState(
          status: MeetupPointEditorStatus.failed,
          locationText: state.locationText,
          point: state.point,
          query: state.query,
          results: state.results,
          selection: candidate,
          failure: failure,
        ),
      );
    }
  }

  void confirm(bool value) {
    emit(
      MeetupPointEditorState(
        status: state.status,
        locationText: state.locationText,
        point: state.point,
        query: state.query,
        results: state.results,
        selection: state.selection,
        confirmed: value,
      ),
    );
  }

  Future<void> save() async {
    final outingId = _outingId;
    final selection = state.selection;
    final coordinate = selection?.coordinate;
    final locationText = state.locationText;
    if (outingId == null ||
        coordinate == null ||
        locationText == null ||
        !state.confirmed) {
      return;
    }
    emit(
      MeetupPointEditorState(
        status: MeetupPointEditorStatus.saving,
        locationText: locationText,
        point: state.point,
        query: state.query,
        selection: selection,
        confirmed: true,
      ),
    );
    try {
      await repository.setMeetupPoint(outingId, coordinate, locationText);
      emit(
        MeetupPointEditorState(
          status: MeetupPointEditorStatus.saved,
          locationText: locationText,
          point: state.point,
          query: state.query,
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
          query: state.query,
          selection: selection,
          failure: failure,
        ),
      );
    }
  }

  Future<void> accessLost() async {
    _outingId = null;
    _searchSessionToken = null;
    _searchSequence++;
    await _subscription?.cancel();
    _subscription = null;
    emit(
      const MeetupPointEditorState(status: MeetupPointEditorStatus.unavailable),
    );
  }

  static String _newSessionToken() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
