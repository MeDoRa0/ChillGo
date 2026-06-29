import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/core/data/models/diagnostics_log_model.dart';

void main() {
  final tModel = DiagnosticsLogModel(
    id: '123',
    errorMessage: 'Test error',
    stackTrace: 'Stack trace',
    severity: 'error',
    timestamp: DateTime.parse('2026-06-29T00:00:00.000Z'),
    deviceMetadata: const {'osVersion': 'Android'},
  );

  test('fromJson should return a valid model', () {
    final Map<String, dynamic> jsonMap = {
      'id': '123',
      'errorMessage': 'Test error',
      'stackTrace': 'Stack trace',
      'severity': 'error',
      'timestamp': '2026-06-29T00:00:00.000Z',
      'deviceMetadata': {'osVersion': 'Android'},
    };
    final result = DiagnosticsLogModel.fromJson(jsonMap);
    expect(result.id, tModel.id);
  });

  test('toJson should return a JSON map containing proper data', () {
    final result = tModel.toJson();
    expect(result['id'], '123');
  });
}
