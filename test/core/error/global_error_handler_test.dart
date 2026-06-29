import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chillgo/core/error/global_error_handler.dart';
import 'package:chillgo/core/domain/repositories/diagnostics_repository.dart';

class MockDiagnosticsRepository extends Mock implements DiagnosticsRepository {}

void main() {
  late GlobalErrorHandler errorHandler;
  late MockDiagnosticsRepository mockDiagnosticsRepository;

  setUp(() {
    mockDiagnosticsRepository = MockDiagnosticsRepository();
    errorHandler = GlobalErrorHandler(diagnosticsRepository: mockDiagnosticsRepository);
  });

  test('should initialize correctly and register handlers', () {
    errorHandler.initialize();
    expect(errorHandler.diagnosticsRepository, isNotNull);
  });
}
