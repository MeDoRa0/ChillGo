import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/agreement_category.dart';
import '../../domain/entities/agreement_proposal.dart';

class AgreementProposalModel extends AgreementProposal {
  const AgreementProposalModel({
    required super.id,
    required super.roundId,
    required super.outingId,
    required super.crewId,
    required super.category,
    required super.createdByUserId,
    required super.authorDisplayName,
    required super.normalizedValue,
    required super.createdAt,
    super.timeValue,
    super.locationText,
  });
  factory AgreementProposalModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) => AgreementProposalModel(
    id: id,
    roundId: map['roundId'] as String,
    outingId: map['outingId'] as String,
    crewId: map['crewId'] as String,
    category: AgreementCategory.fromValue(map['category'] as String),
    createdByUserId: (map['authorUserId'] ?? map['createdByUserId']) as String,
    authorDisplayName: (map['authorDisplayName'] ?? '') as String,
    normalizedValue: (map['normalizedKey'] ?? map['normalizedValue']) as String,
    createdAt: readFirestoreTimestamp(map['createdAt'])!,
    timeValue: readFirestoreTimestamp(map['timeValue']),
    locationText: map['locationText'] as String?,
  );
  Map<String, dynamic> toMap() => {
    'roundId': roundId,
    'outingId': outingId,
    'crewId': crewId,
    'category': category.value,
    'authorUserId': createdByUserId,
    'authorDisplayName': authorDisplayName,
    'normalizedKey': normalizedValue,
    'createdAt': writeFirestoreTimestamp(createdAt),
    if (timeValue != null) 'timeValue': writeFirestoreTimestamp(timeValue!),
    if (locationText != null) 'locationText': locationText,
  };
}
