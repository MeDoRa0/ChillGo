# Quickstart & Validation Guide: Live Meetup

This guide validates the Phase 6 design in [data-model.md](./data-model.md) and [contracts/](./contracts/). It does not authorize deployment, physical-device E2E, or usability sessions.

## Prerequisites

1. Phases 2-5 are implemented, including Accepted attendance, outing lifecycle, chat trusted clock pattern, and outing deletion.
2. Flutter/Dart dependencies are installed.
3. Node.js 22, Functions dependencies, and Firebase CLI are available.
4. Auth, Firestore, and Functions emulators use the repository configuration.
5. Separate restricted Google Maps Android/iOS keys are supplied outside source
   control for platform smoke tests.
6. Android/iOS location configuration follows [contracts/map_location_services.md](./contracts/map_location_services.md).

### Platform and provider setup

- Android declares only coarse/fine foreground location permissions. iOS declares only when-in-use access and the Podfile sets `BYPASS_PERMISSION_LOCATION_ALWAYS=1`. Do not add background location or foreground-service capabilities.
- Enable billing, Maps SDK for Android, Maps SDK for iOS, and Geocoding API in
  the Google Cloud project.
- Android: set `GOOGLE_MAPS_ANDROID_SDK_API_KEY` in the ignored
  `android/maps-secrets.properties` file. Restrict it to the Android
  package/certificate and Maps SDK for Android.
- iOS: copy `ios/Flutter/GoogleMapsSecrets.xcconfig.example` to the ignored
  `ios/Flutter/GoogleMapsSecrets.xcconfig`, set
  `GOOGLE_MAPS_IOS_SDK_API_KEY`, and restrict it to the iOS bundle ID and Maps
  SDK for iOS.
- Store `GOOGLE_MAPS_GEOCODING_API_KEY` only in Firebase Secret Manager and
  bind it to `searchMapPlace` and `reverseGeocode`. The Flutter app calls these
  authenticated callable functions; it never contains a Geocoding API key.
- Never commit an API key. Set usage quotas and billing alerts for Google Maps
  Platform and Firebase.
- Start Auth, Firestore, and Functions emulators together for transition scenarios because delete-before-acknowledgment behavior crosses all three services.

## Automated Validation

### Focused Flutter Tests

```bash
flutter test test/features/live_meetup/ test/features/outings/presentation/widgets/interactive_outing_card_test.dart test/core/routes/app_router_test.dart test/core/di/injection_container_test.dart
```

**Expected**: Domain policies, mapping, trusted expiry, access revocation, command outcomes, process-only sharing, lifecycle pause/resume, permission failures, map/text parity, Cubits, route, DI, and outing-entry tests pass.

### Full Flutter Suite and Analyzer

```bash
flutter test
dart analyze
```

**Expected**: Existing features remain green and no new analyzer findings are introduced.

### Functions Unit Tests

```bash
npm --prefix functions run test:live-meetup
```

**Expected**: Schema, trusted ordering, idempotency, status replacement, transfer, stop/update races, stale samples, point authority, resumable delete-before-acknowledgment transitions, cleanup, and outing deletion pass.

Full Functions suite:

```bash
npm --prefix functions test
```

### Firestore Security Rules

```bash
npm --prefix firestore_tests test
```

**Expected**: Meeting eligibility, Accepted attendance, organizer point preparation, bounded queries, command privacy, direct-get expiry, access loss, and existing feature regressions pass.

### Integrated Emulator Flow

```bash
npm --prefix functions run test:live-meetup:integration
```

**Expected**: Authenticated commands reach terminal state, listeners receive current state, one-device transfer/stop ordering holds, stale points disappear, and lifecycle/eligibility transitions deny access, delete protected presence, and only then acknowledge finalization without recreation.

## Verification Record — 2026-07-27

- `flutter test --no-pub test/features/live_meetup`: 33 passed.
- Focused Outing/Agreement/Crew repository transition tests: 44 passed.
- `flutter test --no-pub`: 261 passed after the Google Maps migration.
- `dart analyze`: completed with no errors or warnings; eight pre-existing or
  style-only info diagnostics remain.
- `flutter build apk --debug --no-pub`: completed successfully with the
  official Google Maps Android SDK linked; no API key was embedded in this
  configuration-only build.
- `npm --prefix functions test`: 39 passed and 19 emulator-only tests skipped
  outside an emulator environment.
