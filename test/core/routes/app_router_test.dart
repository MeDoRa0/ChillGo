import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/core/routes/app_router.dart';

void main() {
  test('AppRouter configuration should be initialized', () {
    expect(appRouter, isNotNull);
    expect(appRouter.configuration.routes.length, greaterThanOrEqualTo(2));
  });
}
