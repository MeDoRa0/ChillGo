abstract interface class TrustedClock {
  bool get isEstablished;
  DateTime get now;
  Future<void> establish();
  Future<void> refresh();
  Future<void> dispose();
}
