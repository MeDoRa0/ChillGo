# Release operations

Run `dart run tool/run_release_validation.dart` for two automated candidate
attempts. Add `--android-integration` only for an approved Android emulator
session, and `--build-packages` for package verification. iOS integration is
pending macOS availability and must not be reported as complete. Record only
sanitized evidence using [candidate records](./candidates/README.md).
