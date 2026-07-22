import '../entities/outing.dart';
import '../entities/outing_participant.dart';
import '../entities/outing_status.dart';
import '../entities/attendance_status.dart';

class OutingDetail {
  final Outing outing;
  final List<OutingParticipant> participants;

  const OutingDetail({required this.outing, required this.participants});
}

abstract class OutingRepository {
  Stream<List<Outing>> streamCrewOutings(String crewId);
  Stream<OutingDetail?> streamOutingDetail(String outingId);

  Future<String> createOuting({
    required String crewId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required String locationText,
  });

  Future<void> updateOutingDetails({
    required String outingId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required String locationText,
  });

  Future<void> cancelOuting({
    required String outingId,
    required String cancelledReason,
  });

  /// Permanently removes an outing and its participant roster.
  Future<void> deleteOuting({required String outingId});

  Future<void> requestExpiryCleanup({required String outingId});

  Future<void> addParticipant({
    required String outingId,
    required String userId,
  });

  /// Adds the signed-in crew member to an outing they want to attend.
  Future<void> acceptOuting({required String outingId});

  Future<void> respondToOuting({
    required String outingId,
    required AttendanceStatus attendanceStatus,
  });

  Future<void> removeParticipant({
    required String outingId,
    required String userId,
  });

  Future<void> changeLifecycleStatus({
    required String outingId,
    required OutingStatus nextStatus,
  });
}
