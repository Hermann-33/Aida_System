# Active Context

**As of:** 2026-08-17
**Current task:** `TASK-CLOSEOUT-001 — complete and close the current AIDA implementation tranche`
**Current verdict:** COMPLETE — implementation, live cross-client order E2E and final cross-repository verification gates pass.

## Current product reality

AIDA Café uses one Supabase backend for the Flutter customer app and the React Dashboard/Admin/POS. The current tranche has implemented, tested authority for customer Auth/member provisioning, protected employee/Admin sessions, shared catalogue, authoritative ordering/scheduling, customer order history/status, Dashboard POS quote/place/order queue/status transitions, and Android release networking/build reproducibility.

## Validated physical/manual evidence

The user validated on a physical Android phone and local Dashboard:

- release APK installation and Supabase connectivity;
- new customer signup;
- trusted Auth/profile/member provisioning;
- the new member appearing in protected Dashboard Members;
- real Owner Dashboard login;
- Owner catalogue price mutation;
- the installed customer app observing the updated catalogue value.

The previous Android `Failed host lookup / SocketException` release defect is closed.

## Current live Supabase evidence

Independently rechecked on 2026-08-17:

- Auth users: 9
- profiles: 9
- members: 6
- trusted roles: 1 owner, 1 admin, 1 staff
- retained orders: 1
- catalogue revision: 15

These counts are dated operational evidence, not architectural invariants. Employee identities are intentionally separate from customer/member rows.

The retained order is `100006` (`7cf027dc-3ff0-4604-a3fd-c7a943aac603`), customer source, authoritative total 1,290 sen, final status `completed`, status version 4. Its event ledger records creation as confirmed followed by preparing, ready and completed transitions.

All intended identity, catalogue and order tables retain RLS/FORCE RLS; the ordering RPC surface exists; `orders` remains published to Realtime; ordinary customer clients do not have direct commercial order DML authority.

## Customer implementation status

COMPLETE for the current tranche:

- Supabase Auth/session/signup/logout and trusted profile/member provisioning;
- server-owned member code and student pending declaration boundary;
- minimum per-user offline member-code cache with logout/user-switch isolation;
- shared catalogue, variants/add-ons and revision invalidation/refetch;
- authoritative quote-before-place and server-owned totals;
- retry-stable idempotent customer placement;
- ASAP/scheduled pickup from server policy;
- explicit `Pay at counter`/unpaid semantics;
- persisted server order number/status/history/detail;
- owner-scoped order Realtime invalidation followed by authorized refetch;
- Android production INTERNET permission;
- reproducible Android release build from committed Git.

Customer validation: Flutter 3.44.9, pub get PASS, analyze PASS, 44/44 tests PASS, release APK PASS in the task checkout and an independent clean committed worktree. Canonical Auth/member, catalogue and order SQL regressions pass transactionally.

## Dashboard implementation status

COMPLETE for the current tranche:

- same-origin employee/Admin BFF with HttpOnly session cookies and caller-JWT Supabase access;
- protected Admin Members;
- shared catalogue reads and protected Admin mutations;
- TASK-AUTH-005 preview/live session separation;
- typed same-origin order client;
- POS cart mapped to server-trusted IDs/quantity/note intent only;
- server quote rendered as commercial authority;
- stable `clientRequestId` for placement retries;
- ASAP/scheduled pickup derived from server policy;
- cart cleared only after persisted placement;
- explicit `Pay at counter`/unpaid semantics;
- live order queue polling every ~2.5 seconds with no preview-order fallback;
- legal versioned status transitions and 409 conflict refetch;
- no browser employee bearer-token persistence.

Dashboard validation: lint PASS with two existing Fast Refresh warnings, typecheck PASS, 25 Vitest files / 111 tests PASS, build PASS, Playwright 8/8 PASS, `git diff --check` PASS, and final `npm audit` 0 vulnerabilities.

## Final live order E2E

Completed on 2026-08-17 through supported customer and Dashboard BFF boundaries using approved demo credentials supplied only as process-local environment variables:

- customer Auth and active-member validation passed;
- live published Sandwich catalogue item quoted for ASAP pickup at an authoritative total of 1,290 sen;
- customer `place_customer_order` persisted order `100006` (`7cf027dc-3ff0-4604-a3fd-c7a943aac603`) as `confirmed`, version 1;
- the authenticated Owner Dashboard queue observed the same UUID, order number, total, status and version;
- Dashboard transitions persisted `preparing` version 2, `ready` version 3 and `completed` version 4;
- the customer's authorized `get_order` read observed each persisted status;
- the final all-status Dashboard queue contained exactly one retained order, the completed E2E order.

No service role, direct SQL order insertion, password reset, client-trusted price/status or browser employee bearer-token persistence was used. The credential variables were removed after authenticated work and were never committed.

## Security and deployment

The current Supabase security advisor has one hosted Auth warning: `auth_leaked_password_protection` / **Leaked Password Protection Disabled**. This is operational project configuration debt, not an RLS regression. Remediation: <https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection>.

Hosted/Vercel deployment remains **DEFERRED**. The accepted current demo topology is local Dashboard PC → cloud Supabase → installed customer phone.

## Integration PRs

- Customer PR #13 → `master`: COMPLETE and mergeable.
- Dashboard PR #12 → `main`: COMPLETE and mergeable.

Both have completed the implementation and applicable ADR-0004 validation gates. Final coordinated merge remains a repository operation, not an implementation blocker.

## Deferred product domains

Real payment/refunds, loyalty ledger/redemption, inventory, promotions/discount authority, tax/accounting, trusted reporting, branch-scoped operations/capacity, delivery and hosted production deployment/release operations remain future bounded tasks.
