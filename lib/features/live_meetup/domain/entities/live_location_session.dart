import 'package:equatable/equatable.dart';

class LiveLocationSession extends Equatable {
  LiveLocationSession({
    required this.outingId,
    required this.sessionId,
    required this.sessionToken,
    required this.deviceSessionId,
  }) {
    for (final entry in {
      'outingId': outingId,
      'sessionId': sessionId,
      'sessionToken': sessionToken,
      'deviceSessionId': deviceSessionId,
    }.entries) {
      if (entry.value.trim().isEmpty) {
        throw ArgumentError.value(entry.value, entry.key, 'Must not be empty.');
      }
    }
  }

  final String outingId;
  final String sessionId;
  final String sessionToken;
  final String deviceSessionId;

  @override
  List<Object> get props => [
    outingId,
    sessionId,
    sessionToken,
    deviceSessionId,
  ];
}
