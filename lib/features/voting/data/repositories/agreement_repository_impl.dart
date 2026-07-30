import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../outings/domain/entities/attendance_status.dart';
import '../../../outings/domain/entities/outing_status.dart';
import '../../../live_meetup/domain/repositories/live_meetup_repository.dart';
import '../../domain/entities/agreement_proposal.dart';
import '../../domain/entities/agreement_result.dart';
import '../../domain/entities/agreement_round.dart';
import '../../domain/entities/agreement_category.dart';
import '../../domain/entities/agreement_command.dart';
import '../../domain/entities/agreement_vote.dart';
import '../../domain/repositories/agreement_repository.dart';
import '../datasources/firestore_agreement_datasource.dart';
import '../../../live_meetup/domain/services/live_meetup_transition_service.dart';

class AgreementRepositoryImpl implements AgreementRepository {
  AgreementRepositoryImpl({
    required this.datasource,
    required this.currentUid,
    required this.transitionService,
  });
  final FirestoreAgreementDatasource datasource;
  final String Function() currentUid;
  final LiveMeetupTransitionService transitionService;
  String get _uid {
    final value = currentUid();
    if (value.isEmpty) throw const AgreementAccessDenied('Sign in required.');
    return value;
  }

  @override
  Stream<AgreementDetail?> streamAgreement(String outingId) {
    late StreamSubscription roundsSub, proposalsSub, resultsSub;
    StreamSubscription? votesSub;
    final controller = StreamController<AgreementDetail?>();
    var rounds = <AgreementRound>[];
    var proposals = <AgreementProposal>[];
    var results = <AgreementResult>[];
    var votes = <AgreementVote>[];
    String? watchedVoteRoundId;
    var voteSubscriptionGeneration = 0;

    void emit() => controller.add(
      AgreementDetail(
        activeRound: rounds.where((e) => e.isOpen).firstOrNull,
        rounds: List.from(rounds),
        proposals: List.from(proposals),
        myVotes: votes,
        results: List.from(results),
      ),
    );

    Future<void> replaceVoteSubscription(String? roundId) async {
      if (watchedVoteRoundId == roundId) return;
      watchedVoteRoundId = roundId;
      final generation = ++voteSubscriptionGeneration;
      await votesSub?.cancel();
      if (generation != voteSubscriptionGeneration) return;
      votesSub = null;
      votes = <AgreementVote>[];
      emit();
      if (roundId == null) return;
      votesSub = datasource.streamMyVotes(roundId, _uid).listen((currentVotes) {
        votes = currentVotes;
        emit();
      }, onError: controller.addError);
    }

    void watchVotesFor(String? roundId) {
      unawaited(
        replaceVoteSubscription(roundId).catchError(
          (Object error, StackTrace stack) => controller.addError(error, stack),
        ),
      );
    }

    controller.onListen = () {
      roundsSub = datasource.streamRounds(outingId).listen((currentRounds) {
        rounds = currentRounds;
        emit();
        watchVotesFor(
          currentRounds.where((round) => round.isOpen).firstOrNull?.id,
        );
      }, onError: controller.addError);
      proposalsSub = datasource.streamProposals(outingId).listen((
        currentProposals,
      ) {
        proposals = currentProposals;
        emit();
      }, onError: controller.addError);
      resultsSub = datasource.streamResults(outingId).listen((currentResults) {
        results = currentResults;
        emit();
      }, onError: controller.addError);
    };
    controller.onCancel = () async {
      voteSubscriptionGeneration++;
      await roundsSub.cancel();
      await proposalsSub.cancel();
      await resultsSub.cancel();
      await votesSub?.cancel();
    };
    return controller.stream;
  }

