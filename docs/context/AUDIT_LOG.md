# Audit Log

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
