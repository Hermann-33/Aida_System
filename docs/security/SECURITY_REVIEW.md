# AIDA Café Security Review

Updated: 2026-08-23

**Current verdict:** identity, catalogue, modifier, pricing, order/scheduling and fulfilment authority remain server-controlled. TASK-MENU-CUSTOMIZATION-001 adds catalogue-driven per-drink options and immutable option snapshots without moving trust into either frontend.

## Core controls

- Supabase Auth plus trusted `user_profiles`/`members` remain authoritative for identity and membership.
- Public signup cannot self-promote role/member/verification state.
- Catalogue authority remains Supabase Postgres/RLS/RPC.
- Dashboard privileged flows retain same-origin HttpOnly employee sessions and caller-JWT Supabase access.
- No service-role key or browser-readable employee bearer token is introduced.
- Staff remains excluded from Admin catalogue mutation; Admin/Owner remains the trusted catalogue-management role.

## Catalogue / modifier controls

Trusted catalogue resources include:

- `catalogue_items` / `catalogue_item_variants` / `catalogue_item_addons`;
- `catalogue_option_groups`;
- `catalogue_option_values`;
- `catalogue_item_option_values`.

`catalogue_items.is_drink` identifies products that consume option groups. The current reusable groups are Temperature and Sweetness.

Per-drink option label, price delta, availability, default and sort order are server data. Customer/POS UI state cannot make an unavailable option valid or change its authoritative price.

Compatible add-ons are normalized server links. Add-on category membership alone does not authorize selection.

Every active required drink group must have at least one available option and exactly one available default. The live closeout check found zero invalid required groups.

Public/authenticated catalogue-option reads are protected by RLS and the intended table grants. Mutation remains Admin/Owner-only through the trusted catalogue boundary.

## Order / pricing controls

Order clients submit IDs and intent only:

```text
itemId
variantId
optionValueIds[]
addOnIds[]
quantity
note
fulfillmentType / requestedPickupAt
clientRequestId for placement
```

Clients do not submit trusted product/option/add-on labels, option/add-on price deltas, unit prices, totals, customer/member identity, order status or payment state.

`quote_order(jsonb)` revalidates product/variant/add-on/option ownership and availability and derives price from the database.

Current deployed quote contract is `pricingVersion=2`:

```text
base + variant + options + compatible add-ons = authoritative unit price
```

When a legacy client omits a required option group, the live function resolves the configured available default. If a valid default does not exist, quote fails rather than trusting the client.

## Immutable option snapshots

Persisted order truth now includes:

- `order_lines.option_total_sen`;
- `order_line_options` selected group/value snapshots.

`order_line_options` records accepted group/value IDs, codes, labels and price deltas. Later Admin changes cannot rewrite historical order configuration or price.

Ordinary authenticated users have no direct `SELECT` grant on `order_line_options`; authorized order reads remain behind trusted snapshot functions/RLS behavior.

## Per-line isolation

Customer and POS cart identity/equivalence includes option/add-on selections. Two copies of the same product with different Temperature/Sweetness/add-ons remain independent lines/configurations.

This prevents a per-order/global add-on state from accidentally applying Boba/Oat Milk/etc. to unrelated drinks.

## Scheduling / idempotency controls

The accepted scheduling and placement controls remain unchanged:

- `clientRequestId` is required for idempotent placement;
- identical retry returns the existing order;
- same key with changed payload conflicts;
- scheduling is validated relative to server time/policy;
- immutable `prepareAt` and backend `scheduleState` remain server-owned;
- no timer/browser auto-transitions fulfilment state.

Customer-facing `Now` is only presentation. The wire/backend enum remains `asap`, so no security or compatibility boundary is weakened by the copy change.

## Employee / Dashboard boundary

Dashboard employee authentication still uses the ADR-0008 same-origin BFF:

- HttpOnly access/refresh cookies;
- trusted role/disabled-state validation;
- caller JWT forwarded to Supabase;
- no browser token persistence;
- no service-role use in Vite/browser code.

Admin preview remains read-only. A preview session cannot call privileged catalogue writes.

The menu-customization task did not introduce terminal/branch/shift authority or use preview fixtures to authorize live operations.

## UI safety / accessibility-relevant state

Customer unavailable options remain visible but disabled with explicit `Unavailable` messaging/semantics; selected choices use an explicit check indicator and are not represented only by color.

Dashboard modifier/Admin controls preserve labelled native radio/checkbox behavior, disabled semantics, focus-visible rules and reduced-motion handling.

These are interaction-safety properties, not a claim of full WCAG conformance.

## TASK-MENU-CUSTOMIZATION-001 verification

Detailed evidence:

`docs/context/MENU_CUSTOMIZATION_2026-08-23.md`

Live checks on 2026-08-23 confirm:

- 11 drink products, 4 add-ons;
- zero required drink groups with an invalid available-default configuration;
- all current Iced Drinks have Hot unavailable;
- public/authenticated quote execution remains granted;
- public/authenticated option-catalogue reads have intended grants + RLS;
- ordinary authenticated users have no direct `order_line_options` table read.

Client validation:

- Customer: analyze PASS, 55/55 tests PASS, secret scan PASS, exact-size UI/golden QA PASS;
- Dashboard: `npm ci` 0 vulnerabilities, lint/typecheck/build PASS, Vitest 129/129, Playwright 10/10, no task-related console errors.

No RLS/Auth/service-role/browser-token bypass was introduced by the final UI validation changes.

## Advisor state

Current Supabase security advisor reports one pre-existing WARN:

- `auth_leaked_password_protection` — **Leaked Password Protection Disabled**.

Remediation: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

No new task-related security WARN/ERROR remains.

Performance advisor findings are INFO-only unused indexes on the current small dataset, including recent customization FK-supporting indexes.

## Explicitly deferred authority

No trusted implementation currently exists for:

- real payment/refunds;
- loyalty earning/redemption;
- inventory depletion;
- promotions/discounts;
- tax/accounting/reporting;
- branch-scoped staff/order access;
- branch scheduling hours/capacity;
- terminal/sales-point authority;
- shift/cash reconciliation;
- delivery;
- hosted production operations.

Frontend presentation must not imply those domains are authoritative.

## 2026-09-09 future-work gating

The customer repository preserves future account-deletion/referral client code without enabling it in normal production builds.

- `AIDA_ENABLE_ACCOUNT_DELETION_DRAFT` defaults to false.
- `AIDA_ENABLE_REFERRAL_DRAFT` defaults to false.
- draft SQL remains outside canonical `supabase/migrations/`.
- no demo order-progress provider, Staff demo screen, or customer-visible test controls remain in the final integration.
- production order confirmation consumes persisted backend order state only.

This is source preservation only; it does not expand the currently deployed Supabase/Auth/order trust boundary.

