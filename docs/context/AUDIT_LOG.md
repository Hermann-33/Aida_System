# Audit Log

## 2026-08-13 — TASK-AUTH-004 — Customer Auth runtime + protected Admin access

**Verdict:** PARTIAL pending physical-device signup and a real trusted Admin identity.

Created coordinated branch `codex/task-auth-004-runtime-access-fix` in both repositories, stacked on `codex/fix-auth-signup-diagnostics`. Fresh Supabase evidence showed 0 Auth users and 0 admin/owner profiles; the existing Auth provisioning trigger/function and server-generated member-code boundary remained intact, and security advisor remained 0 lints.

Customer source now defaults to the active AIDA project URL and public publishable key while retaining `--dart-define` overrides, eliminating a fragile installed-build configuration dependency without embedding a secret. Unrecognized `AuthException` text is normalized/capped and surfaced so the next phone attempt exposes the actual hosted Auth reason instead of the prior generic fallback.

Dashboard local Vite/BFF now receives the same public project URL/publishable key by default with explicit environment override. Protected Admin routes remain fail-closed but preserve destination/session-error context when redirecting to `/admin/login`; Admin login explains the requirement, returns to the originally selected route after success, and distinguishes credential, authorization, disabled-account, configuration and network failures.

No RLS/member-directory authorization was weakened, no employee bearer token was exposed, and no service-role/secret key was shipped. A temporary exact-account Edge Function was deployed only to investigate supported Auth Admin bootstrapping; the available runtime could not invoke it, no user was created, and it was immediately superseded by an HTTP-410 disabled version. No direct `auth.users` SQL insert was used.

Required closure: pull/rebuild both local clients, run their normal suites, attempt signup on the physical phone and capture the new exact Auth response; then create/promote the intended trusted operator identity and verify Dashboard Members/Menu through the existing caller-JWT BFF/RLS path.

## 2026-08-13 — TASK-DEMO-ORDER-001 — Customer Flutter integration

**Verdict:** PARTIAL under ADR-0004; customer local integration is complete, but dashboard frontend and deployed real-identity cross-client E2E remain.

Integrated the live order/scheduling contract into Flutter on `codex/task-demo-order-001-order-scheduling-backend`. Added typed policy/selection/quote/snapshot/status models; Supabase RPC and owner-scoped Realtime repository boundaries; timezone-aware server-policy slots; retry-stable placement UUIDs; authoritative quote-before-place; clear-on-success/retain-on-failure cart behavior; real history/detail; and persisted status presentation without client timers. The active flow uses only `Pay at counter` and sends no trusted prices, totals, identity, order number or status.

Flutter 3.44.9 `pub get` and zero-issue `analyze` pass; full suite passes 40/40. Focused tests cover policy/quote mapping, trusted ASAP/scheduled serialization, server total use, lead/interval/horizon slots, idempotency reuse/new intent, cart clear/retain, all persisted statuses and Realtime-triggered refetch. Flutter 3.47 produced two toolchain-only golden diffs; actual/diff images were reviewed, all menu/QR content was correct, and matching-project 3.44.9 passed without updating baselines.

Read-only live evidence: project healthy; exact two order migrations present; 14 expected RLS-enabled public tables; order tables empty; five customer RPCs present; `orders` published to Realtime; FORCE RLS active; anon placement execute denied; authenticated execute granted; security advisor 0 lints. Performance advisor has unused-index INFO only on the empty/new dataset. No schema/data mutation or SQL regression rerun was necessary because backend state was unchanged. Production scans found no service-role/secret credential marker.

No approved customer/staff identity or configured public client key is available in this runtime, and this task was explicitly forbidden from creating identities/deploying. Therefore authenticated live placement and customer-place -> dashboard-transition -> Flutter-Realtime visible update remain unproven.

## 2026-08-13 — TASK-DEMO-ORDER-001 — Authoritative ordering and scheduled pickup backend

**Verdict:** PARTIAL for the end-user feature under ADR-0004; shared backend scope implemented and live-validated, frontend intentionally deferred to Codex.

