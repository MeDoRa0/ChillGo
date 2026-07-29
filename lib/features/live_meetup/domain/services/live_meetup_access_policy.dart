import '../../../outings/domain/entities/attendance_status.dart';
import '../../../outings/domain/entities/outing_status.dart';

enum LiveMeetupAccess { denied, allowed }

class LiveMeetupAccessPolicy {
  const LiveMeetupAccessPolicy();

  LiveMeetupAccess participantAccess({
    required OutingStatus outingStatus,
    required AttendanceStatus attendanceStatus,
    required bool isCrewMember,
    required bool isParticipant,
    bool cleanupPending = false,
    bool deletionPending = false,
  }) {
    final allowed =
        outingStatus == OutingStatus.meeting &&
        attendanceStatus == AttendanceStatus.accepted &&
        isCrewMember &&
        isParticipant &&
        !cleanupPending &&
        !deletionPending;
    return allowed ? LiveMeetupAccess.allowed : LiveMeetupAccess.denied;
  }

  bool canPrepareMeetupPoint({
    required OutingStatus outingStatus,
    required bool isCrewMember,
    required bool isCreator,
    required bool isCrewOwner,
    bool cleanupPending = false,
    bool deletionPending = false,
  }) =>
      isCrewMember &&
      (isCreator || isCrewOwner) &&
      (outingStatus == OutingStatus.confirmed ||
          outingStatus == OutingStatus.meeting) &&
      !cleanupPending &&
      !deletionPending;
}
