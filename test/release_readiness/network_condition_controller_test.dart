import '../../integration_test/support/network_condition_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fails an interrupted operation with a recoverable error', () async {
    final controller = NetworkConditionController()..interrupt();

    await expectLater(
      controller.execute(() async => 'completed'),
      throwsA(isA<RecoverableNetworkInterruption>()),
    );
  });

  test('executes the operation after connectivity is restored', () async {
    final controller = NetworkConditionController()
      ..interrupt()
      ..restore();

    expect(await controller.execute(() async => 'completed'), 'completed');
  });
}
