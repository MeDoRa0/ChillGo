/// Controlled failure source for integration tests that verify recovery UI.
class NetworkConditionController {
  bool _isInterrupted = false;

  void interrupt() => _isInterrupted = true;

  void restore() => _isInterrupted = false;

  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_isInterrupted) throw const RecoverableNetworkInterruption();
    return operation();
  }
}

class RecoverableNetworkInterruption implements Exception {
  const RecoverableNetworkInterruption();
}