- Live Meetup Auth/Firestore/Functions integration profile: 3 passed, including
  an idempotent Accepted-to-Declined transition, bounded deletion of 300
  presence records for 100 attendees before the outing reached Completed, and
  Cancelled/Archived cleanup of anomalous presence.
- Recovery, ordering, and deletion emulator profiles cover cleanup-pending
  denial, cursor pause/resume, terminal acknowledgment, transfer/stop races,
  expiry, duplicate delivery, and delayed-command non-recreation.
- Firestore/Storage Rules suite: 46 passed, including requester-private
  transitions, forged-target denial, direct destructive-write denial, and
  cleanup-pending access denial.

The automated Flutter runs are platform-neutral. Permission prompts, real
foreground/background behavior, native map interaction, and assistive
technology still require the explicitly authorized manual platform gate below.
The integration profile proves the 100-attendee cleanup boundary, but it does
not replace native-network or production smoke measurements.

The local Firestore emulator performance profile completed 100 trials for each
required path:

| Path | Median | p95 | Maximum | Requirement |
|---|---:|---:|---:|---|
| Status command-to-observer | 111 ms | 272 ms | 273 ms | p95 < 5 s |
| Location command-to-observer | 87 ms | 117 ms | 118 ms | p95 < 5 s |
| 100-attendee meetup opening queries | 16 ms | 28 ms | 51 ms | p95 < 3 s |
| Accepted stop-to-observer removal | 62 ms | 65 ms | 80 ms | all < 5 s |

All 100 accepted-stop trials removed the observed location. The profile uses a
local emulator and therefore establishes deterministic application/query
behavior, not production network latency.

### Privacy audit

Source and test searches covered precise coordinate fields, session tokens,
geocoding text, logging, analytics, crash reporting, command terminalization,
transition terminalization, and outing deletion. Runtime logs contain only
operation type, safe error code, counts, status, and latency; they do not emit
coordinates, session credentials, or location text. Session tokens remain
process-only on the client, are hashed in trusted share state, and command
payloads are scrubbed at terminal state. Transition targets, cursors, leases,
and processing claims are scrubbed at terminal state. No route history,
background-location service, coordinate analytics, or coordinate crash payload
was found.

## Validation Scenarios

### A. Status and Attendee Summary

1. Create a Meeting outing with Accepted, Invited, and Declined participants.
2. Verify only Accepted current crew members open Live Meetup.
3. Update each of the three statuses and verify one current value with trusted time.
4. Race two devices and verify the newer command tuple wins without history.
5. Verify Accepted attendees without a status appear as Not Updated.

### B. Explicit Consent and Permission

1. Open Live Meetup with sharing off and verify no location command/listener starts.
2. Review consent text, deny permission, and verify status remains usable.
3. Grant approximate permission and verify accuracy is disclosed.
4. Start sharing and verify a fresh point becomes visible.
5. Stop and verify the point deletion is observed within five seconds of accepted stop.

### C. Lifecycle and Process Boundary

1. Share while navigating to another ChillGo screen; verify foreground sharing continues.
2. Move the app to inactive/hidden/paused and verify the location stream is canceled.
3. Resume the same process and verify the same in-memory session may resume.
4. Keep it backgrounded beyond two minutes and verify the point expires.
5. terminate/relaunch the process and verify no automatic sharing starts; explicit start/transfer is required.

### D. Multi-Device Transfer and Races

1. Start session A and publish a point.
2. Start session B without transfer confirmation and verify `transferRequired`.
3. Confirm transfer; verify the point is deleted and session A updates fail.
4. Overlap A update, B transfer, and A stop; verify B remains the only active capability.
5. Verify one participant identity and at most one marker throughout.

### E. Freshness and Invalid Samples

1. Publish valid points immediately before and after an expiry boundary.
2. Set device wall time incorrectly; verify trusted time controls freshness.
3. Verify a point is removed exactly at two minutes without a manual refresh.
4. Reject out-of-range, non-finite, negative accuracy, over-5,000-meter accuracy, and over-30-second sample-age attempts.
5. Run scheduled cleanup twice and verify idempotent physical deletion.
6. Complete the blocking Rules/repository proof for direct gets, bounded lists, drift, long-lived listeners, and timers.

### F. Meetup Point and Map

1. In Confirmed, verify only a creator who remains a current crew member or the current crew owner can search/select/confirm a point regardless of attendance; verify a former-crew creator cannot.
2. Verify preparation exposes no participant status/location.
3. Enter Meeting and verify eligible attendees see destination plus participant markers.
4. Change the point and verify all open views distinguish the replacement.
5. Change the finalized free-text location through trusted agreement flow and verify a stale point is removed.
6. Simulate tile/search failure and verify the textual alternative and status/sharing controls remain complete.

