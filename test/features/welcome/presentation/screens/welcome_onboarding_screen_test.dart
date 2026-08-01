import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chillgo/core/presentation/theme/chillgo_theme.dart';
import 'package:chillgo/features/welcome/domain/repositories/welcome_onboarding_repository.dart';
import 'package:chillgo/features/welcome/presentation/screens/welcome_onboarding_screen.dart';

class FakeWelcomeOnboardingRepository implements WelcomeOnboardingRepository {
  final StreamController<bool> _completionController =
      StreamController<bool>.broadcast();

  @override
  bool isComplete = false;

  @override
  Stream<bool> get completionChanges => _completionController.stream;

  @override
  Future<void> complete() async {
    isComplete = true;
    _completionController.add(true);
  }

  @override
  Future<void> dispose() => _completionController.close();
}

void main() {
  late FakeWelcomeOnboardingRepository welcomeRepository;

  setUp(() {
    welcomeRepository = FakeWelcomeOnboardingRepository();
  });

  tearDown(() async {
    await welcomeRepository.dispose();
  });

  testWidgets('moves through all three onboarding pages and completes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ChillGoTheme.sunshine,
        home: WelcomeOnboardingScreen(welcomeRepository: welcomeRepository),
      ),
    );

    expect(find.text('Bring your people together'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.text('One crew. One clear plan.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.text('Know when everyone’s close'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Get started'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Get started'));
    await tester.pump();
    expect(welcomeRepository.isComplete, isTrue);
  });

  testWidgets('skip completes onboarding from the first page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ChillGoTheme.sunshine,
        home: WelcomeOnboardingScreen(welcomeRepository: welcomeRepository),
      ),
    );

    await tester.tap(find.widgetWithText(TextButton, 'Skip'));
    await tester.pump();

    expect(welcomeRepository.isComplete, isTrue);
  });

  testWidgets('all pages fit a compact phone viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ChillGoTheme.sunshine,
        home: WelcomeOnboardingScreen(welcomeRepository: welcomeRepository),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
