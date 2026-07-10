import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/features/outings/data/models/outing_model.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';

void main() {
  test('OutingModel maps Firestore data', () {
    final model = OutingModel.fromMap({
      'crewId': 'crew-1',
      'title': 'Friday Cafe',
      'scheduledAt': '2030-01-01T10:00:00.000Z',
      'locationText': 'City Center Cafe',
      'status': 'draft',
      'createdByUserId': 'user-1',
      'createdAt': '2026-01-01T10:00:00.000Z',
      'updatedAt': '2026-01-01T10:00:00.000Z',
    }, 'outing-1');

    expect(model.id, 'outing-1');
    expect(model.status, OutingStatus.draft);
    expect(model.toMap()['crewId'], 'crew-1');
  });
}