Created the same task branch in both repos: `codex/task-demo-order-001-order-scheduling-backend`, stacked on each repo's AUTH-003 branch. No default branch was changed.

Applied live Supabase migrations `20260812182212_create_authoritative_orders_and_scheduling` and `20260812183029_index_order_foreign_keys`. Canonical customer-repo filenames were aligned to the exact live ledger versions without changing applied SQL.

Added FORCE-RLS order/scheduling tables, authoritative quote/order RPCs, immutable commercial snapshots, idempotent placement, server scheduling policy, versioned legal fulfilment transitions, append-only events, and `orders` Realtime publication. Scheduling begins with Asia/Kuala_Lumpur, 15-minute lead, 15-minute slots and 7-day horizon. Branch hours/capacity remain explicitly unmodeled.

Canonical `supabase/tests/order_integration.sql` passed transactionally. It proved forged totals are ignored, live catalogue pricing/variant/add-on compatibility is revalidated, invalid schedules fail, customer ownership/member derivation holds, idempotency works, direct customer order DML/status control fails, staff POS/queue access works, legal/stale/terminal status rules hold, and only admin can update schedule policy. Rollback cleanup left 0 Auth users/profiles/members/orders/lines/add-ons/events.

Security advisor returned 0 lints. Performance advisor initially identified four unindexed order foreign keys; a forward migration added covering indexes. Final performance findings are unused-index INFO only on the empty/new dataset.

Dashboard server-only implementation added `server/orderBff.ts`, Vercel/Vite API adapters, Vite route mounting and `server/orderBff.test.ts`. It retains the existing HttpOnly employee-session/caller-JWT model, requires same origin for POSTs, uses no service-role credential, and maps idempotency/status-version conflicts to HTTP 409. No React component or Flutter source file was changed by this backend task. An isolated strict TypeScript 5.8.3 compile of `server/orderBff.ts` passed under the repo's server compiler rules.

Accepted ADR-0010 and added the byte-identical `ORDER_AND_SCHEDULING_CONTRACT.md` in both repos. The remaining work is frontend integration: customer authoritative quote/ASAP-or-scheduled placement/history/Realtime status; dashboard POS authoritative quote/place and live order board/status controls; then full client toolchains and cross-client E2E.

No real payment authority was added. Frontends must use an explicit Pay-at-counter/unpaid demo path rather than claiming Card/E-wallet/Student Wallet processing.

## 2026-08-12 — TASK-MENU-001 — Shared catalogue/menu integration

**Verdict:** PARTIAL because client/toolchain/deployed E2E validation was deferred by user instruction.

Implemented a live shared catalogue in Supabase, seeded the 16 former customer menu hardcodes, normalized per-item variants and compatible add-ons, added audit/revision signaling, removed the customer runtime catalogue fixture and hardcoded size enum, wired Flutter to the shared snapshot + Realtime invalidation, and replaced Admin Menu preview data with caller-JWT BFF reads/mutations.

Database verification passed for seed integrity, public read, admin create/update, revision advance, audit evidence, customer write denial and unpublished-row hiding. Security advisor ended at 0 lints; performance advisor has only expected unused-index INFO.

The auth stack remains independently PARTIAL because its requested validation/deployment closure was skipped. POS checkout/order/payment preview behavior was not promoted to trusted business authority by this task.

## 2026-08-13 — AUTH-001/AUTH-002/TASK-MENU-001 — Customer validation closeout

**Verdict:** PARTIAL under ADR-0004.

Worked only in the customer repository on `codex/task-menu-001-shared-catalogue`; the unrelated dirty `master` checkout was preserved in a separate worktree. Draft PR stack remains #5 -> #6 -> #7.

Validation evidence:

