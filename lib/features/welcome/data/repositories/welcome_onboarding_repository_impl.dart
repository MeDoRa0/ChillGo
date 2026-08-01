import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/welcome_onboarding_repository.dart';

class WelcomeOnboardingRepositoryImpl implements WelcomeOnboardingRepository {
  WelcomeOnboardingRepositoryImpl({required this.sharedPreferences})
    : _isComplete = sharedPreferences.getBool(_completionKey) ?? false;

  static const _completionKey = 'WELCOME_ONBOARDING_COMPLETE';

  final SharedPreferences sharedPreferences;
  final StreamController<bool> _completionController =
      StreamController<bool>.broadcast();

  bool _isComplete;

  @override
  bool get isComplete => _isComplete;

  @override
  Stream<bool> get completionChanges => _completionController.stream;

  @override
  Future<void> complete() async {
    if (_isComplete) return;

    await sharedPreferences.setBool(_completionKey, true);
    _isComplete = true;
    _completionController.add(true);
  }

  @override
  Future<void> dispose() => _completionController.close();
}
