import '../../domain/entities/outing.dart';

class OutingModel extends Outing {
  const OutingModel({
    required super.id,
    required super.crewId,
    required super.title,
    super.description,
    required super.scheduledAt,
    required super.locationText,
    required super.status,
    required super.createdByUserId,
    required super.createdAt,
    required super.updatedAt,
    super.cancelledReason,
    super.cancelledAt,
    super.archivedAt,
  });

  factory OutingModel.fromMap(Map<String, dynamic> map, String docId) {
    final outing = Outing.fromMap(map, docId);
    return OutingModel.fromEntity(outing);
  }

  factory OutingModel.fromEntity(Outing outing) {
    return OutingModel(
      id: outing.id,
      crewId: outing.crewId,
      title: outing.title,
      description: outing.description,
      scheduledAt: outing.scheduledAt,
      locationText: outing.locationText,
      status: outing.status,
      createdByUserId: outing.createdByUserId,
      createdAt: outing.createdAt,
      updatedAt: outing.updatedAt,
      cancelledReason: outing.cancelledReason,
      cancelledAt: outing.cancelledAt,
      archivedAt: outing.archivedAt,
    );
  }
}
