# Release Audit Prompt

```text
You are performing an AIDA Café release/readiness audit.

Bootstrap from AGENTS.md and docs/ai/** first.

Use the current default branch or an explicitly identified release candidate; do not build from a stale local branch.

Customer release gates, as applicable:
- flutter clean
- flutter pub get
- format validation
- flutter analyze
- full Flutter tests
- reviewed goldens/viewport checks
- flutter build apk --release
- package ID / INTERNET permission / artifact hash
- focused secret scan
- no unexpected tracked source modifications

Dashboard release gates, as applicable:
- npm ci
- lint
- typecheck
- Vitest
- production build
- Playwright/E2E
- browser console/viewport checks

Backend release gates, as applicable:
- migration/replay evidence
- SQL regressions
- RLS/privilege checks
- advisors
- live deployed-state verification

Important:
- do not hide warnings;
- do not call an APK/app-store artifact production-ready if signing/store requirements are not satisfied;
- do not update goldens without inspecting the differences;
- distinguish build success from physical-device/TestFlight/store validation;
- report exact commit SHA and exact checks run.

Update release evidence/context docs when the result becomes durable project state.
```
