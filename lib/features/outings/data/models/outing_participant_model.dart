import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/outing_participant.dart';

class OutingParticipantModel extends OutingParticipant {
  const OutingParticipantModel({
    required super.id,
    required super.outingId,
    required super.crewId,
    required super.userId,
    required super.username,
    required super.displayName,
    super.avatarUrl,
    required super.addedByUserId,
    required super.addedAt,
    required super.isCreatorParticipant,
  });

  factory OutingParticipantModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    final normalizedMap = Map<String, dynamic>.from(map);
    final addedAt = readFirestoreTimestamp(normalizedMap['addedAt']);
    if (addedAt != null) normalizedMap['addedAt'] = addedAt;
    final participant = OutingParticipant.fromMap(normalizedMap, docId);
    return OutingParticipantModel.fromEntity(participant);
  }

  factory OutingParticipantModel.fromEntity(OutingParticipant participant) {
    return OutingParticipantModel(
      id: participant.id,
      outingId: participant.outingId,
      crewId: participant.crewId,
      userId: participant.userId,
      username: participant.username,
      displayName: participant.displayName,
      avatarUrl: participant.avatarUrl,
      addedByUserId: participant.addedByUserId,
      addedAt: participant.addedAt,
      isCreatorParticipant: participant.isCreatorParticipant,
    );
  }
}
