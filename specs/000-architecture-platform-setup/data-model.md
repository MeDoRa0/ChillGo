# Data Model: Architecture & Multi-Platform Setup

This document defines the schemas and structures for the data entities introduced in Phase 0.

## 1. AppConfiguration

Represents the application startup state and service initialization status. This model can be stored locally (e.g., using `SharedPreferences` or kept in-memory) to track the app state.

### Schema

| Field Name | Type | Description |
|---|---|---|
| `id` | `String` | Unique identifier (normally a static key like `"global_config"`) |
| `isFirebaseInitialized` | `bool` | True if Firebase Core initialized successfully |
| `isCrashlyticsEnabled` | `bool` | True if Firebase Crashlytics is initialized and active |
| `isAnalyticsEnabled` | `bool` | True if Firebase Analytics is initialized |
| `isFcmEnabled` | `bool` | True if Firebase Cloud Messaging is initialized |
| `platform` | `String` | Operating system/platform identifier (`"android"`, `"ios"`, `"web"`, `"windows"`) |
| `appVersion` | `String` | Current running version of the application (e.g. `"1.0.0"`) |
| `lastStartupTime` | `DateTime` | Timestamp of the last application launch |

### Validation Rules
- `platform` MUST be one of: `"android"`, `"ios"`, `"web"`, `"windows"`.
- `appVersion` MUST follow semantic versioning format (e.g., `"x.y.z"`).

---

## 2. DiagnosticsLog

Encapsulates application errors, warnings, and diagnostic traces captured locally. These can be logged to a local buffer and synchronized to Firestore or remote crashlytics servers.

### Schema

| Field Name | Type | Description |
|---|---|---|
| `id` | `String` | Unique log entry identifier (UUID) |
| `errorMessage` | `String` | Descriptive message of the error or event |
| `stackTrace` | `String?` | Stack trace associated with the error (nullable for non-error logs) |
| `severity` | `String` | Severity level of the log entry (`"info"`, `"warning"`, `"error"`, `"fatal"`) |
| `timestamp` | `DateTime` | When the event was recorded |
| `deviceMetadata` | `Map<String, dynamic>` | Key-value pairs containing platform and environment context at the time of log |

### `deviceMetadata` Details
- `osVersion`: Operating system version (e.g. `"Windows 11"`, `"Android 13"`).
- `deviceModel`: Device hardware model (e.g. `"iPhone 14"`, `"Pixel 6"`).
- `screenSize`: Screen dimensions formatted as `"width x height"` (e.g., `"390 x 844"`).
- `isOffline`: Boolean indicating whether internet was unavailable.

### Validation Rules
- `severity` MUST be one of: `"info"`, `"warning"`, `"error"`, `"fatal"`.
- `timestamp` MUST NOT be in the future.
