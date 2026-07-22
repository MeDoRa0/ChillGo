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

    test('identifies outdated and current crew-plan boundaries', () {
      final now = DateTime.utc(2030, 1, 1, 10);
      final outing = Outing.fromMap({
        'crewId': 'crew-1',
        'title': 'Friday Cafe',
        'scheduledAt': now.toIso8601String(),
        'locationText': 'City Center Cafe',
        'status': 'draft',
        'createdByUserId': 'user-1',
        'createdAt': '2026-01-01T10:00:00.000Z',
        'updatedAt': '2026-01-01T10:00:00.000Z',
      }, 'outing-1');

      final outdatedOuting = outing.copyWith(
        scheduledAt: now.subtract(const Duration(seconds: 1)),
      );
      final futureOuting = outing.copyWith(
        scheduledAt: now.add(const Duration(seconds: 1)),
      );

      expect(outdatedOuting.isOutdatedAt(now), isTrue);
      expect(outdatedOuting.isCurrentCrewPlanAt(now), isFalse);
      expect(outing.isOutdatedAt(now), isFalse);
      expect(outing.isCurrentCrewPlanAt(now), isTrue);
      expect(futureOuting.isOutdatedAt(now), isFalse);
      expect(futureOuting.isCurrentCrewPlanAt(now), isTrue);
      expect(
        outing
            .copyWith(status: OutingStatus.completed)
            .isCurrentCrewPlanAt(now),
        isFalse,
      );
    });

    test('becomes cleanup eligible exactly twelve hours after schedule', () {
      final scheduledAt = DateTime.utc(2030, 1, 1, 10);
      final outing = Outing.fromMap({
        'crewId': 'crew-1',
        'title': 'Friday Cafe',
        'scheduledAt': scheduledAt.toIso8601String(),
        'locationText': 'City Center Cafe',
        'status': 'draft',
        'createdByUserId': 'user-1',
        'createdAt': '2026-01-01T10:00:00.000Z',
        'updatedAt': '2026-01-01T10:00:00.000Z',
      }, 'outing-1');

      expect(
        outing.isCleanupEligibleAt(
          scheduledAt
              .add(outingCleanupDelay)
              .subtract(const Duration(milliseconds: 1)),
        ),
        isFalse,
      );
      expect(
        outing.isCleanupEligibleAt(scheduledAt.add(outingCleanupDelay)),
        isTrue,
      );
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
