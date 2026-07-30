# Contract: Telemetry and Diagnostics Privacy

## Allowlisted journey signals

The app may emit only these aggregate completion events: `sign_in_completed`, `profile_setup_completed`, `crew_created_or_joined`, `outing_created`, `agreement_completed`, `meetup_coordination_completed`, and `notification_center_opened`. Parameters are limited to schema version, app release version, Android/iOS client type, and controlled outcome category.

## Unexpected failure reports

Reports include app release version, Android/iOS client type, controlled failure category, and sanitized diagnostic context. Provider failure is best effort; the app must not fabricate a success signal.

## Prohibited data

Analytics events, Crashlytics keys/logs, release evidence, and incident records must never include chat/message text, display names, crew/outing IDs, precise/live location, vote data, invitations, device/auth tokens, email, credentials, raw network bodies, or unsanitized free-form exceptions.

## Review

Before public submission and each stage advance, sample every schema/report type for usefulness, duplication, privacy risk, and MVP coverage. Disable unsafe collection before advancement and initiate the incident procedure if exposure is plausible.
