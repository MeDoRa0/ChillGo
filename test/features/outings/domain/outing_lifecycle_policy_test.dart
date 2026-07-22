import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';
import 'package:chillgo/features/outings/domain/services/outing_lifecycle_policy.dart';

void main() {
  group('OutingLifecyclePolicy', () {
    final policy = OutingLifecyclePolicy();

    test('allows configured lifecycle transitions', () {
      expect(
        policy.canTransition(OutingStatus.draft, OutingStatus.planning),
        isFalse,
      );
      expect(
        policy.canTransition(OutingStatus.draft, OutingStatus.cancelled),
        isTrue,
      );
      expect(
        policy.canTransition(OutingStatus.planning, OutingStatus.confirmed),
        isFalse,
      );
      expect(
        policy.canTransition(OutingStatus.planning, OutingStatus.cancelled),
        isTrue,
      );
      expect(
        policy.canTransition(OutingStatus.confirmed, OutingStatus.meeting),
        isTrue,
      );
      expect(
        policy.canTransition(OutingStatus.confirmed, OutingStatus.cancelled),
        isTrue,
      );
      expect(
        policy.canTransition(OutingStatus.meeting, OutingStatus.completed),
        isTrue,
      );
      expect(
        policy.canTransition(OutingStatus.completed, OutingStatus.archived),
        isTrue,
      );
    });

    test('attendance responses stop at meeting', () {
      expect(policy.canRespondToAttendance(OutingStatus.draft), isTrue);
      expect(policy.canRespondToAttendance(OutingStatus.planning), isTrue);
      expect(policy.canRespondToAttendance(OutingStatus.confirmed), isTrue);
      expect(policy.canRespondToAttendance(OutingStatus.meeting), isFalse);
      expect(policy.canRespondToAttendance(OutingStatus.completed), isFalse);
    });

    test('rejects invalid transitions', () {
      expect(
        policy.canTransition(OutingStatus.meeting, OutingStatus.cancelled),
        isFalse,
      );
      expect(
        policy.canTransition(OutingStatus.cancelled, OutingStatus.archived),
        isFalse,
      );
      expect(
        policy.canTransition(OutingStatus.archived, OutingStatus.draft),
        isFalse,
      );
    });

    test('parses stable Firestore status values', () {
      expect(OutingStatus.fromValue('confirmed'), OutingStatus.confirmed);
      expect(() => OutingStatus.fromValue('unknown'), throwsFormatException);
      expect(() => OutingStatus.fromValue(null), throwsFormatException);
    });
  });
}
