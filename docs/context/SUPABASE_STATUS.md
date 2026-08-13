# Supabase Status

**Status date:** 2026-08-14
**Project:** Aida System
**Ref:** `eswovqxqzfevcdwwcmuh`
**Region:** `ap-southeast-1`

## Identity/membership

Existing identity/member objects remain live with forced RLS:

- `user_profiles`
- `members`
- `student_verifications`

Trusted role helpers and admin/owner member-directory functions remain unchanged.

Current live identity baseline after user-approved physical/device validation:

- Auth users: 9
- profiles: 9
- members: 6
- owners: 1
- admins: 1
- staff: 1

These are dated operational counts, not schema invariants. Physical customer signup created trusted Auth/profile/member rows, and the new member appeared through Dashboard Members.

## Catalogue — TASK-MENU-001

Live catalogue objects remain:

- `catalogue_categories`
- `catalogue_items`
- `catalogue_item_variants`
- `catalogue_item_addons`
- `catalogue_revision`
- `catalogue_audit_events`

Seed baseline remains:

- 4 categories
- 16 items
- 27 variants
- 27 compatible add-on links
- catalogue revision 15 at the 2026-08-14 baseline

The revision advanced through real Admin activity. User validation proved an Owner price mutation became visible in the installed customer app through catalogue revision invalidation and authoritative refetch.

Catalogue authority and regression behavior are unchanged by TASK-DEMO-ORDER-001.

## Orders and scheduling — TASK-DEMO-ORDER-001

Canonical repository migrations are now aligned exactly to their live ledger versions:

1. `20260812182212_create_authoritative_orders_and_scheduling.sql`
2. `20260812183029_index_order_foreign_keys.sql`

Live tables:

- `order_schedule_settings`
- `orders`
- `order_lines`
- `order_line_addons`
- `order_events`

All five have RLS enabled and FORCE RLS.

Live public RPC contract:

- `get_ordering_policy()`
- `quote_order(jsonb)`
- `place_customer_order(jsonb)`
- `place_pos_order(jsonb)`
- `get_order(uuid)`
- `get_my_orders(integer)`
- `list_orders(text[], integer)`
- `transition_order_status(uuid,text,bigint,text)`
- `save_ordering_policy(jsonb)`

Private SECURITY DEFINER helpers perform narrowly scoped controlled persistence behind SECURITY INVOKER public entrypoints with explicit caller/role checks. Ordinary authenticated clients have no direct INSERT/UPDATE grants on order commercial tables.

Current scheduling singleton:

```text
timezone                 Asia/Kuala_Lumpur
schedule_enabled         true
minimum_lead_minutes     15
slot_interval_minutes    15
maximum_advance_days     7
```

Branch-specific opening hours/closures/capacity are not modeled in the current schema.

Current retained order state after regression rollback:

- orders: 0
- order lines: 0
- order-line add-ons: 0
- order events: 0

The numeric identity sequence may contain gaps after transactional regression because PostgreSQL sequences are non-transactional; order-number uniqueness/authority is unaffected and no synthetic order row remains.

## Realtime

`supabase_realtime` currently publishes exactly the two intended mutable signals:

- `catalogue_revision`
- `orders`

Catalogue clients re-fetch the full catalogue after revision change. Order clients re-fetch an authorized full order snapshot after an order-header change. Immutable order lines/add-ons are not separately published.

## TASK-DEMO-ORDER-001 validation

`supabase/tests/order_integration.sql` passed transactionally against the live project and rolled back all synthetic users/orders.

Customer closeout rechecked the live project read-only on 2026-08-14: all intended order RPCs exist; `orders` remains in `supabase_realtime`; all 14 intended public tables have RLS and FORCE RLS; ordinary authenticated clients have no direct order DML; and all order tables remain empty. Performance advisor contains only unused-index INFO notices expected before order traffic.

It proved:

- anonymous authoritative quote access;
- no anonymous placement/status capability;
- no direct authenticated order-table DML;
- forged client price/total fields ignored;
- live `CF-SCL` Medium + Oat Milk price resolution;
- incompatible add-on rejection;
- past schedule rejection;
- customer scheduled placement with trusted member derivation;
- immutable line/add-on snapshots;
- idempotent retry and key-reuse conflict;
- customer owner-scoped history;
- customer status-mutation denial;
- staff queue and POS guest order creation;
- versioned legal status transitions;
- stale/illegal transition rejection;
- admin-only scheduling policy update.

Security advisor on 2026-08-14: one WARN, **Leaked Password Protection Disabled**. Remediation: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

This Auth setting was not changed during closeout and must not be reported as zero lints.

Performance advisor initially identified four unindexed new foreign keys. The second forward migration added covering indexes. Final performance findings are `unused_index` INFO only, which is expected on a new/empty order dataset; there are no remaining unindexed-FK findings.

## Historical migration-ledger drift

The pre-order identity/catalogue migrations retain the previously documented historical filename/live-version differences:

| Repository version | Live version | Name |
|---|---|---|
| `20260811101100` | `20260811101525` | `create_identity_membership_foundation` |
| `20260811102200` | `20260811101620` | `harden_foundation_role_helpers` |
| `20260811102700` | `20260811101641` | `optimize_foundation_rls_policies` |
| `20260812191500` | `20260812112337` | `integrate_customer_auth_member_directory` |
| `20260812192500` | `20260812112457` | `fix_signup_member_code_generation` |
| `20260812195500` | `20260812113040` | `make_admin_member_directory_security_invoker` |
| `20260812231500` | `20260812152607` | `create_shared_catalogue` |
| `20260812235000` | `20260812154805` | `harden_catalogue_rls_policies` |

Those eight were already proven semantically equivalent and are not schema drift. Do not rewrite applied historical migrations.

For TASK-DEMO-ORDER-001, the migration source was committed before live application and then the repository filename was aligned to the exact version returned by the migration ledger without changing SQL contents. The order migration ledger and canonical filenames therefore match exactly.

## Current public schema inventory

Current active public base tables consist of:

- 3 identity/member tables
- 6 catalogue tables
- 5 order/scheduling tables

Total: 14 public base tables, all within the accepted shared-backend architecture.

Legacy ledger rows describing older removed objects remain historical ledger evidence; they are not current live public schema authority.
