import 'package:chillgo/core/presentation/theme/chillgo_theme.dart';
import 'package:chillgo/features/authentication/presentation/screens/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shows Apple sign-in on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(_testApp());

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(
        find.text('Good company. Easy meetups.\nBetter days.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsNothing);
      expect(find.text('CG', findRichText: true), findsNothing);
      expect(find.byIcon(Icons.explore_rounded), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('hides Apple sign-in outside iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(_testApp());

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

Widget _testApp() {
  return MaterialApp(theme: ChillGoTheme.sunshine, home: const LoginScreen());
}
