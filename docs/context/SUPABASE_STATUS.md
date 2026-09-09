# Supabase Status

**Status date:** 2026-08-23
**Project:** Aida System
**Ref:** `eswovqxqzfevcdwwcmuh`
**Region:** `ap-southeast-1`

## Current live snapshot

Supabase remains the shared trusted backend for the Flutter customer app and React Dashboard/Admin/POS.

Current catalogue observation:

```text
catalogue revision         130
drink products              11
non-drink products           4
add-ons                      4
invalid required groups      0
Iced Drinks with Hot on      0
```

These counts are operational observations, not schema invariants.

## Applied migration tail

Current live migration history includes:

```text
20260812152607 create_shared_catalogue
20260812154805 harden_catalogue_rls_policies
20260812182212 create_authoritative_orders_and_scheduling
20260812183029 index_order_foreign_keys
20260820151421 add_scheduled_order_preparation_window
20260820214041 refresh_catalogue_product_images
20260820221139 replace_americano_catalogue_image
20260822135421 add_drink_customization_catalogue
20260822135602 integrate_drink_customizations_with_orders
20260822141814 harden_drink_customization_indexes_and_rls
20260822143542 grant_public_drink_customization_reads
```

Canonical executable migration files live only under the customer repository `supabase/migrations/` directory unless an accepted ADR changes ownership.

## Identity / employee boundary

Trusted identity remains Supabase Auth plus:

- `user_profiles.app_role` / `disabled_at` for employee/Admin authorization;
- `members` for customer membership identity.

Public signup cannot self-assign privileged roles/member codes. Dashboard privileged browser flows continue through the same-origin HttpOnly employee BFF using the authenticated caller JWT; no service-role/browser bearer-token architecture is introduced by menu customization.

## Catalogue authority

Core catalogue resources now include:

- `catalogue_categories`;
- `catalogue_items` including `is_drink`;
- `catalogue_item_variants`;
- `catalogue_item_addons`;
- `catalogue_option_groups`;
- `catalogue_option_values`;
- `catalogue_item_option_values`;
- `catalogue_revision`;
- `catalogue_audit_events`.

Supabase remains authoritative for item/category publication, availability, UUIDs, integer-sen prices, variant ownership, compatible add-ons and drink-option configuration.

Current standard drink groups:

```text
Temperature
- Hot
- Iced

Sweetness
- Regular
- Less sweet
- Least sweet
```

Per-item option configuration can override the customer label, price delta, availability, default and sort order. Every live required group currently has at least one available option and exactly one available default.

The existing `Iced Drinks` products currently expose Iced as available/default and Hot as unavailable.

Anonymous/public catalogue reads have the required table grants plus RLS for option catalogue data. Admin/Owner mutation remains behind `save_catalogue_item(jsonb)` and the trusted role boundary.

## Order / modifier authority

Current order resources include:

- `order_schedule_settings`;
- `orders`;
- `order_lines` including `option_total_sen`;
- `order_line_addons`;
- `order_line_options`;
- `order_events`.

`order_line_options` is an immutable historical snapshot surface for selected option group/value IDs, group/value labels and price deltas. Ordinary authenticated users have no direct table read grant; authorized order snapshots expose permitted data through the trusted order functions.

Order selection payloads may include:

```text
itemId
variantId
addOnIds[]
optionValueIds[]
quantity
note
```

`quote_order(jsonb)` remains authoritative for validation and pricing. The deployed implementation returns `pricingVersion=2` and computes authoritative unit price from base + variant + options + compatible add-ons.

When an older client omits a required option group, the live function definition resolves that group's configured available default. This provides rollout compatibility without moving authority into the client.

## Scheduling policy

Live policy verified 2026-08-23:

```text
timezone                 Asia/Kuala_Lumpur
schedule_enabled         true
minimum_lead_minutes     15
preparation_lead_minutes 15
slot_interval_minutes    15
maximum_advance_days     7
```

Scheduled operational classification remains server-owned through immutable `prepare_at`, `serverNow` and `scheduleState`; no menu-customization change altered the accepted fulfilment-state machine.

## Realtime

`supabase_realtime` continues to publish the intended mutable signals:

- `catalogue_revision` for catalogue invalidation/refetch;
- `orders` for authorized customer order invalidation/refetch.

Dashboard employee clients still use same-origin BFF polling/refetch rather than exposing the HttpOnly employee JWT to React.

## TASK-MENU-CUSTOMIZATION-001 verification

Live checks on 2026-08-23 proved:

- 11 drink products and 4 add-ons are present;
- no required drink group lacks an available default;
- no current `Iced Drinks` product has Hot enabled;
- anonymous can execute `get_catalogue()` and `quote_order(jsonb)`;
- authenticated can execute `quote_order(jsonb)`;
- anonymous/authenticated option-catalogue read grants are present;
- ordinary authenticated users have no direct `order_line_options` read grant.

The inspection connector itself uses a read-only database role and cannot impersonate `anon`, so final closeout did not create a synthetic production order merely to exercise quote/place. The deployed function definitions and executable client suites were inspected instead.

Detailed evidence: `docs/context/MENU_CUSTOMIZATION_2026-08-23.md`.

## Advisor state

Security advisor currently reports one pre-existing WARN only:

- `auth_leaked_password_protection` — Leaked Password Protection Disabled.

Remediation: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

No new security WARN/ERROR is attributed to TASK-MENU-CUSTOMIZATION-001.

Performance advisor findings are INFO-only unused indexes, including recent FK-supporting customization indexes on the small current dataset. Do not remove those indexes solely to clear an unused-index INFO result.

## Explicitly deferred backend authority

Still not implemented as trusted live domains:

- branch-specific opening hours/closures/capacity;
- branch-scoped staff/order visibility;
- terminal/sales-point authority;
- shifts/cash reconciliation;
- payment/refunds;
- loyalty earning/redemption;
- inventory depletion;
- promotions/discounts;
- tax/accounting/reporting;
- delivery;
- hosted production operations.

## 2026-09-09 preserved backend drafts

TASK-UI-REDESIGN-004 preserves useful account-deletion and referral/loyalty prototypes under `supabase/drafts/`.

These files are **not live Supabase state** and are deliberately outside `supabase/migrations/`:

- `supabase/drafts/20260826120000_add_customer_account_deletion.sql`;
- `supabase/drafts/20260828120000_add_referral_program.sql`;
- `supabase/drafts/tests/account_deletion_integration.sql`.

They must not be listed as applied migrations. Promotion requires a dedicated bounded backend task, a new canonical migration timestamp, replay/regression validation, RLS/security review and advisor checks.
