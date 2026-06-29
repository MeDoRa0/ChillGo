# Quickstart Guide: Architecture & Multi-Platform Setup

This guide documents validation scenarios and setup commands to run and verify the architectural foundations of the ChillGo app.

## Prerequisites

- **Flutter SDK**: `3.44.2` or later
- **Dart SDK**: `3.12.2` or later
- **Firebase CLI**: Installed and logged in (`firebase login`)
- **Java Development Kit (JDK)**: Required for Firestore emulator execution

---

## Setup & Running Commands

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Verify Linting & Static Analysis
```bash
flutter analyze
```
*Expected Outcome: Command returns clean with zero errors or warnings.*

### 3. Run Automated Tests
```bash
flutter test
```
*Expected Outcome: All unit and bloc tests pass successfully.*

### 4. Start Firestore Local Emulator
```bash
firebase emulators:start --only firestore
```
*Expected Outcome: Emulator dashboard runs at http://127.0.0.1:4000 and Firestore port binds successfully.*

### 5. Run Application on Target Platforms
- **Android**:
  ```bash
  flutter run -d android
  ```
- **iOS**:
  ```bash
  flutter run -d ios
  ```
- **Web**:
  ```bash
  flutter run -d chrome
  ```
- **Windows**:
  ```bash
  flutter run -d windows
  ```

---

## Verification Scenarios

### Scenario 1: Routing & DI Validation
1. Launch the application.
2. Verify that the app transitions to the `HomeScreen` (`/`) within 3 seconds.
3. Trigger a route transition to `/details` using a developer mock button/navigation.
4. Verify that the `DetailsPage` displays parameters passed to it successfully.
5. Attempt to navigate to an invalid path (e.g. `/invalid-route`).
6. Verify that the app displays the `NotFoundScreen` with a fallback link to `/`.

### Scenario 2: Firebase & Exception Logging
1. Launch the app in debug mode.
2. Trigger a simulated exception (using a debug button that throws `StateError('Simulated crash')`).
3. Verify that:
   - The Flutter framework catches the exception.
   - The local logs print the error details.
   - A Crashlytics dispatch request is registered (simulated/printed in debug console, or logged to console output).

### Scenario 3: Responsive UI Adaptability
1. Launch the app on **Web** or **Windows** desktop.
2. Resize the window down to mobile width (e.g., 360px).
3. Verify that the home screen elements arrange vertically or scale gracefully without overflow warnings.
4. Resize the window to tablet width (e.g., 768px) and desktop width (e.g., 1200px).
5. Verify that layout adjustments (e.g. multi-column layouts, expanded sidebars) appear as expected.
