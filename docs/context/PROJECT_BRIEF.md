# AIDA Café Project Brief

Updated: 2026-08-13

## Product purpose

AIDA Café is the ordering, membership, loyalty and café-operations system for City University Malaysia. The product combines a customer application with staff POS and administration workflows over one authoritative backend.

## System components

### Customer application

Repository: `Hermann-33/Aida_System`.

Flutter customer UI for authentication, home/promotions, rewards/vouchers, membership QR, menu browsing/configuration, favourites, cart, payment-method selection, order tracking/history and profile. Supabase Auth/member reads, minimum per-user offline member-code caching, and the shared catalogue are wired on the current stack. Loyalty, rewards, offers/promotions, profile writes, cart/quote/order/payment and history remain mock, local, or incomplete.

### POS/Admin dashboard

Repository: `Hermann-33/Aida_System-Dashboard`.

React 19 + TypeScript + Vite browser application with employee access, terminal enrolment, POS, orders, payments, member/QR lookup, loyalty, shifts, branches/locations, terminals, employees/access, menu/catalogue, inventory, marketing, reporting, audit, integrations and settings. Admin and POS catalogue browsing use the shared Supabase catalogue through the same-origin BFF; preview checkout/totals/orders/payments and most other operations still use fixtures, component/module state, or session storage.

### Shared backend

Supabase project **Aida System**, ref `eswovqxqzfevcdwwcmuh`.

The identity/member foundation and shared catalogue are implemented with RLS. Quote/order, payment, loyalty, POS operational, inventory, marketing and reporting persistence remain to be built.

## Target users

- Students and other café customers.
- Baristas/cashiers/staff operating shared terminals and POS workflows.
- Managers/admin/owners operating catalogue, staff, inventory, rewards, marketing and reporting workflows.

## Shared product rule

The two frontends are views/controllers over one operational system. They must use the same identifiers, lifecycle definitions and backend rules. The customer app cannot invent a price/order/reward outcome that the POS does not recognise, and the dashboard cannot mutate data outside the same server-enforced contract.

## Current maturity

- Customer UI: Supabase Auth/member and catalogue partially integrated; remaining business domains are mock/session-local.
- Dashboard UI: shared catalogue browsing/administration integrated; broader operations remain fixture/local/session preview.
- Supabase: real identity/membership and shared catalogue foundations exist; customer reads them and the stacked dashboard Admin catalogue uses caller-JWT BFF/RPC access.
- Full ordering/loyalty/operations: `PARTIAL` because authoritative shared persistence and operational integration are missing.

## Core business domains

Identity/session, membership/student verification, branches/sales points/terminals, employees/roles, catalogue/modifiers/pricing, cart/quote, orders/fulfilment/KDS, payments/refunds, loyalty/rewards/vouchers, inventory/recipes/wastage/transfers, promotions/marketing, reporting and immutable audit.

## Success criteria

AIDA succeeds when role-appropriate users complete their flows against one trusted backend with consistent IDs and state transitions, server-authoritative value calculations, secure ownership/branch/role access, audited privileged actions, usable failure/offline behavior, reproducible migrations, cross-client integration tests and current mirrored documentation.
