# ADR-0009 — Shared catalogue authority and revision signal

**Status:** Accepted
**Date:** 2026-08-12

## Context

The customer app and POS/Admin dashboard previously contained incompatible hardcoded catalogue fixtures. Prices, size deltas, add-ons, availability and merchandising flags therefore had no shared trusted authority. The product requires an Admin menu edit to become visible in the customer app without shipping privileged database credentials to either client.

## Decision

Supabase Postgres is the authoritative catalogue store. Canonical migrations remain in `Hermann-33/Aida_System/supabase/`.

The catalogue consists of categories, items, per-item variants, compatible add-on links, a singleton revision row and append-only audit evidence. Money is stored as integer sen. Database UUIDs, not frontend-generated IDs, are authoritative.

Public/customer reads use `public.get_catalogue()` under RLS. Admin/owner mutations use `public.save_catalogue_category(jsonb)` and `public.save_catalogue_item(jsonb)` as `SECURITY INVOKER` RPCs. The dashboard browser reaches those RPCs through the same-origin BFF and the authenticated administrator's Supabase JWT; no service-role credential is used.

Only `public.catalogue_revision` is added to the Supabase Realtime publication. Customer clients subscribe to that singleton signal and re-fetch the full RLS-filtered snapshot when its revision changes. Realtime payloads are invalidation signals, not catalogue authority.

The 16 menu entries previously hardcoded in the customer app are the initial production seed. The conflicting dashboard preview catalogue is not promoted to production data. Fake ratings and reward-bonus values are not catalogue fields.

## Consequences

- Admin changes to published catalogue data have one database source and invalidate the customer app menu.
- Size/variant price deltas and compatible add-ons are editable database data rather than Dart enums/category-name rules.
- Customer runtime has no hardcoded menu fallback; failures fail visibly.
- Unpublish/availability are explicit catalogue states; destructive item deletion is not the normal Admin workflow.
- POS transactional preview data remains a separate future order/POS integration concern and is not catalogue authority.
- Full feature completion still requires applicable client/toolchain and deployed end-to-end validation under ADR-0004.
