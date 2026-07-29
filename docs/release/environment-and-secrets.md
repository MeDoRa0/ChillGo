# Environment and secret inventory

Release owner: **TBD before any store upload**. Store accounts and external
Android upload key / Apple signing ownership: **TBD and kept outside this repo**.

The permanent Android/iOS identity must be selected by the release owner before
first upload; placeholder identities are prohibited. Environments: local
emulator, non-production Firebase validation, and production Firebase. External
secrets include Firebase configuration, Play upload key, App Store credentials,
APNs credentials, Maps keys, and any CI secret. None may be committed.
