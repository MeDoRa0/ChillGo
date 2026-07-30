import 'package:equatable/equatable.dart';

class OutingReviewNotification extends Equatable {
  const OutingReviewNotification({
    required this.id,
    required this.recipientUserId,
    required this.crewId,
    required this.outingId,
    required this.creatorDisplayName,
    required this.outingTitle,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String recipientUserId;
  final String crewId;
  final String outingId;
  final String creatorDisplayName;
  final String outingTitle;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  @override
  List<Object?> get props => [
    id,
    recipientUserId,
    crewId,
    outingId,
    creatorDisplayName,
    outingTitle,
    createdAt,
    readAt,
  ];
}