  @override
  Stream<List<AgreementVote>> streamMyVotes(String roundId) =>
      datasource.streamMyVotes(roundId, _uid);
  @override
  Stream<AgreementCommand?> streamCommand(String commandId) =>
      datasource.streamCommand(commandId);
  @override
  Future<void> respondToOuting(String id, AttendanceStatus s) async {
    if (s == AttendanceStatus.invited) {
      throw const AgreementValidationFailure('Choose accepted or declined.');
    }
    await _guard(() async {
      final current = await datasource.participantAttendance(id, _uid);
      if (s == AttendanceStatus.declined && current == 'accepted') {
        final result = await transitionService.declineAttendance(id);
        if (result.status != LiveMeetupTransitionStatus.succeeded) {
          throw result.failure ?? const LiveMeetupServiceFailure();
        }
        return;
      }
      await datasource.respondToOuting(id, _uid, s.value);
    });
  }

  @override
  Future<void> castVote(String r, AgreementCategory c, String p) =>
      p.trim().isEmpty
      ? Future.error(const AgreementValidationFailure('Proposal required.'))
      : _guard(
          () => datasource.castVote(
            roundId: r,
            category: c,
            proposalId: p,
            uid: _uid,
          ),
        );
  @override
  Future<void> withdrawVote(String r, AgreementCategory c) =>
      _guard(() => datasource.withdrawVote(r, c, _uid));
  Future<String> _command(
    String type,
    String outingId, [
    Map<String, Object?> payload = const {},
  ]) => _guard(
    () => datasource.createCommand(
      type: type,
      outingId: outingId,
      uid: _uid,
      payload: payload,
    ),
  );
  @override
  Future<String> openRound(String id) => _command('open_round', id);
  @override
  Future<String> createTimeProposal(String id, DateTime value) {
    if (!value.toUtc().isAfter(DateTime.now().toUtc())) {
      throw const AgreementValidationFailure('Time must be in the future.');
    }
    return _command('create_proposal', id, {
      'category': 'time',
      'timeValue': Timestamp.fromDate(value.toUtc()),
    });
  }

  @override
  Future<String> createLocationProposal(String id, String value) {
    final v = value.trim();
    if (v.isEmpty || v.length > 120) {
      throw const AgreementValidationFailure(
        'Location must be 1-120 characters.',
      );
    }
    return _command('create_proposal', id, {
      'category': 'location',
      'locationText': v,
    });
  }

  @override
  Future<String> previewConfirmation(String id) =>
      _command('preview_confirmation', id);
  @override
  Future<String> confirmRound(
    String id, {
    String? selectedTimeProposalId,
    String? selectedLocationProposalId,
  }) {
    final payload = <String, Object?>{
      ...?(selectedTimeProposalId != null
          ? {'selectedTimeProposalId': selectedTimeProposalId}
          : null),
      ...?(selectedLocationProposalId != null
          ? {'selectedLocationProposalId': selectedLocationProposalId}
          : null),
    };
    return _command('confirm_round', id, payload);
  }

  @override
  Future<String> reopenRound(String id, String reason) {
    final r = reason.trim();
    if (r.length < 3 || r.length > 200) {
      throw const AgreementValidationFailure(
        'Reason must be 3-200 characters.',
      );
    }
    return _command('reopen_round', id, {'reason': r});
  }

  @override
  Future<String> cancelOuting(String id, String reason) async {
    final r = reason.trim();
    if (r.length < 3 || r.length > 200) {
      throw const AgreementValidationFailure(
        'Reason must be 3-200 characters.',
      );
    }
    final result = await transitionService.endOuting(
      id,
      OutingStatus.cancelled,
    );
    if (result.status != LiveMeetupTransitionStatus.succeeded) {
      throw result.failure ?? const LiveMeetupServiceFailure();
    }
    return result.transitionId;
  }

  @override
  Future<String> deleteOuting(String id) => _command('delete_outing', id);

  @override
  Future<String> requestOutingExpiry(String id) =>
      _command('expire_outing', id);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const AgreementAccessDenied('Access denied.');
      }
      if (e.code == 'unavailable') {
        throw const AgreementNetworkFailure('Network unavailable.');
      }
      throw AgreementServiceFailure(e.message ?? 'Agreement service failed.');
    }
  }
}
