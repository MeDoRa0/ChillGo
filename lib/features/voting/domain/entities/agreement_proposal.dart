import 'agreement_category.dart';

class AgreementProposal {
  const AgreementProposal({
    required this.id,
    required this.roundId,
    required this.outingId,
    required this.crewId,
    required this.category,
    required this.createdByUserId,
    required this.authorDisplayName,
    required this.normalizedValue,
    required this.createdAt,
    this.timeValue,
    this.locationText,
  });
  final String id,
      roundId,
      outingId,
      crewId,
      createdByUserId,
      authorDisplayName,
      normalizedValue;
  final AgreementCategory category;
  final DateTime createdAt;
  final DateTime? timeValue;
  final String? locationText;
  bool isExpiredAt(DateTime now) =>
      category == AgreementCategory.time &&
      (timeValue == null || !timeValue!.isAfter(now.toUtc()));
  bool isEligibleAt(DateTime now) => !isExpiredAt(now);
}
