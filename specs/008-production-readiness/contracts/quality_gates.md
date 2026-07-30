# Contract: Release Quality Gates

| Gate | Evidence | Passing condition | Failure action |
|---|---|---|---|
| Automated validation | Analyze, Flutter, Functions, integration, and Rules logs | 100% of designated checks pass in two consecutive complete runs | Reproduce and correct; flaky/unavailable is not a pass. |
| Protected access | Full Rules actor matrix | 100% expected denies and authorized controls | Pause candidate and correct Rules/code. |
| Core journeys | 100 trials per journey/platform | At least 95% without unhandled error | Investigate/fix before approval. |
| Usable views | Android/iOS timing evidence | p95 <= 3 seconds | Correct regression or record an approved non-blocking limitation. |
| Production stability | Crashlytics release dashboard for first 30 days | >=99.5% crash-free sessions, development builds excluded | Pause advancement and prepare corrective release. |
| Telemetry privacy | Schema and report samples | Required version/client information; no prohibited data | Disable unsafe signal and treat material exposure as a blocker. |
| Store readiness | Android/iOS package and listing checklist | Signed assets, metadata, disclosures, support details complete | Do not submit or advance. |

Critical or high-severity security, privacy, data-loss, or core-workflow defects block approval and advancement. Only a release owner may approve a documented non-blocking exception; exceptions never override this rule.
