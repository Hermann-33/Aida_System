# AIDA Café Project Brief

Updated: 2026-08-12

## Product purpose

AIDA Café is the ordering, membership, loyalty and café-operations system for City University Malaysia. The product combines a customer application with staff POS and administration workflows over one authoritative backend.

## System components

### Customer application

Repository: `Hermann-33/Aida_System`.

Flutter customer UI for authentication, home/promotions, rewards/vouchers, membership QR, menu browsing/configuration, favourites, cart, payment-method selection, order tracking/history and profile. It is currently a polished prototype still bound to mock/session-local data; no Flutter Supabase client is wired yet.

### POS/Admin dashboard

Repository: `Hermann-33/Aida_System-Dashboard`.

React 19 + TypeScript + Vite browser application with employee access, terminal enrolment, POS, orders, payments, member/QR lookup, loyalty, shifts, branches/locations, terminals, employees/access, menu/catalogue, inventory, marketing, reporting, audit, integrations and settings. It is currently a frontend preview using deterministic fixtures, component/module state and session storage; no Supabase SDK or durable transactional backend is connected.

### Shared backend

Supabase project **Aida System**, ref `eswovqxqzfevcdwwcmuh`.

The first database foundation is implemented: trusted profiles/application roles, members/server-issued member codes and student-verification records with RLS. Menu, quote/order, payment, loyalty, POS operational, inventory, marketing and reporting persistence remain to be built.

## Target users

- Students and other café customers.
- Baristas/cashiers/staff operating shared terminals and POS workflows.
- Managers/admin/owners operating catalogue, staff, inventory, rewards, marketing and reporting workflows.

## Shared product rule

The two frontends are views/controllers over one operational system. They must use the same identifiers, lifecycle definitions and backend rules. The customer app cannot invent a price/order/reward outcome that the POS does not recognise, and the dashboard cannot mutate data outside the same server-enforced contract.

## Current maturity

- Customer UI: prototype; mock/session-local business data.
- Dashboard UI: broad preview; fixture/local/session state with planned HTTP adapters.
- Supabase: real identity/membership foundation exists; not yet connected to either frontend.
- Full ordering/loyalty/operations: `PARTIAL` because authoritative shared persistence and operational integration are missing.

## Core business domains

Identity/session, membership/student verification, branches/sales points/terminals, employees/roles, catalogue/modifiers/pricing, cart/quote, orders/fulfilment/KDS, payments/refunds, loyalty/rewards/vouchers, inventory/recipes/wastage/transfers, promotions/marketing, reporting and immutable audit.

## Success criteria

AIDA succeeds when role-appropriate users complete their flows against one trusted backend with consistent IDs and state transitions, server-authoritative value calculations, secure ownership/branch/role access, audited privileged actions, usable failure/offline behavior, reproducible migrations, cross-client integration tests and current mirrored documentation.