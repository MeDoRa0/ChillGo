import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:chillgo/core/data/repositories/diagnostics_repository_impl.dart';
import 'package:chillgo/core/data/repositories/release_metadata_repository_impl.dart';

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  late DiagnosticsRepositoryImpl repository;
  late MockFirebaseCrashlytics mockCrashlytics;
  late MockFirebaseAnalytics mockAnalytics;

  setUp(() {
    mockCrashlytics = MockFirebaseCrashlytics();
    mockAnalytics = MockFirebaseAnalytics();
    repository = DiagnosticsRepositoryImpl(
      crashlytics: mockCrashlytics,
      analytics: mockAnalytics,
      releaseMetadata: ReleaseMetadataRepositoryImpl(
        releaseVersion: '1.0.0+1',
        platform: TargetPlatform.android,
      ),
    );
  });

  test('should record error in Crashlytics and save log locally', () async {
    final exception = Exception('test');
    const stack = StackTrace.empty;

    when(
      () => mockCrashlytics.recordError(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockCrashlytics.setCustomKey(any(), any()),
    ).thenAnswer((_) async {});

    await repository.logException(exception, stack);

    verify(
      () => mockCrashlytics.recordError(
        any(that: isA<StateError>()),
        null,
        reason: 'unexpected_failure',
      ),
    ).called(1);
    final logs = await repository.getLocalLogs();
    expect(logs.length, 1);
    expect(logs.first.errorMessage, 'unexpected_failure');
  });

  test(
    'should save log locally when remote diagnostics are unavailable',
    () async {
      final localOnlyRepository = DiagnosticsRepositoryImpl();
      final exception = Exception('desktop startup');

      await localOnlyRepository.logException(exception, StackTrace.empty);

      final logs = await localOnlyRepository.getLocalLogs();
      expect(logs.length, 1);
      expect(logs.first.errorMessage, 'unexpected_failure');
    },
  );

  test('submits only allowlisted aggregate journey events', () async {
    when(
      () => mockAnalytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});

    await repository.logEvent('sign_in_completed', const {
      'outcome_category': 'completed',
    });

    verify(
      () => mockAnalytics.logEvent(
        name: 'sign_in_completed',
        parameters: {
          'release_version': '1.0.0+1',
          'client_type': 'android',
          'failure_category': 'journey_completed',
          'outcome_category': 'completed',
        },
      ),
    ).called(1);
  });

  test(
    'drops a non-allowlisted event without forwarding private fields',
    () async {
      await repository.logEvent('chat_message_sent', {'message': 'private'});
      verifyNever(
        () => mockAnalytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      );
    },
  );
}
