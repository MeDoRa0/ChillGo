import 'package:chillgo/features/voting/data/models/agreement_command_model.dart';
import 'package:chillgo/features/voting/domain/entities/agreement_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a scrubbed terminal command without requiring its payload', () {
    final command = AgreementCommandModel.fromMap({
      'type': 'open_round',
      'status': 'succeeded',
      'outingId': 'outing',
      'crewId': 'crew',
      'requestedByUserId': 'user',
      'createdAt': DateTime.utc(2026, 7, 30),
      'result': {'roundId': 'round'},
    }, 'command');

    expect(command.status, AgreementCommandStatus.succeeded);
    expect(command.payload, isEmpty);
    expect(command.result, {'roundId': 'round'});
  });
}
