import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chillgo/features/welcome/data/repositories/welcome_onboarding_repository_impl.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockSharedPreferences sharedPreferences;

  setUp(() {
    sharedPreferences = MockSharedPreferences();
  });

  test('starts incomplete when no completion flag exists', () async {
    when(
      () => sharedPreferences.getBool('WELCOME_ONBOARDING_COMPLETE'),
    ).thenReturn(null);
    final repository = WelcomeOnboardingRepositoryImpl(
      sharedPreferences: sharedPreferences,
    );

    expect(repository.isComplete, isFalse);

    await repository.dispose();
  });

  test('persists completion and notifies routing listeners', () async {
    when(
      () => sharedPreferences.getBool('WELCOME_ONBOARDING_COMPLETE'),
    ).thenReturn(false);
    when(
      () => sharedPreferences.setBool('WELCOME_ONBOARDING_COMPLETE', true),
    ).thenAnswer((_) async => true);
    final repository = WelcomeOnboardingRepositoryImpl(
      sharedPreferences: sharedPreferences,
    );
    final completion = repository.completionChanges.first;

    await repository.complete();

    expect(repository.isComplete, isTrue);
    expect(await completion, isTrue);
    verify(
      () => sharedPreferences.setBool('WELCOME_ONBOARDING_COMPLETE', true),
    ).called(1);
    await repository.dispose();
  });
}
