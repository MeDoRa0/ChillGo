import 'diagnostics_context.dart';

/// The only product events permitted to leave the app.
class ReleaseTelemetryEvent {
  const ReleaseTelemetryEvent._(this.name, this.context, this.outcome);

  static const allowedNames = <String>{
    'sign_in_completed',
    'profile_setup_completed',
    'crew_created_or_joined',
    'outing_created',
    'agreement_completed',
    'meetup_coordination_completed',
    'notification_center_opened',
  };

  final String name;
  final DiagnosticsContext context;
  final String outcome;

  static ReleaseTelemetryEvent create({
    required String name,
    required DiagnosticsContext context,
    String outcome = 'completed',
  }) {
    if (!allowedNames.contains(name)) {
      throw ArgumentError.value(name, 'name', 'Event is not allowlisted.');
    }
    if (!_isControlledValue(outcome)) {
      throw ArgumentError.value(
        outcome,
        'outcome',
        'Outcome must be controlled.',
      );
    }
    return ReleaseTelemetryEvent._(name, context, outcome);
  }

  Map<String, Object> toParameters() => {
    ...context.toSafeMap(),
    'outcome_category': outcome,
  };

  static bool _isControlledValue(String value) =>
      RegExp(r'^[a-z_]{1,40}$').hasMatch(value);
}
