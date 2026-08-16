# TASK-CLOSEOUT-001 Final Evidence — 2026-08-17

This record freezes the final closeout evidence for the current AIDA implementation tranche. Dynamic counts below are dated observations, not permanent invariants.

## Verdict

`COMPLETE`

All scoped implementation, local toolchain, security-boundary and applicable ADR-0004 cross-client validation gates are closed.

## Live backend snapshot

Independently rechecked after the final E2E:

- Auth users: 9
- profiles: 9
- members: 6
- owner/admin/staff roles: 1 / 1 / 1
- catalogue revision: 15
- retained orders: 1

Employee identities remain separate from customer/member records.

## Previously validated physical paths

- Android release APK installed and connected to Supabase.
- Fresh customer signup succeeded.
- Trusted Auth/profile/member provisioning succeeded.
- New member appeared in protected Dashboard Members.
- Real Owner Dashboard login succeeded.
- Owner catalogue price mutation propagated to the installed customer app.
- The Android release host-lookup/network defect did not recur.

## Customer closeout gates

- Flutter 3.44.9 dependency resolution: PASS
- analyze: PASS, no issues
- tests: PASS, 44/44
- release APK: PASS
- independent clean-worktree release build: PASS
- production INTERNET permission: PASS
- canonical Auth/member SQL regression: PASS transactionally
- canonical catalogue SQL regression: PASS transactionally
- canonical order SQL regression: PASS transactionally
- Android build reproducible from committed Git: PASS

Committed Android toolchain closeout uses AGP 8.9.1 and Gradle 8.11.1 with the required Flutter compatibility properties.

## Dashboard closeout gates

- lint: PASS with two established Fast Refresh warnings
- typecheck: PASS
- Vitest: PASS, 25 files / 111 tests
- production build: PASS
- Playwright: PASS, 8/8
- `npm audit`: PASS, 0 vulnerabilities
- `git diff --check`: PASS
- preview/live session regression: PASS
- authoritative POS quote/place/order queue/status frontend: PASS

## Final live cross-client order E2E

Customer catalogue selection:

- item: Sandwich
- item UUID: `88c53b7e-7c16-420f-8650-b2587cca4103`
- published/available: yes
- required variant/add-on: none

Authoritative quote:

- fulfilment: ASAP
- total: 1,290 sen

Persisted order:

- order UUID: `7cf027dc-3ff0-4604-a3fd-c7a943aac603`
- order number: `100006`
- source: customer
- initial status: `confirmed`
- initial status version: 1

Dashboard/Customer lifecycle:

1. Dashboard queue observed the exact persisted UUID/order number/total/status/version.
2. Dashboard BFF transitioned `confirmed` v1 → `preparing` v2.
3. Customer-authorized `get_order` returned `preparing`.
4. Dashboard BFF transitioned `preparing` v2 → `ready` v3.
5. Customer-authorized `get_order` returned `ready`.
6. Dashboard BFF transitioned `ready` v3 → `completed` v4.
7. Customer-authorized `get_order` returned `completed`.
8. Final Dashboard all-status queue observed the completed order.

Independent database verification confirms the order remains `completed` at version 4 and the order-event ledger contains created/confirmed → preparing → ready → completed.

## Credential handling

Approved demo credentials were supplied only through process-local environment variables for the E2E run. They were removed afterward and were not added to repository files, documentation, commits or PR comments.

No service-role credential, direct SQL order insert, password reset or browser employee bearer-token persistence was used.

## Current security advisor

One hosted Auth WARN remains:

- `auth_leaked_password_protection` — Leaked Password Protection Disabled

Remediation: <https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection>

This operational setting is deferred security configuration debt and is not an RLS/application-authority regression.

## Merge state

- Customer PR #13 → `master`: COMPLETE and independently mergeable.
- Dashboard PR #12 → `main`: COMPLETE and independently mergeable.

Hosted/Vercel deployment remains DEFERRED and is not a blocker for the accepted local Dashboard PC → cloud Supabase → installed Android phone topology.

## Deferred domains

Real payment/refunds, loyalty earning/redemption, inventory, promotions/discount authority, tax/accounting, trusted reporting, branch-scoped operations/capacity, delivery and hosted production deployment/release operations remain future bounded tasks.
