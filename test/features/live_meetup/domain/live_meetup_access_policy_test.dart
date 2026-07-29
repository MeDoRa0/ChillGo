import 'package:chillgo/features/live_meetup/domain/services/live_meetup_access_policy.dart';
import 'package:chillgo/features/outings/domain/entities/attendance_status.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = LiveMeetupAccessPolicy();

  test('participant access requires Meeting, membership, and Accepted', () {
    expect(
      policy.participantAccess(
        outingStatus: OutingStatus.meeting,
        attendanceStatus: AttendanceStatus.accepted,
        isCrewMember: true,
        isParticipant: true,
      ),
      LiveMeetupAccess.allowed,
    );
    for (final status in OutingStatus.values.where(
      (s) => s != OutingStatus.meeting,
    )) {
      expect(
        policy.participantAccess(
          outingStatus: status,
          attendanceStatus: AttendanceStatus.accepted,
          isCrewMember: true,
          isParticipant: true,
        ),
        LiveMeetupAccess.denied,
      );
    }
  });

  test('pending cleanup or deletion always denies participant access', () {
    for (final flags in [(true, false), (false, true)]) {
      expect(
        policy.participantAccess(
          outingStatus: OutingStatus.meeting,
          attendanceStatus: AttendanceStatus.accepted,
          isCrewMember: true,
          isParticipant: true,
          cleanupPending: flags.$1,
          deletionPending: flags.$2,
        ),
        LiveMeetupAccess.denied,
      );
    }
  });

  test('current creator or owner may prepare in Confirmed or Meeting', () {
    expect(
      policy.canPrepareMeetupPoint(
        outingStatus: OutingStatus.confirmed,
        isCrewMember: true,
        isCreator: true,
        isCrewOwner: false,
      ),
      isTrue,
    );
    expect(
      policy.canPrepareMeetupPoint(
        outingStatus: OutingStatus.meeting,
        isCrewMember: true,
        isCreator: false,
        isCrewOwner: true,
      ),
      isTrue,
    );
    expect(
      policy.canPrepareMeetupPoint(
        outingStatus: OutingStatus.confirmed,
        isCrewMember: false,
        isCreator: true,
        isCrewOwner: false,
      ),
      isFalse,
    );
  });
}
