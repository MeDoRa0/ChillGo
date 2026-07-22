import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/features/outings/data/models/outing_participant_model.dart';
import 'package:chillgo/features/outings/domain/entities/attendance_status.dart';

void main() {
  test('OutingParticipantModel maps Firestore data', () {
    final model = OutingParticipantModel.fromMap({
      'outingId': 'outing-1',
      'crewId': 'crew-1',
      'userId': 'user-1',
      'username': 'bob',
      'displayName': 'Bob',
      'addedByUserId': 'user-1',
      'addedAt': '2026-01-01T10:00:00.000Z',
      'isCreatorParticipant': true,
      'attendanceStatus': 'accepted',
      'respondedAt': '2026-01-01T10:30:00.000Z',
    }, 'outing-1_user-1');

    expect(model.id, 'outing-1_user-1');
    expect(model.toMap()['isCreatorParticipant'], isTrue);
    expect(model.attendanceStatus, AttendanceStatus.accepted);
    expect(model.respondedAt, DateTime.utc(2026, 1, 1, 10, 30));
  });
}
