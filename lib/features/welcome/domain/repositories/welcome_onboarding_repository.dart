abstract interface class WelcomeOnboardingRepository {
  bool get isComplete;

  Stream<bool> get completionChanges;

  Future<void> complete();

  Future<void> dispose();
}
