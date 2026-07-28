# Research: Live Meetup

This document records Phase 0 decisions for Phase 6 on Android and iOS.

## Decision 1: Use Firestore Commands for Trusted, Online-Only Acceptance

**Decision**: Create each operation in `live_meetup_commands` inside a client Firestore transaction that first reads the outing. A v2 Firestore-created Function validates and applies it. Commands cover status changes, start/transfer/stop sharing, location publication, and meetup-point changes.

**Rationale**: Firestore transactions fail offline and do not enqueue writes, matching manual-retry behavior. The repository already uses this transport for Agreement and Chat. Firestore triggers are at-least-once and unordered, so every operation carries a trusted `createdAt == request.time` ordering key and handlers are idempotent. Sources: [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions) and [Firestore trigger delivery](https://firebase.google.com/docs/functions/firestore-events).

**Alternatives considered**:

- Normal direct Firestore writes: rejected because offline-capable clients can queue them and because cross-document stop/transfer races need trusted serialization.
- Callable Functions: rejected to preserve the repository's existing
  requester-private Firestore command transport and avoid a second mutation
  channel.
- Custom authenticated HTTP Functions: viable, but rejected because it duplicates authentication/CORS/emulator plumbing already solved by the project's command pattern.

## Decision 2: Order Commands by Trusted Creation Tuple

**Decision**: Treat `(createdAt, commandId)` as the operation ordering tuple. Security Rules require `createdAt == request.time`. Trusted transactions compare the tuple with the affected entity's last applied tuple and return older commands as safe `superseded` outcomes.

**Rationale**: Trigger invocation order is not guaranteed. Processing time alone would allow an older status or point to overwrite a newer user action. Firestore request time is server-controlled and available before asynchronous processing; the document ID breaks timestamp ties.

**Alternatives considered**:

- Trigger processing time: rejected because delayed old events could win.
- Device timestamp: rejected because device clocks may be wrong or manipulated.
- Assume trigger order: rejected by the documented at-least-once, unordered delivery model.

## Decision 3: Keep One Current Status and One Current Location

**Decision**: Use deterministic documents `live_meetup_statuses/{outingId}_{userId}` and `live_locations/{outingId}_{userId}`. A newer accepted update replaces the document; no historical collection is created. The attendee summary joins these records with the existing outing participant roster.

**Rationale**: This directly enforces no public history and prevents duplicate markers. Deterministic paths make idempotency, cleanup, and Security Rules predictable.

**Alternatives considered**:

- Append-only events: rejected because they preserve status and route history.
- Arrays on the outing: rejected because of contention, document growth, and coarse authorization.
- Subcollections: viable, but rejected to match the repository's top-level ownership and deletion-sweep convention.

## Decision 4: Use Ephemeral Session Secrets and a Trusted Share Watermark

**Decision**: Starting creates a high-entropy secret held only in the active Flutter process. Trusted code stores its SHA-256 hash in `live_meetup_shares/{outingId}_{userId}` with an active session ID and last control tuple. Location and stop commands must prove the session secret. Transfer requires an explicit `transferExisting` command, atomically replaces the hash/session, deletes the current point, and invalidates the old device. Command listing is denied; only exact known requester command gets are allowed, and payloads are scrubbed on terminal processing.

**Rationale**: A plain device ID is forgeable and a readable session token would be exposed to every signed-in device for the same user. A process-memory secret naturally ends client capability when the app closes. The trusted control watermark prevents an older start event from reversing a later stop. The new process has no secret and must explicitly start/transfer again.

**Alternatives considered**:

- Persist the secret in SharedPreferences: rejected because reopening would silently restart consent.
- Store a readable token in the share document: rejected because Firestore Rules cannot hide individual fields in an otherwise readable document.
- Device ID alone: rejected because it is not an authorization capability and does not solve concurrent transfer races.

## Decision 5: Pause the Location Stream on Every Non-Resumed Lifecycle State

**Decision**: A process-scoped sharing coordinator owns `AppLifecycleListener`. It subscribes to `geolocator` only while the app is `resumed`, cancels on `inactive`, `hidden`, `paused`, or `detached`, and may recreate the stream on `resumed` only when the same in-memory session secret still exists. It never configures Android foreground-service or iOS background-location modes.

**Rationale**: Flutter exposes multiple lifecycle transitions, and relying only on pause can miss conservative shutdown opportunities. Canceling on every non-resumed state is privacy-safe and testable on both mobile targets. Sources: [Flutter AppLifecycleListener](https://api.flutter.dev/flutter/widgets/AppLifecycleListener-class.html) and [geolocator platform/permission guidance](https://pub.dev/packages/geolocator).

**Alternatives considered**:

- Android/iOS background location: rejected by the specification's foreground-only rule.
- Keep the stream alive and discard callbacks: rejected because the platform location service would continue collecting unnecessarily.
- Persist an auto-resume flag across process launch: rejected because reopening requires a new explicit start action.

## Decision 6: Refresh at a Bounded Cadence and Validate Samples

**Decision**: Request high-accuracy foreground fixes, publish at most once every 15 seconds, and publish sooner only when the provider produces a newer usable fix after the interval gate. Reject non-finite/out-of-range coordinates, negative or non-finite accuracy, accuracy above 5,000 meters, and samples whose monotonic acquisition-to-submit age exceeds 30 seconds. Report approximate/high-uncertainty locations using their accuracy radius rather than implying precision.

**Rationale**: Fifteen seconds allows eight refresh opportunities inside the two-minute freshness window without excessive writes. Accuracy is device-reported and cannot prove physical truth, but bounds remove malformed data and let the UI communicate uncertainty.

**Alternatives considered**:

- Publish every provider callback: rejected because it creates unnecessary command/function/write load.
- Distance-only updates: rejected because a stationary attendee's point would expire.
- Trust the device wall-clock sample timestamp: rejected because the specification explicitly covers incorrect device time.

## Decision 7: Enforce a Two-Minute Product Boundary with Trusted Time

**Decision**: Accepted location commands use their Rules-validated server `createdAt` as `acceptedAt`; `expiresAt` is exactly two minutes later. The repository queries by outing, synchronizes a trusted clock through owner-private time probes, excludes/times out expired points exactly at the boundary, and never returns them to Cubits. Direct document gets are denied after `request.time`. A one-minute scheduled cleanup and TTL remove physical records.

**Rationale**: Firestore TTL is not instantaneous and can take about 24 hours, so it cannot define visibility. Rules evaluate list queries against potential results and cannot safely assert a moving per-document expiry cutoff. The supported repository therefore provides the exact product boundary, while Rules still enforce all identity/lifecycle privacy and deny expired direct gets. Sources: [Firestore TTL behavior](https://firebase.google.com/docs/firestore/ttl), [Rules are not filters](https://firebase.google.com/docs/firestore/security/rules-query), and [field-level limitations](https://firebase.google.com/docs/firestore/security/rules-fields).

**Alternatives considered**:

- TTL alone: rejected because deletion is delayed.
- Device `DateTime.now()`: rejected because device time can be wrong.
- A separate trusted read API: stronger for raw list expiry, but rejected for Phase 6 because the supported repository plus rapid hard cleanup meets the product boundary without introducing another service boundary. A blocking emulator proof remains required.

## Decision 8: Use Google Maps on Android and iOS

**Decision**: Add the official `google_maps_flutter` renderer and implement `MapProvider` with Google Geocoding search/reverse-label operations. Supply separate Maps SDK and client-side Geocoding keys for Android and iOS outside source control, with application and API restrictions. Google Maps renders required map attribution; legal notices remain available through Flutter's license UI.

**Rationale**: Android and iOS are the supported Live Meetup targets, so the official Google Maps plugin provides the desired native map experience without a desktop fallback. The Geocoding API provides forward and reverse address mapping behind the existing domain interface. Sources: [Google Maps Flutter setup](https://developers.google.com/maps/flutter-package/config), [Geocoding API](https://developers.google.com/maps/documentation/geocoding), and [Google Maps API security guidance](https://developers.google.com/maps/api-security-best-practices).

**Alternatives considered**:

- MapTiler plus `flutter_map`: no longer selected after Android/iOS became the explicit product scope.
- A platform WebView: rejected because the official native SDK integration is available.
- Public OpenStreetMap tile servers in production: rejected because production traffic and caching must use a service with an explicit application agreement and quota.

## Decision 9: Keep Map and Location Providers Out of Domain Contracts

**Decision**: Domain contracts use `GeoCoordinate`, `DeviceLocationSample`, and `PlaceCandidate` value objects. Data adapters translate Firestore `GeoPoint`, geolocator `Position`, and Google Geocoding JSON. The presentation-only `MeetupMap` translates domain coordinates to Google Maps markers.

**Rationale**: This satisfies the constitution's interface-first rule and makes domain/Cubit tests independent of plugins, network, and rendering.

**Alternatives considered**:

- Expose plugin types directly: rejected because it couples business and presentation state to providers.
- Put a Flutter `Widget` factory in the domain layer: rejected because the domain must remain platform-agnostic.

## Decision 10: Store the Meetup Point Separately from the Outing

**Decision**: Store `meetup_points/{outingId}` with the selected coordinate, a snapshot of the finalized `locationText`, setter, and accepted tuple. Confirmed organizer/owner preparation can read it without exposing participant live data; Meeting attendees can read it. Agreement/lifecycle code deletes or invalidates it if the finalized free-text location changes.

**Rationale**: Existing outing documents have broader visibility. A separate document permits the specification's narrower pre-Meeting access and prevents a prepared point from silently referring to a changed location label.

**Alternatives considered**:

- Fields on `outings`: rejected because they could expose the exact point before Meeting to users not authorized for preparation.
- Store only on-device until Meeting: rejected because another authorized organizer/device must see and update the prepared point.

## Decision 11: Finalize Privacy-Sensitive Transitions Only After Deletion

**Decision**: Outing completion, Accepted-to-Declined attendance changes, and participant/membership removal use requester-private `live_meetup_transitions` rather than direct client writes. Trusted processing first marks the authoritative outing, participant, or membership `liveMeetupCleanupPending`, which Rules treat as immediately ineligible. A resumable coordinator then deletes the affected deterministic status/share/location records in bounded batches, verifies that none remain, applies the requested lifecycle, attendance, or eligibility mutation, clears/removes the pending record, and only then marks the transition command successful. Both existing attendance-response repository entry points use this transition when an Accepted participant selects Declined. A failed worker leaves the target pending and inaccessible, and retry/scheduled repair resumes from persisted progress without reporting success. Outing deletion continues to mark `deletionPending`, terminates commands, sweeps all Phase 6 collections, deletes the outing, and repeats the sweep. Event triggers, a minutely repair job, and TTL remain defense-in-depth for administrative bypasses, expired locations, abandoned commands, and probes.

**Rationale**: The constitution and refined specification require protected presence to be physically absent before an outing/eligibility transition is acknowledged. Asynchronous post-write triggers can deny access promptly but cannot satisfy delete-before-acknowledgment. A staged command preserves the existing repository transport, supports member removal across multiple outings without exceeding one write batch, and keeps partial failures inaccessible and resumable.

**Alternatives considered**:

- Asynchronous event cleanup as the normal path: rejected because the underlying transition would already have been acknowledged before physical deletion.
- One unbounded transaction/batch: rejected because membership and crew operations can span multiple outings and exceed bounded write limits.
- Client cleanup: rejected because it is interruptible and cannot protect against in-flight trusted handlers.
- Rules only: rejected because denied records would remain stored indefinitely.

## Decision 12: Keep Precise Coordinates Out of Logs and Long-Lived Commands

**Decision**: Logging includes command type, outcome code, latency, outing hash, and aggregate counts but never coordinates, accuracy, tile/search queries, session secrets, or participant display data. Trusted processing scrubs every terminal command payload immediately. Pending location commands expire after two minutes; all other pending/terminal commands use short bounded cleanup deadlines.

**Rationale**: Command staging is necessary for the cross-platform trusted boundary, but it must not become route history or diagnostics storage.

**Alternatives considered**:

- Retain payloads for debugging: rejected because it duplicates precise location history.
- Log rounded coordinates: rejected because repeated points can still reconstruct movement.
