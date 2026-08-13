# AIDA Café Architecture

Updated: 2026-08-14

```mermaid
flowchart LR
  C[Customer Flutter app] -->|Supabase Auth + customer RPCs| S[Shared Supabase]
  D[Dashboard React browser] -->|same-origin HttpOnly employee session| B[Dashboard BFF]
  B -->|caller JWT| S
  S --> A[Supabase Auth]
  S --> P[(Postgres + FORCE RLS)]
  S --> CR[catalogue_revision]
  S --> OR[orders Realtime]
  CR -->|invalidate + refetch catalogue| C
  OR -->|owner-scoped change + refetch order| C
  D -->|poll/refetch employee queue; no browser staff token| B
```

## Shared identity/member authority

Supabase Auth owns authentication. Trusted employee/admin authorization lives in `user_profiles.app_role` plus `disabled_at`; customer membership identity/code lives in `members`. Client metadata, route guards and browser storage do not grant trusted role/member authority.

The dashboard keeps privileged employee credentials behind the ADR-0008 same-origin BFF. The browser receives HttpOnly cookies, while the BFF validates the employee and forwards that caller JWT to Supabase. No service-role credential or browser-readable employee bearer token is part of the architecture.

## Shared catalogue

ADR-0009 makes Supabase Postgres the catalogue authority. `catalogue_categories`, `catalogue_items`, `catalogue_item_variants` and `catalogue_item_addons` store publication, price, availability and customization data. Money is integer sen.

Customer reads use `get_catalogue()` under RLS. Admin mutations use `save_catalogue_category(jsonb)` and `save_catalogue_item(jsonb)` through the dashboard BFF with the administrator caller JWT.

`catalogue_revision` is the catalogue invalidation signal. Customer clients re-read authoritative data after a revision change.

## Authoritative order and scheduling boundary

ADR-0010 makes the same Supabase project authoritative for customer and POS order pricing, persistence, scheduling and fulfilment status.

```mermaid
flowchart TD
  CC[Customer cart selections] --> Q[quote_order]
  PC[POS cart selections] --> QB[Dashboard order BFF]
  QB --> Q
  Q --> CAT[(Shared catalogue)]
  Q --> V[Validated server quote]
  V --> CO[place_customer_order]
  V --> PO[place_pos_order]
  CO --> O[(orders + immutable line snapshots)]
  PO --> O
  O --> E[(order_events)]
  STAFF[Staff dashboard] -->|caller JWT via BFF| T[transition_order_status]
  T --> O
  O --> RT[orders Realtime]
  RT --> CUSTOMER[Customer refetches authorized order]
```

Clients submit IDs, quantities, notes and fulfilment intent only. They are not authority for product names, prices, totals, customer/member identity, order numbers, status or payment state. `quote_order(jsonb)` revalidates the current published/available catalogue, item variants and compatible add-ons before deriving integer-sen totals.

`orders`, `order_lines` and `order_line_addons` persist server-owned commercial snapshots. Placement is idempotent through `clientRequestId`. Staff-only fulfilment transitions use an expected `statusVersion` to prevent silent concurrent overwrites and append `order_events` evidence.

The current scheduled-pickup policy is a single-café policy: `Asia/Kuala_Lumpur`, 15-minute minimum lead, 15-minute slots and seven-day horizon. Branch hours, closures, capacity and branch-scoped queues are not authoritative yet and remain deferred.

## Realtime boundary

`supabase_realtime` currently publishes:

- `catalogue_revision` — invalidation only;
- `orders` — owner/staff-authorized order-header changes.

Immutable order lines/add-ons are not separately published. Customer clients subscribe with their Supabase session and refetch the full authorized order after a header change.

The dashboard employee token remains HttpOnly, so React must not expose it merely to open a Supabase Realtime connection. The current secure demo integration should refetch/poll the same-origin order BFF for the employee queue and invalidate immediately after local status/place mutations. A future server-side event bridge can replace polling if required.

## Explicitly separate authority

Real payment settlement/refunds, loyalty earning/redemption, inventory depletion, discounts/promotions, tax/accounting, revenue reporting, branch scheduling/capacity and delivery remain separate trusted backend domains. They must consume authoritative orders/payment state rather than frontend-computed totals.

## Android release boundary

The customer production manifest declares `android.permission.INTERNET` because Auth, member/profile, catalogue, orders, and Realtime require TLS network access. The committed Android build uses AGP 8.9.1 with Gradle 8.11.1 and Flutter's compatibility properties; release packaging has been reproduced in an independent clean worktree. Flutter contains only the project URL and public publishable key, never a service-role/secret credential.
