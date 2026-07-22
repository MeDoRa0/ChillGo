import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/agreement_round.dart';

class AgreementRoundModel extends AgreementRound {
  const AgreementRoundModel({
    required super.id,
    required super.outingId,
    required super.crewId,
    required super.sequence,
    required super.status,
    required super.createdByUserId,
    required super.createdAt,
    super.closedAt,
    super.supersededByRoundId,
    super.reopenReason,
    super.seedTimeProposalId,
    super.seedLocationProposalId,
    super.confirmedByUserId,
    super.confirmedAt,
    super.selectedTimeProposalId,
    super.selectedLocationProposalId,
    super.eligibleVoterCount,
    super.timeVoteCount,
    super.locationVoteCount,
  });

  factory AgreementRoundModel.fromMap(Map<String, dynamic> map, String id) =>
      AgreementRoundModel(
        id: id,
        outingId: map['outingId'] as String,
        crewId: map['crewId'] as String,
        sequence: map['sequence'] as int,
        status: AgreementRoundStatus.fromValue(map['status'] as String),
        createdByUserId:
            (map['openedByUserId'] ?? map['createdByUserId']) as String,
        createdAt: readFirestoreTimestamp(map['openedAt'] ?? map['createdAt'])!,
        closedAt: readFirestoreTimestamp(map['closedAt']),
        supersededByRoundId: map['supersededByRoundId'] as String?,
        reopenReason: map['reopenReason'] as String?,
        seedTimeProposalId: map['seedTimeProposalId'] as String?,
        seedLocationProposalId: map['seedLocationProposalId'] as String?,
        confirmedByUserId: map['confirmedByUserId'] as String?,
        confirmedAt: readFirestoreTimestamp(map['confirmedAt']),
        selectedTimeProposalId: map['selectedTimeProposalId'] as String?,
        selectedLocationProposalId:
            map['selectedLocationProposalId'] as String?,
        eligibleVoterCount: map['eligibleVoterCount'] as int?,
        timeVoteCount: map['timeVoteCount'] as int?,
        locationVoteCount: map['locationVoteCount'] as int?,
      );

  Map<String, dynamic> toMap() => {
    'outingId': outingId,
    'crewId': crewId,
    'sequence': sequence,
    'status': status.value,
    'openedByUserId': createdByUserId,
    'openedAt': writeFirestoreTimestamp(createdAt),
    if (closedAt != null) 'closedAt': writeFirestoreTimestamp(closedAt!),
    if (supersededByRoundId != null) 'supersededByRoundId': supersededByRoundId,
    if (reopenReason != null) 'reopenReason': reopenReason,
    if (seedTimeProposalId != null) 'seedTimeProposalId': seedTimeProposalId,
    if (seedLocationProposalId != null)
      'seedLocationProposalId': seedLocationProposalId,
    if (confirmedByUserId != null) 'confirmedByUserId': confirmedByUserId,
    if (confirmedAt != null)
      'confirmedAt': writeFirestoreTimestamp(confirmedAt!),
    if (selectedTimeProposalId != null)
      'selectedTimeProposalId': selectedTimeProposalId,
    if (selectedLocationProposalId != null)
      'selectedLocationProposalId': selectedLocationProposalId,
    if (eligibleVoterCount != null) 'eligibleVoterCount': eligibleVoterCount,
    if (timeVoteCount != null) 'timeVoteCount': timeVoteCount,
    if (locationVoteCount != null) 'locationVoteCount': locationVoteCount,
  };
}
