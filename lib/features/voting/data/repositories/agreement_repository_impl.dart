import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../outings/domain/entities/attendance_status.dart';
import '../../domain/entities/agreement_category.dart';
import '../../domain/entities/agreement_command.dart';
import '../../domain/entities/agreement_vote.dart';
import '../../domain/repositories/agreement_repository.dart';
import '../datasources/firestore_agreement_datasource.dart';

class AgreementRepositoryImpl implements AgreementRepository {
  AgreementRepositoryImpl({required this.datasource, required this.currentUid});
  final FirestoreAgreementDatasource datasource;
  final String Function() currentUid;
  String get _uid {
    final value = currentUid();
    if (value.isEmpty) throw const AgreementAccessDenied('Sign in required.');
    return value;
  }

  @override
  Stream<AgreementDetail?> streamAgreement(String outingId) {
    late StreamSubscription roundsSub, proposalsSub, resultsSub, votesSub;
    final controller = StreamController<AgreementDetail?>();
    var rounds = <dynamic>[];
    var proposals = <dynamic>[];
    var results = <dynamic>[];
    var votes = <AgreementVote>[];
    void emit() => controller.add(
      AgreementDetail(
        activeRound: rounds.where((e) => e.isOpen).firstOrNull,
        rounds: List.from(rounds),
        proposals: List.from(proposals),
        myVotes: votes,
        results: List.from(results),
      ),
    );
    controller.onListen = () {
      roundsSub = datasource.streamRounds(outingId).listen((v) {
        rounds = v;
        emit();
      }, onError: controller.addError);
      proposalsSub = datasource.streamProposals(outingId).listen((v) {
        proposals = v;
        emit();
      }, onError: controller.addError);
      resultsSub = datasource.streamResults(outingId).listen((v) {
        results = v;
        emit();
      }, onError: controller.addError);
      votesSub = datasource
          .streamRounds(outingId)
          .asyncExpand(
            (v) => v.where((r) => r.isOpen).isEmpty
                ? Stream.value(<AgreementVote>[])
                : datasource.streamMyVotes(
                    v.firstWhere((r) => r.isOpen).id,
                    _uid,
                  ),
          )
          .listen((v) {
            votes = v;
            emit();
          }, onError: controller.addError);
    };
    controller.onCancel = () async {
      await Future.wait([
        roundsSub.cancel(),
        proposalsSub.cancel(),
        resultsSub.cancel(),
        votesSub.cancel(),
      ]);
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
  Future<void> respondToOuting(String id, AttendanceStatus s) =>
      s == AttendanceStatus.invited
      ? Future.error(
          const AgreementValidationFailure('Choose accepted or declined.'),
        )
      : _guard(() => datasource.respondToOuting(id, _uid, s.value));
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
  }) => _command('confirm_round', id, {
    if (selectedTimeProposalId != null)
      'selectedTimeProposalId': selectedTimeProposalId,
    if (selectedLocationProposalId != null)
      'selectedLocationProposalId': selectedLocationProposalId,
  });
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
  Future<String> cancelOuting(String id, String reason) {
    final r = reason.trim();
    if (r.length < 3 || r.length > 200) {
      throw const AgreementValidationFailure(
        'Reason must be 3-200 characters.',
      );
    }
    return _command('cancel_outing', id, {'reason': r});
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
