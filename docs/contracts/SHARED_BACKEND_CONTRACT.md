# Shared Backend Contract

Updated: 2026-09-12

## Authority

Supabase Auth/Postgres/FORCE-RLS plus controlled RPC/BFF operations are authoritative. Canonical executable Supabase migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

Neither frontend is authority for authenticated identity, trusted role/disabled state, membership identity, employee branch scope, branch/sales-point/terminal identity, terminal credential validity, shift state, cash reconciliation, catalogue/pricing, order totals/status, tender/payment classification, privacy preferences or account-deletion/anonymization state.

Dashboard privileged flows remain behind the same-origin BFF with HttpOnly employee and terminal credentials and caller-JWT forwarding. No service-role secret or browser-readable reusable employee bearer token/terminal credential is used. Preview fixtures never become backend authority.

## Identity and authorization

- Supabase Auth identity is trusted authentication identity.
- `user_profiles.app_role` plus `disabled_at` is trusted application authorization state.
- `members` is trusted customer membership state.
- `employee_branch_assignments` is trusted ordinary-staff operational scope.
- signup cannot self-assign employee/Admin role, member code, verification outcome or branch scope.
- employee identities remain distinct from customer/member records.
- customer-editable Auth metadata is not authorization authority.

## Catalogue and commercial order contract

Supabase owns catalogue IDs, publication/availability, modifier compatibility, integer-sen prices, authoritative quote totals and persisted commercial snapshots. Clients submit selection/fulfilment intent only.

Persisted order history includes `orders`, `order_lines`, `order_line_addons`, `order_line_options` and `order_events`. `clientRequestId` supplies idempotency. Fulfilment status changes are optimistic-versioned and server-authorized.

Customer order placement derives customer/member identity from `auth.uid()` plus trusted active membership. POS placement derives operational topology from the server-held terminal credential and caller employee scope.

## Phase 1 operational topology contract

Trusted chain:

```text
branch -> sales point -> terminal -> employee branch scope -> POS attribution
```

A sales point belongs to one branch and a terminal to one sales point. Manager-issued one-time enrolment activates a terminal. Credential resolution validates terminal/revocation, active topology, caller employee state and branch scope. Browser-supplied location IDs cannot replace terminal credential authority. Accepted branch/sales-point/terminal attribution is immutable.

## Phase 2 shift and cash contract

Trusted chain:

```text
terminal + employee -> shift -> POS order / cash ledger
```

Contracts:

- shift lifecycle `open | locked | closed` with optimistic versioning;
- one live open/locked shift per terminal and per operator;
- opening float and cash movement amounts are integer sen;
- `cash_movements` is append-only;
- expected cash = opening float + cash-in - cash-out + trusted cash-paid POS sales;
- employee submits actual count; backend derives variance;
- non-zero variance close requires Admin/Owner;
- new POS placement requires the caller's matching open shift;
- persisted `shift_id`, tender and payment state are protected from ordinary mutation;
- Phase 2 tender classification is `cash | unpaid` only;
- cash-paid cancellation remains blocked until trusted refund authority exists;
- customer orders remain shift-free and unpaid.

External processor capture, settlement and refunds are not implied by Phase 2.

## Phase 3 customer privacy/account contract

Trusted resources:

```text
public.customer_privacy_preferences
public.orders.customer_deleted_at
public.get_my_privacy_preferences()
public.save_my_privacy_preferences(boolean, boolean)
public.delete_own_account()
```

### Privacy preferences

`customer_privacy_preferences` is FORCE-RLS protected and direct authenticated table grants are revoked. Public RPCs expose only the caller's preference record. Marketing notifications default off; transactional notifications default on. Preference state does not itself request OS notification permission or deliver notifications.

### Whole-account deletion

`delete_own_account()` accepts no target user ID. The public wrapper is `SECURITY INVOKER`. The private privileged helper is caller-bound to `auth.uid()`, requires a trusted customer profile, and cannot be used by staff/Admin to self-delete through the customer path.

