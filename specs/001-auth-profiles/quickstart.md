# Quickstart & Verification Guide: Phase 1 — Authentication & Profiles

This guide outlines the steps to verify the authentication and profile features using automated tests and the Firebase Emulator Suite.

## Prerequisites

1. Ensure the Firebase CLI is installed and you are logged in.
2. Java Development Kit (JDK) version 11 or higher is required to run the Firebase Emulators.

---

## 1. Local Emulators Setup & Run

The Firebase Emulator Suite allows testing authentication, Firestore rules, and storage rules locally without hitting production.

### Start the Emulators
From the root of the repository, execute:
```bash
firebase emulators:start
```
Once started, the following services will be available:
- **Authentication Emulator**: `localhost:9099`
- **Firestore Emulator**: `localhost:8080`
- **Storage Emulator**: `localhost:9199`
- **Emulator Suite UI**: `localhost:4000` (Open in browser to inspect data)

### Run the App Against Emulators
Pass the emulator flag when launching the Flutter app:
```bash
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```
On Android emulators, the app automatically uses `10.0.2.2` to reach the host machine. Other local targets use `127.0.0.1`.

---

## 2. Automated Tests Execution

Run unit and bloc tests locally to verify repository logic, validation rules, and state management states.

### Run Flutter Unit & Bloc Tests
Execute:
```bash
flutter test
```
All unit tests in `test/features/authentication/` and `test/features/profile/` should pass.

### Run Firestore Security Rules Tests
If rules tests are written in the `firestore_tests/` folder:
```bash
npm run test # or the designated test command within the test directory
```

---

## 3. Manual Verification Scenarios

You can verify the flows manually by running the application targeted to the local emulator.

### Scenario A: New User Onboarding
1. Launch the app in a simulator or browser pointed to the local emulator.
2. Tap **Sign in with Google** or **Sign in with Apple**. (The emulator will present a mock sign-in dialog).
3. Complete the mock sign-in.
4. Verify the app navigates to the **Profile Onboarding Screen**.
5. Attempt to submit an invalid username (e.g. `john doe` with spaces, or `jo` too short). Verify validation errors are shown.
6. Input a valid username (e.g. `johndoe`) and display name (e.g. `John Doe`) and submit.
7. Verify the app redirects to the **Dashboard Screen**.
8. In the Emulator Suite UI (`localhost:4000`), inspect:
   - Collection `usernames` has document `johndoe`.
   - Collection `users` has document matching the user's UID.

### Scenario B: Username Uniqueness Protection
1. Attempt to sign in with a second mock user.
2. In the profile onboarding screen, input the username `johndoe` (created in Scenario A).
3. Verify that the app shows a "Username is already taken" error and prevents submission.
4. Input a different username (e.g. `johndoe2`) and verify onboarding completes.

### Scenario C: Session Persistence & Sign Out
1. Close the application while logged in.
2. Relaunch the application.
3. Verify that the app bypasses the landing/login screen and opens directly to the Dashboard.
4. Navigate to the profile screen and tap **Sign Out**.
5. Verify the app returns to the landing screen and subsequent launches load the landing screen.

### Scenario D: Avatar Upload & Public Lookup
1. Sign in as an onboarded user and open the profile screen.
2. Attempt to upload an unsupported avatar file type or a JPEG, PNG, or WebP larger than 5 MB before compression. Verify the app rejects it with a clear validation message.
3. Upload a valid JPEG, PNG, or WebP avatar. Verify the avatar is compressed, saved, and displayed on the profile screen.
4. Sign in as a second authenticated user and search for the first user's username.
5. Verify the lookup returns only the username, display name, and avatar.
