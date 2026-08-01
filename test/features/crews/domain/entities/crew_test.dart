import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes only the persisted crew fields', () {
    const crew = Crew(id: 'crew1', name: 'Weekend Hikers', ownerId: 'alice');

    expect(crew.toMap(), {'name': 'Weekend Hikers', 'ownerId': 'alice'});
    expect(crew.toMap(), isNot(contains('createdAt')));
  });

  test('reads crew documents without a creation timestamp', () {
    final crew = Crew.fromMap({
      'name': 'Weekend Hikers',
      'ownerId': 'alice',
    }, 'crew1');

    expect(crew.id, 'crew1');
    expect(crew.name, 'Weekend Hikers');
    expect(crew.ownerId, 'alice');
  });
}
