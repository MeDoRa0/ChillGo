# Release candidate evidence

Create one record per immutable build as `<version>+<build>.md`. Do not record
user data, tokens, raw logs, or signing credentials.

## Candidate template

```md
# Candidate <version>+<build>

- Commit:
- Release owner:
- Environment and fixed network profile:
- Android App Bundle / iOS archive identifiers:
- Known limitations:

## Automated gates (two consecutive runs)
| Attempt | Timestamp | Analyze | Flutter | Functions | Rules | Integration | Result |
|---|---|---|---|---|---|---|---|
| 1 | | | | | | | |
| 2 | | | | | | | |

## Performance and telemetry review
- 100 trials per journey/platform; p50/p95 and failures:
- Sampled schema/report types; prohibited-content review:

## Approval and rollout
- Approval-ready owner/date:
- Beta 10% invited cohort and monitoring window:
- Beta 50% invited cohort and monitoring window:
- Public-release approval:
- Pause/rollback decision and rationale:
```

Treat failures as failures, including flaky or unavailable suites. A critical or
high security, privacy, data-loss, or core-workflow issue pauses progression.
