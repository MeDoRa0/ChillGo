# Quickstart: Validate a Release Candidate

## Prerequisites

- Work on `codex/008-production-readiness` with Flutter, Node.js 22, Firebase CLI, Android SDK, and a macOS/Xcode environment for iOS. Phases 0-7, including the complete notification feature, are release-candidate prerequisites.
- Use a non-production Firebase project and external secrets for automation. Never commit signing keys, store credentials, Maps keys, or user evidence.
- Do not use physical devices, invite beta users, submit to either store, or release publicly without explicit user approval.

## Automated validation

1. Record candidate version/build, commit SHA, environment, and fixed launch network profile.
2. Run static, Flutter unit, and widget/interface suites twice from a clean state:

   ```powershell
   flutter analyze
   flutter test
   ```

3. Run Functions and Rules validation:

   ```powershell
   Set-Location functions
   npm run build
   npm test
   Set-Location ..\firestore_tests
   npm test
   ```

4. Run deterministic Android/iOS MVP integration and performance harnesses. Record the 100-run trial count, p50, p95, failures, and build; local emulator timing never substitutes for approved physical-device measurement.
5. Validate the Rules authorization matrix for no session, non-member, removed member, revoked/expired invitation, non-participant, and authorized controls across every protected collection/action.
6. Review every allowed analytics event and sampled Crashlytics report: release version/client type must exist and prohibited data must not.
7. Verify Android/iOS non-placeholder IDs, external signing, version alignment, App Check/Firebase configuration, permission explanations, privacy/support links, assets, and store metadata.

## Approval and rollout

The release owner may approve beta 10% only after two clean runs, passing quality gates, no release blocker, and complete release evidence. Review the defined monitoring window before beta 50%, then before 100% public availability. Pause on a blocker and follow [release operations](./contracts/release_operations.md).
