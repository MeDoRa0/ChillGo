# Contract: Release Operations and Incident Response

## First-release rollout

1. The release owner approves the candidate only after all quality gates pass twice.
2. With explicit user approval, invite the 10% Android/iOS beta cohort and perform approved device checks.
3. Review the fixed monitoring window: crash-free sessions, unexpected-failure samples, journey completion, privacy, and support observations.
4. Repeat at the 50% beta cohort.
5. Submit/release to 100% public store availability only after the final review. Future Android/iOS updates use their store-native staged/phased release features.

## Incident response

1. Triage severity and affected versions without copying protected data.
2. Assess impact and contain using the least-destructive control: pause progression, disable unsafe telemetry, revoke unsafe access, or remove distribution as appropriate.
3. Send the minimum necessary user/support communication; never confirm protected crew, outing, invitation, vote, chat, or location details.
4. Validate a corrective candidate through the full gates, or document a rollback/removal decision.
5. Record root cause, remediation, and follow-up prevention after containment.

## Required release evidence

Candidate identity; two-run validation logs; Rules matrix; performance profile; crash/analytics review; privacy review; Android/iOS signing/configuration; store metadata/assets/support/privacy links; approved manual validation; limitations; monitoring windows; release owner; and pause/rollback/corrective-release decision.
