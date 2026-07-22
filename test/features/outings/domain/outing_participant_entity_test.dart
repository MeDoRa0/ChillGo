import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/features/outings/domain/entities/outing_participant.dart';
import 'package:chillgo/features/outings/domain/entities/attendance_status.dart';

void main() {
  group('OutingParticipant', () {
    test('parses map values and serializes back to Firestore shape', () {
      final participant = OutingParticipant.fromMap({
        'outingId': 'outing-1',
        'crewId': 'crew-1',
        'userId': 'user-1',
        'username': 'bob',
        'displayName': 'Bob',
        'addedByUserId': 'user-1',
        'addedAt': '2026-01-01T10:00:00.000Z',
        'isCreatorParticipant': true,
      }, 'outing-1_user-1');

      expect(participant.id, 'outing-1_user-1');
      expect(participant.isCreatorParticipant, isTrue);
      expect(participant.attendanceStatus, AttendanceStatus.accepted);
      expect(participant.toMap()['username'], 'bob');
    });

    test(
      'legacy non-creator defaults to invited and supports response changes',
      () {
        final participant = OutingParticipant.fromMap({
          'outingId': 'outing-1',
          'crewId': 'crew-1',
          'userId': 'user-2',
          'username': 'sue',
          'displayName': 'Sue',
          'addedByUserId': 'user-1',
          'addedAt': '2026-01-01T10:00:00.000Z',
          'isCreatorParticipant': false,
        }, 'outing-1_user-2');
        expect(participant.attendanceStatus, AttendanceStatus.invited);
        final responded = participant.copyWith(
          attendanceStatus: AttendanceStatus.declined,
          respondedAt: DateTime.utc(2026, 1, 2),
        );
        expect(responded.attendanceStatus, AttendanceStatus.declined);
        expect(responded.respondedAt, isNotNull);
      },
    );

    test('copyWith updates selected values', () {
      final participant = OutingParticipant.fromMap({
        'outingId': 'outing-1',
        'crewId': 'crew-1',
        'userId': 'user-1',
        'username': 'bob',
        'displayName': 'Bob',
        'addedByUserId': 'user-1',
        'addedAt': '2026-01-01T10:00:00.000Z',
        'isCreatorParticipant': true,
      }, 'id');

      expect(participant.copyWith(displayName: 'Bobby').displayName, 'Bobby');
    });

    test('rejects missing required fields', () {
      expect(
        () => OutingParticipant.fromMap({
          'displayName': 'Bob',
          'addedAt': '2026-01-01T10:00:00.000Z',
        }, 'id'),
        throwsFormatException,
      );
    });
  });
}