Deletion remains available to a trusted customer profile even when disabled and does not depend on a healthy active member row.

Before deleting the Auth user, the backend:

1. identifies only the caller's customer orders;
2. clears retained customer-authored `order_lines.note` and `order_events.reason`;
3. performs the one permitted internal customer anonymization transition;
4. nulls `customer_user_id`, `member_id` and customer `created_by_user_id`;
5. sets `customer_deleted_at`;
6. verifies retained order identity/free text no longer references the caller;
7. deletes the caller from `auth.users`, cascading owned profile/member/student/preference/session state through existing FKs/ownership.

No synthetic permanent deleted-customer Auth user is created.

Retained anonymized transaction/audit facts may include order number, catalogue snapshots, quantities, prices/totals/currency, fulfilment/status timestamps, branch/sales-point/terminal/shift attribution and tender/payment facts. POS/staff audit identity is preserved.

Already-issued JWTs may remain cryptographically valid until expiry, so personalized RPCs continue requiring trusted current profile/member state. An anonymized retained order is no longer owned by the deleted subject.

## Scheduling and Realtime

Scheduling policy, `prepareAt`, server time and schedule classification remain server-owned. Branch-specific opening hours/closures/capacity and explicit customer pickup branch are deferred.

Customer Realtime is authorized invalidation followed by authoritative refetch. Dashboard employee clients continue through same-origin BFF polling/refetch because the employee bearer token is HttpOnly.

## Customer app privacy/App Store contract

The customer app exposes in-app whole-account deletion, privacy preferences, Privacy Policy, Terms and Support. Public/guest-capable catalogue and legal/support surfaces do not require unnecessary authentication. Membership identity/QR, profile mutation, customer order placement/history, student verification, account preferences and account deletion remain authenticated-only.

Phase 3 adds no camera, photo-library, location, contacts, microphone, Bluetooth, calendar/reminder, ATT/tracking or notification authorization request and no tracking/advertising SDK. AIDA sells physical café goods, so StoreKit/IAP is not the payment path.

## Security invariants through Phase 3

- no authorization trusts customer-editable metadata or preview fixtures;
- no direct client mutation of trusted topology/shift/cash/privacy tables where controlled RPC authority is required;
- private definer helpers bind actor identity and expose minimal public wrappers;
- customer self-deletion cannot target another user;
- retained customer transactions lose stable customer/member/Auth identity;
- retained customer-authored order free text is scrubbed on deletion;
- staff/POS actor identity is not weakened by customer deletion;
- no service-role/secret credential in Flutter/browser code;
- employee JWT and terminal credential remain HttpOnly in Dashboard live flows.

## Validation and governance

Phase 3 implementation head `10ca26a776994e59b76f8afbd7227e296270cd68` passed Backend database audit #90 and Customer release audit #182. Dashboard Phase 3 runtime is unchanged; pre-closeout Dashboard CI #66 passed. Full Phase 3 evidence is in `docs/context/PHASE_3_CUSTOMER_PRIVACY_ACCOUNT_CLOSEOUT_2026-09-12.md`.

Phases 1–3 are `COMPLETE` but draft/unmerged. Implementation is stopped for `docs/context/PHASE_1_3_ASTRA_AUDIT_BOUNDARY_2026-09-12.md`, currently `PARTIAL` until Astra review is executed/accepted. Phase 4 is blocked.

## Deferred authority

- branch hours/closures/capacity and explicit pickup branch;
- inventory/recipes/depletion;
- loyalty/rewards/vouchers;
- promotions/discounts;
- reporting/tax/accounting export;
- external payment capture/refunds/processor settlement;
- employee Auth-user/credential lifecycle;
- printer/KDS/payment-device integrations;
- notification/marketing delivery provider;
- delivery/deployment-heavy production infrastructure.