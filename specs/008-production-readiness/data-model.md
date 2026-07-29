# Data Model: Production Readiness

Phase 8 adds version-controlled release evidence, not a new client-readable Firestore model.

| Entity | Location | Required fields | Validation and ownership |
|---|---|---|---|
| Release Candidate | `docs/release/candidates/<version>.md` | version/build, commit, artifact IDs, environment, status, known limitations | Release owner records and approves it. No credentials or user data. |
| Quality Gate Result | candidate evidence | suite/command, attempt, timestamp, outcome, sanitized log reference, measured value | Two complete consecutive passes are required. |
| Performance Sample | candidate evidence | scenario, platform, network profile, trial count, p50/p95, failures | Aggregate timings only; 100 trials per primary journey. |
| Operational Signal Definition | [telemetry contract](./contracts/telemetry_privacy.md) | event name, trigger, minimal parameters, review owner | Allowlisted only; prohibited content is rejected. |
| Incident Record | `docs/release/incidents/<id>.md` | severity, versions, impact, containment, corrective action, follow-up | Least-disclosing controlled record. |

## State transitions

```text
draft -> automated validation -> approval-ready -> beta 10% -> beta 50%
  -> public 100% -> complete
                    \\-> paused -> corrective candidate -> automated validation
```

Every advance requires the previous stage's quality gates. Critical/high security, privacy, data-loss, or core-workflow defects move the candidate to `paused` and cannot be waived.
