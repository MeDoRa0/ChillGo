import 'package:chillgo/features/chat/domain/services/chat_access_policy.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = ChatAccessPolicy();

  test('active lifecycle is writable for eligible users', () {
    for (final status in OutingStatus.values.where((s) => s.isEditable)) {
      expect(
        policy.evaluate(
          status: status,
          isCrewMember: true,
          isParticipant: true,
        ),
        ChatAccess.writable,
      );
    }
  });

  test('terminal lifecycle is read only', () {
    for (final status in OutingStatus.values.where((s) => s.isHistorical)) {
      expect(
        policy.evaluate(
          status: status,
          isCrewMember: true,
          isParticipant: true,
        ),
        ChatAccess.readOnly,
      );
    }
  });

  test(
    'membership, participation, and deletion independently revoke access',
    () {
      expect(
        policy.evaluate(
          status: OutingStatus.draft,
          isCrewMember: false,
          isParticipant: true,
        ),
        ChatAccess.inaccessible,
      );
      expect(
        policy.evaluate(
          status: OutingStatus.draft,
          isCrewMember: true,
          isParticipant: false,
        ),
        ChatAccess.inaccessible,
      );
      expect(
        policy.evaluate(
          status: OutingStatus.draft,
          isCrewMember: true,
          isParticipant: true,
          deletionPending: true,
        ),
        ChatAccess.inaccessible,
      );
    },
  );
}
