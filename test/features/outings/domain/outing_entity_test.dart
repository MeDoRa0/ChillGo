import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/features/outings/domain/entities/outing.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';

void main() {
  group('Outing', () {
    test('parses map values and serializes back to Firestore shape', () {
      final outing = Outing.fromMap({
        'crewId': 'crew-1',
        'title': 'Friday Cafe',
        'description': 'Coffee',
        'scheduledAt': '2030-01-01T10:00:00.000Z',
        'locationText': 'City Center Cafe',
        'status': 'planning',
        'createdByUserId': 'user-1',
        'createdAt': '2026-01-01T10:00:00.000Z',
        'updatedAt': '2026-01-01T10:05:00.000Z',
      }, 'outing-1');

      expect(outing.id, 'outing-1');
      expect(outing.status, OutingStatus.planning);
      expect(outing.toMap()['locationText'], 'City Center Cafe');
    });

    test('copyWith updates selected values', () {
      final outing = Outing.fromMap({
        'crewId': 'crew-1',
        'title': 'Friday Cafe',
        'scheduledAt': '2030-01-01T10:00:00.000Z',
        'locationText': 'City Center Cafe',
        'status': 'draft',
        'createdByUserId': 'user-1',
        'createdAt': '2026-01-01T10:00:00.000Z',
        'updatedAt': '2026-01-01T10:00:00.000Z',
      }, 'outing-1');

      final updated = outing.copyWith(title: 'Saturday Cafe');

      expect(updated.title, 'Saturday Cafe');
      expect(updated.id, outing.id);
    });

    test('rejects missing required fields', () {
      expect(
        () => Outing.fromMap({
          'title': 'Friday Cafe',
          'scheduledAt': '2030-01-01T10:00:00.000Z',
          'status': 'draft',
        }, 'outing-1'),
        throwsFormatException,
      );
    });
  });
}
