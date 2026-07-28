# Contract: Map and Device Location Services

This contract keeps location acquisition, map content, and map rendering behind provider-neutral boundaries.

## Domain Values

### `GeoCoordinate`

- latitude: finite `-90..90`
- longitude: finite `-180..180`

### `DeviceLocationSample`

- coordinate
- accuracy meters
- monotonic acquisition marker/age
- provider accuracy category when available

No device wall-clock timestamp is authoritative.

### `PlaceCandidate`

- provider-opaque result ID
- display label
- coordinate
- optional bounding box

## `DeviceLocationService`

Operations:

- check whether location service is available;
- inspect/request when-in-use permission;
- expose whether precision is reduced/approximate where the platform reports it;
- stream foreground positions using configurable accuracy, distance, and timeout;
- stop/cancel immediately.

Behavior:

- no stream begins before the explicit sharing explanation and action;
- no Always/background permission is requested;
- Web reports HTTPS/secure-context failures as actionable service failures;
- denial/permanent denial/service-disabled conditions are distinct;
- approximate results remain usable when within the accepted 5,000-meter bound, but the UI shows their accuracy;
- samples are usable only with finite latitude `-90..90`, finite longitude `-180..180`, finite accuracy `0..5000` meters, and monotonic acquisition-to-submit age no greater than 30 seconds;
- rejecting a stale or malformed sample does not replace the last accepted location or extend its expiry;
- provider callbacks after cancellation are ignored.

## `MapProvider`

Operations:

- report whether the platform-specific Google Maps key is configured;
- search the finalized free-text location for organizer point preparation;
- optionally reverse-label a selected coordinate for confirmation;
- return provider-neutral failures.

Google Maps adapter:

- uses the official Google Maps Flutter renderer and HTTPS Geocoding API;
- reads distinct Maps SDK and Geocoding keys for Android/iOS from build
  configuration, never source control;
- applies Android package/certificate or iOS bundle restrictions and restricts
  each key to only its required Maps SDK or Geocoding API;
- relies on the native renderer for map attribution and exposes Google legal
  notices through the application license UI;
- does not send participant live coordinates to geocoding.

## Map Rendering

`MeetupMap` uses `google_maps_flutter` only in presentation:

- destination marker is visually and semantically distinct;
- participant markers expose display name, status, freshness, and accuracy;
- overlapping markers remain individually discoverable through selection/list controls;
- marker meaning never relies only on color;
- map gestures have keyboard/button alternatives for zoom and recenter;
- the textual alternative is always reachable and contains all required coordination information;
- map/search failure leaves the textual alternative and status/sharing controls usable.

## Platform Configuration

- Android: foreground/when-in-use fine and coarse location declarations only; no background location/foreground service.
- Android: inject `GOOGLE_MAPS_ANDROID_SDK_API_KEY` from the ignored
  `android/maps-secrets.properties` file into the manifest and restrict it to
  Maps SDK for Android and the release application certificate.
- iOS: `NSLocationWhenInUseUsageDescription`, iOS 14 minimum, and geolocator
  configured to bypass Always permission; inject
  `GOOGLE_MAPS_IOS_SDK_API_KEY` through the untracked xcconfig.
- Geocoding: keep `GOOGLE_MAPS_GEOCODING_API_KEY` in Firebase Secret Manager;
  authenticated `searchMapPlace` and `reverseGeocode` callable functions own
  Google Geocoding API requests. The mobile app never receives this key.

## Test Doubles

- deterministic location service with permission/service/sample streams;
- fake map provider with fixed tile/search results and failures;
- widget map surface replacement so marker semantics and textual parity can be tested without network tiles.