### G. Access Loss and Cleanup

1. While views are open, request an Accepted-to-Declined attendance change through each existing attendance-response entry point, participant removal, crew-membership removal, and each Completed, Cancelled, and Archived outing transition through their trusted transition operations.
2. Verify the target becomes cleanup-pending, Rules deny the next read/write, and supported clients clear protected data within one second of observation.
3. Pause trusted processing between bounded deletion batches; verify the transition is not reported successful, access stays denied, and a retry resumes from persisted progress.
4. Verify all affected status/share/location records are absent before the coordinator applies the terminal status or removes the participant/membership and reports success.
5. Overlap the transition with publish/start/point commands and verify cleanup-pending state prevents recreation.
6. Repeat completed transitions and repair invocations and verify idempotent success without restored data.
7. Permanently delete the outing and verify all Phase 6 records and commands are absent/inaccessible.

## Performance Profile

Seed one Meeting outing with 100 Accepted participants, 100 statuses, and 100 fresh locations.

- Run 100 status updates and 100 location updates at the SC-002 network profile.
- Record command creation-to-terminal latency and terminal-to-observer latency separately.
- Require at least 95 of each update type to become visible within five seconds.
- Run at least 100 meetup-open trials and require at least 95 to show summary, point state, and sharers within three seconds.
- Run at least 100 accepted-stop trials with another eligible view open and require every accepted stop to remove the sharer's location from the observer within five seconds; record stop acceptance-to-observer-removal latency separately.
- Confirm listener queries remain bounded to 100 and no historic locations are read.

## Mobile Platform and Manual E2E Gate

Android and iOS must each validate:

- when-in-use permission and denial recovery;
- foreground sharing and background pause;
- same-process resume and process-restart explicit consent;
- Google map rendering, attribution/legal notices, touch controls, and markers;
- textual alternative and assistive semantics;
- online-only failure with no delayed retry.

The constitution requires explicit user permission before manual E2E or usability work. Do not start or mark these checks complete without that authorization.

SC-001 and SC-007 require at least 20 representative participants, including at least five trials on Android and five on iOS. Record authorization, platform distribution, timings, assistance, failures, and outcomes here when approved.

## Deployment Gate

- Deploy Rules, Functions, scheduler, indexes, and TTL as one coordinated release.
- Verify scheduled Functions billing/project support.
- Verify `live_locations.expiresAt` and `live_meetup_commands.purgeAt` TTL policies in the deployed project.
- Configure separate protected Google Maps Android/iOS keys without committing secrets.
- Confirm provider attribution and account quota/alerts.
- Run production index, command, cleanup, and map/search smoke checks.
- Verify a production privacy-transition smoke flow never reports success before affected live status/share/location queries are empty.
- Confirm logs/analytics/crash reports contain no precise coordinates, session tokens, or geocoding text.
- Run all automated suites before enabling the feature.

### Production deployment record — 2026-07-28

- Project `chillgo-61439` received the compiled Firestore Rules, seven composite
  indexes, seven TTL field policies, and ten Node.js 22 second-generation
  Functions in `us-central1`.
- Both scheduled functions are active. `liveMeetupCleanupScheduled` completed
  its first production invocation with `deleted: 0` and `resumed: 0`.
- An isolated Accepted-to-Declined production smoke transition succeeded only
  after its status, share, and location documents were absent; attendance was
  finalized as Declined and all smoke fixtures were removed afterward.
- A valid unauthenticated REST read against `live_locations` returned HTTP 403
  under the deployed Rules.
- Production application logs from the scheduler and transition smoke contain
  operation type, terminal status, latency, and aggregate counts only; no
  coordinates, session tokens, geocoding text, or route history were emitted.
- Android coarse/fine location permissions and the iOS when-in-use description
  are present in source. The Google Maps renderer supplies map attribution.

T114 remains open because the current environment has no Google Maps SDK or
Geocoding keys for Android/iOS, so application/API restrictions, map/search
smoke behavior, quota, and alerts cannot be checked.
Firebase Storage is also not initialized in this project; its unchanged Rules
could not be deployed and Firebase directed the owner to complete Storage
setup in the console. Storage is not used by Live Meetup and was excluded from
the successful backend release.
