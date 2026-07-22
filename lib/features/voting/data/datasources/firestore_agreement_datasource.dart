import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/data/firestore_timestamp.dart';

import '../../domain/entities/agreement_category.dart';
import '../../domain/entities/agreement_result.dart';
import '../models/agreement_command_model.dart';
import '../models/agreement_proposal_model.dart';
import '../models/agreement_round_model.dart';
import '../models/agreement_vote_model.dart';

class FirestoreAgreementDatasource {
  FirestoreAgreementDatasource({required this.firestore});
  final FirebaseFirestore firestore;

  Stream<List<AgreementRoundModel>> streamRounds(String outingId) => firestore
      .collection('agreement_rounds')
      .where('outingId', isEqualTo: outingId)
      .snapshots()
      .map(
        (s) =>
            s.docs
                .map((d) => AgreementRoundModel.fromMap(d.data(), d.id))
                .toList()
              ..sort((a, b) => b.sequence.compareTo(a.sequence)),
      );
  Stream<List<AgreementProposalModel>> streamProposals(String outingId) =>
      firestore
          .collection('agreement_proposals')
          .where('outingId', isEqualTo: outingId)
          .snapshots()
          .map(
            (s) => s.docs
                .map((d) => AgreementProposalModel.fromMap(d.data(), d.id))
                .toList(),
          );
  Stream<List<AgreementResult>> streamResults(String outingId) => firestore
      .collection('agreement_results')
      .where('outingId', isEqualTo: outingId)
      .snapshots()
      .map((snapshot) {
        final values = <AgreementResult>[];
        for (final category in AgreementCategory.values) {
          final docs = snapshot.docs
              .where((d) => d.data()['category'] == category.value)
              .toList();
          if (docs.isEmpty) continue;
          final selected = docs
              .where((d) => d.data()['isSelected'] == true)
              .firstOrNull;
          if (selected == null) continue;
          final data = selected.data();
          values.add(
            AgreementResult(
              id: '${data['roundId']}_${category.value}',
              roundId: data['roundId'] as String,
              outingId: data['outingId'] as String,
              crewId: data['crewId'] as String,
              category: category,
              selectedProposalId: selected.data()['proposalId'] as String,
              voteTotals: {
                for (final d in docs)
                  d.data()['proposalId'] as String:
                      d.data()['voteCount'] as int,
              },
              eligibleParticipantCount:
                  data['eligibleParticipantCount'] as int? ?? 0,
              participatingVoterCount:
                  data['participatingVoterCount'] as int? ?? 0,
              confirmedAt: readFirestoreTimestamp(data['createdAt'])!,
            ),
          );
        }
        return values;
      });
  Stream<List<AgreementVoteModel>> streamMyVotes(String roundId, String uid) {
    final ids = AgreementCategory.values
        .map((c) => '${roundId}_${c.value}_$uid')
        .toList();
    return firestore
        .collection('agreement_votes')
        .where(FieldPath.documentId, whereIn: ids)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => AgreementVoteModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Stream<AgreementCommandModel?> streamCommand(String id) => firestore
      .collection('agreement_commands')
      .doc(id)
      .snapshots()
      .map(
        (d) => d.exists ? AgreementCommandModel.fromMap(d.data()!, d.id) : null,
      );

  Future<Map<String, dynamic>> outingData(String outingId) async {
    final doc = await firestore.collection('outings').doc(outingId).get();
    if (!doc.exists) throw StateError('outing-not-found');
    return doc.data()!;
  }

  Future<void> respondToOuting(String outingId, String uid, String status) =>
      firestore
          .collection('outing_participants')
          .doc('${outingId}_$uid')
          .update({
            'attendanceStatus': status,
            'respondedAt': FieldValue.serverTimestamp(),
          });
  Future<void> castVote({
    required String roundId,
    required AgreementCategory category,
    required String proposalId,
    required String uid,
  }) async {
    final round = await firestore
        .collection('agreement_rounds')
        .doc(roundId)
        .get();
    if (!round.exists) throw StateError('round-not-found');
    final data = round.data()!;
    final ref = firestore
        .collection('agreement_votes')
        .doc('${roundId}_${category.value}_$uid');
    final existing = await ref.get();
    final now = FieldValue.serverTimestamp();
    if (existing.exists) {
      await ref.update({'proposalId': proposalId, 'updatedAt': now});
      return;
    }
    await ref.set({
      'roundId': roundId,
      'outingId': data['outingId'],
      'crewId': data['crewId'],
      'category': category.value,
      'proposalId': proposalId,
      'userId': uid,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> withdrawVote(
    String roundId,
    AgreementCategory category,
    String uid,
  ) => firestore
      .collection('agreement_votes')
      .doc('${roundId}_${category.value}_$uid')
      .delete();
  Future<String> createCommand({
    required String type,
    required String outingId,
    required String uid,
    required Map<String, Object?> payload,
  }) async {
    final outing = await outingData(outingId);
    final ref = firestore.collection('agreement_commands').doc();
    await ref.set({
      'type': type,
      'outingId': outingId,
      'crewId': outing['crewId'],
      'requestedByUserId': uid,
      'payload': payload,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
