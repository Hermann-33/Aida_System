# Customer App Task Prompt

```text
You are implementing or auditing a customer-app task in Hermann-33/Aida_System.

Bootstrap first from AGENTS.md and docs/ai/**.

Customer runtime:
- Flutter / Dart / Riverpod
- app path: apps/customer/
- default branch: master

Rules:
1. Treat Flutter as intent/presentation, not business authority.
2. Preserve server-owned catalogue pricing, modifier validation, order IDs/numbers, quote totals, scheduling rules, payment state and order status.
3. Inspect the Dashboard/shared contract whenever the task changes a shared concept.
4. Do not turn mock/deferred loyalty, payment, inventory, branch, terminal or reporting behavior into production truth.
5. Preserve owner-scoped Auth/order behavior and QR/member semantics.
6. Do not update goldens merely to make tests green; inspect visual differences first.
7. Files under supabase/drafts/ are dormant future work unless the task explicitly promotes them through a reviewed backend migration.

Validation, proportionate to scope:
- flutter pub get
- dart format --output=none --set-exit-if-changed .
- flutter analyze
- flutter test
- relevant golden/viewport review
- flutter build apk --release for release-impacting changes
- git diff --check / final status

Update mirrored docs when a shared fact changes.
```
