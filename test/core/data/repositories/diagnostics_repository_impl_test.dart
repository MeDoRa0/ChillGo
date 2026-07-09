import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:chillgo/core/data/repositories/diagnostics_repository_impl.dart';

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
    );
  });

  test('should record error in Crashlytics and save log locally', () async {
    final exception = Exception('test');
    const stack = StackTrace.empty;

    when(
      () => mockCrashlytics.recordError(any(), any()),
    ).thenAnswer((_) async {});

    await repository.logException(exception, stack);

    verify(() => mockCrashlytics.recordError(exception, stack)).called(1);
    final logs = await repository.getLocalLogs();
    expect(logs.length, 1);
    expect(logs.first.errorMessage, exception.toString());
  });

  test(
    'should save log locally when remote diagnostics are unavailable',
    () async {
      final localOnlyRepository = DiagnosticsRepositoryImpl();
      final exception = Exception('desktop startup');

      await localOnlyRepository.logException(exception, StackTrace.empty);

      final logs = await localOnlyRepository.getLocalLogs();
      expect(logs.length, 1);
      expect(logs.first.errorMessage, exception.toString());
    },
  );
}
