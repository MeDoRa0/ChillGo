# Performance validation

Use a fixed non-production launch profile (stable emulator/device, warm DNS,
documented Wi-Fi or cellular profile) and record it in candidate evidence. Run
100 trials per primary journey on Android and iOS, collecting aggregate elapsed
milliseconds only. Sort timings; p50 is the middle sample and p95 is index
`ceil(0.95*n)-1`. At least 95% must complete without unhandled error and p95
must be at most 3 seconds. The first-release scope supports up to 1,000 MAU.