- `flutter pub get` passed and exposed/repaired the stale lockfile for the already-pinned `supabase_flutter: 2.15.4` dependency.
- `flutter analyze` passed with no issues.
- Full `flutter test` passes 32/32. Each prior golden failure was inspected before updating: home and home-scrolled retained the intended content/layout with deterministic engine text/gradient/shadow raster changes; menu-selected also exposed a real underrepresentative test fixture, which was repaired to all 4 categories / 16 items before accepting the remaining raster change; membership-card's fresh actual contained the correct QR, proving the earlier missing-QR diagnostic was stale. Reviewed baselines now match the intentional rendering.
- ADR-0003 explicitly requires durable access to minimum offline QR material. Added a per-Supabase-user cache for only the server member ID/code, with logout/user-switch cleanup and tests; roles, verification, loyalty and pricing are not cached.
- Added and passed a focused provider test proving a Realtime revision event causes a second authoritative catalogue fetch.
- Production searches found no `item_size.dart`, `ItemSize`, exact migrated item-name literals, seeded catalogue price literals, or static `-100/0/+150` variant definitions. Production `MenuItem`/`MenuVariant` construction occurs only in the Supabase response mapper.
- Canonical `auth_membership_integration.sql` and `catalogue_integration.sql` both passed verbatim against project `eswovqxqzfevcdwwcmuh` inside rollback transactions.
- Independent cleanup returned zero synthetic Auth users, regression categories/items, and regression audit rows.
- Anonymous `get_catalogue()` evidence returned revision 1, 4 categories, 16 items, 27 variants, 27 compatible add-on links, and all Flutter adapter fields.
- Live public-table inventory contains only the expected 3 identity/member and 6 catalogue tables; RLS is enabled on all.
- Security advisor returned 0 lints. Performance advisor returned six `unused_index` INFO notices: four identity/member and two catalogue indexes.
- Compared every current repository migration to the stored live ledger statement. Names and SQL semantics match for all eight; only timestamp prefixes and non-semantic comments/formatting differ. Current live inventory is the expected nine RLS-enabled public tables, no public views/buckets, and only the revision table in Realtime. No migration or schema mutation was made.
- Reconciled the customer mirror to owner-supplied dashboard evidence at clean pushed commit `238e0ff211fe550f42ec4d4423724e3642282295`: lint/typecheck/85 tests/build and Playwright 6/6 pass; Admin and POS use the shared catalogue with no runtime preview catalogue fallback; the BFF returns 4/16/27; anonymous, cross-origin, and non-admin mutation defenses pass; security advisor is 0 lints. Preview checkout/totals/orders/payments remain untrusted.

Remaining gate: deployed/device customer Auth and deployed Admin-write -> customer UI Realtime E2E require approved real identities and deployment. That work belongs to TASK-AUTH-003.

## 2026-08-13 — TASK-AUTH-003 — Customer deployed/device E2E preflight

**Verdict:** PARTIAL under ADR-0004.

Created customer branch `codex/task-auth-003-deployed-e2e` from validated TASK-MENU-001 commit `7c7d91c2e3cf07e319dce1881c1322525881584f`. Flutter 3.44.7 reports Chrome, Edge, and Windows desktop as supported local runtimes; no Android emulator/physical device is available. A release Flutter web build compiled successfully with the live public Supabase configuration and rendered the real sign-in UI in Chromium.

The authoritative blockers are unchanged external prerequisites: live Supabase contains 0 Auth users, 0 confirmed users, 0 profiles, 0 members, and no admin/owner; GitHub exposes no customer/dashboard deployment; and the dashboard has no AUTH-003 branch, deployed URL, or mutation evidence. No approved identity credentials or mailbox path were supplied. Accordingly no identity was invented, no password-reset email was sent, and no direct database mutation was substituted for the deployed Admin flow.

Recorded catalogue baseline: revision 1; SKU `CF-SCL`; item ID `4287b72b-5c01-4c98-8f7b-2e4babfb1cd4`; 1290 sen; available/published. Anonymous calls to catalogue mutation and Admin member RPCs failed closed with HTTP 404. Scans found no service-role/secret marker in Flutter source/config or the release web build. Supabase retained 4 categories, 16 items, 27 variants, 27 add-on links and zero identity/member rows.

Exact human action: approve/provision one real customer mailbox identity and one trusted admin/owner identity; deploy the dashboard AUTH-003 stack; securely provide its URL and test credentials; then resume the running-client lifecycle and Admin mutation -> revision -> Flutter Realtime -> UI -> restored-state proof.
