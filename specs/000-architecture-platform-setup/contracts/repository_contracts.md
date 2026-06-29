# Interface Contracts: Architecture & Multi-Platform Setup

This document specifies the abstract interfaces, API schemas, and routing contracts for the architecture layer.

## 1. Routing & URL Space Contract

The application utilizes declarative routing (`go_router`) to handle navigation, deep-linking, and error handling.

| Path | Screen Class | Parameters / Intent | Fallback / Guard |
|---|---|---|---|
| `/` | `HomeScreen` | Default entry point, displaying responsive layouts | None |
| `/details` | `DetailsPage` | Dummy page verifying parameter transition | Redirects to `/` if parameters invalid |
| `/error` | `NotFoundScreen` | Intercepts invalid routes and deep links | Fallback for any unmatched paths |

---

## 2. ConfigRepository Contract (Dart)

Abstract interface managing app configuration and platform states, decoupled from direct system plugins.

```dart
abstract class ConfigRepository {
  /// Fetches the local application configuration, or initializes it if empty.
  Future<AppConfiguration> getAppConfiguration();

  /// Updates a specific flag on the application configuration.
  Future<void> updateConfigFlag({
    required String key,
    required bool value,
  });

  /// Captures current platform, OS, and screen information.
  Map<String, dynamic> getPlatformMetadata();
}
```

---

## 3. DiagnosticsRepository Contract (Dart)

Abstract interface managing logging and crash reporting, abstracting Firebase Crashlytics.

```dart
abstract class DiagnosticsRepository {
  /// Initializes crashlytics and remote monitoring.
  Future<void> initialize();

  /// Logs a non-fatal error locally and triggers remote crashlytics report.
  Future<void> logError(dynamic error, StackTrace? stackTrace, {String? reason});

  /// Logs general diagnostic statements locally or to Analytics.
  Future<void> logInfo(String message, {Map<String, dynamic>? parameters});

  /// Installs global exception handlers capturing all uncaught Flutter/Platform exceptions.
  void installGlobalErrorHandlers();
}
```
