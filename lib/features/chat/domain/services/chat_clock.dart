abstract interface class ChatClock {
  DateTime get now;
  bool get isEstablished;
  Future<void> establish();
  Future<void> refresh();
  Future<void> dispose();
}

class FixedChatClock implements ChatClock {
  FixedChatClock(this.value);
  DateTime value;
  @override
  DateTime get now => value.toUtc();
  @override
  bool get isEstablished => true;
  @override
  Future<void> establish() async {}
  @override
  Future<void> refresh() async {}
  @override
  Future<void> dispose() async {}
}
