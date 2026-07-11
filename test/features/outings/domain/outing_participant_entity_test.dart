import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/features/outings/domain/entities/outing_participant.dart';

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
      expect(participant.toMap()['username'], 'bob');
    });

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
