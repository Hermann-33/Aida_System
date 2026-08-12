# Shared Backend Contract

Updated: 2026-08-12

This document defines project-level contract rules shared by the customer app and POS/Admin dashboard. It is not a complete schema specification.

## Contract ownership

- Trusted authority: shared Supabase/backend.
- Canonical migrations: `Hermann-33/Aida_System/supabase/` until superseded by ADR.
- Customer adapter and dashboard adapter are consumers of one contract.
- UI fixture/model shapes do not dictate database tables.

## Existing foundation

Current stable concepts already represented in Supabase:

- Auth user ID.
- `user_profiles` with trusted application role.
- `members` with server-issued stable `member_code`.
- `student_verifications` with trusted review state.

## Cross-client identifiers

Future contracts must provide stable server-owned identifiers for:

- branch and sales point;
- terminal;
- employee/staff identity and role assignment;
- menu category, item, variant, modifier group/option;
- quote;
- order, order line and receipt reference;
- payment/tender/refund reference;
- reward, voucher and loyalty event;
- inventory item/location/recipe/transfer;
- campaign/placement and audit event.

Clients may generate request correlation/idempotency keys where the contract permits, but not authoritative business identifiers.

## Money and pricing

- Store/transport money as integer minor units (sen) unless a later ADR supersedes this.
- Clients submit item/configuration IDs and quantities, not trusted prices/totals.
- Trusted quote/order logic validates current publication, availability, modifier compatibility, discount/promotion eligibility, tax/fees and final total.
- Purchased receipt snapshots preserve historical descriptions and prices even after catalogue changes.

## Identity and authorization

- Customer identity comes from Supabase Auth.
- Staff/admin authorization comes from trusted employee/application-role records, never hidden UI or editable metadata.
- Dashboard branch scope and global-manager exceptions are server-checked.
- Terminal credentials and manager approval are independently verifiable and audited.
- QR/member code is lookup material, not authentication.

## Order lifecycle

A later ADR/schema task must define explicit states and legal transitions. Customer can create/read own orders through controlled operations; POS/staff can perform only authorized operational transitions for permitted branch/location; admin actions such as void/refund/cancel require reason/approval/audit as defined by policy.

Client timers or local `ready` flags are never authoritative.

## Payment contract

AIDA does not accept raw payment credentials into ordinary app/database fields. Approved provider/device boundaries own sensitive payment handling. Shared backend stores the minimum trusted payment method/status/reference/amount/refund facts required for orders, reconciliation and reporting.

## Loyalty and vouchers

Balances derive from auditable events/ledger. Redemption, voucher issuance and voucher consumption are atomic and idempotent. Customer possession of a voucher/QR does not authorize consumption; staff operation and current order/eligibility rules are verified server-side.

## Catalogue contract

Customer and POS must consume the same published item/variant/modifier IDs and prices. Admin changes are privileged, validated and auditable. Availability/routing may be branch/sales-point scoped if the approved domain requires it. Client preview assumptions such as uniform size deltas or add-ons-as-items are not automatically schema decisions.

## Inventory contract

Inventory requires trusted units, location scope and an append-only/equivalently auditable movement model for receipt, depletion, count/adjustment, wastage and transfer. Local dashboard arrays cannot be promoted directly.

## Marketing/reporting/audit

Published campaign/creative/placement records require effective windows, audience/branch scope, versioning and audit. Reports derive from trusted operational records with defined timezone/business-day/refund semantics. Privileged mutations and sensitive lookups generate immutable/equivalently protected audit evidence.

## Time, idempotency and concurrency

- Business timestamps and expiry decisions use server time.
- Order create, redemption, voucher consumption, payment/refund recording and other replay-sensitive operations require idempotency.
- Concurrency-sensitive balances, stock and order transitions are atomic or explicitly locked/serialized.

## Realtime/offline

Realtime subscriptions must respect the same RLS/role/branch scope as reads. Cached/offline customer data may improve UX but never authorizes stale price, loyalty or order changes. Dashboard offline POS behavior requires a separate approved reconciliation design before production.

## Contract change gate

A breaking shared contract change is `PARTIAL` until:

1. migration/API/RPC behavior is reviewed;
2. security/RLS/role/branch tests pass;
3. both client adapters are assessed for compatibility;
4. shared docs/ADRs are synchronized in both repos.