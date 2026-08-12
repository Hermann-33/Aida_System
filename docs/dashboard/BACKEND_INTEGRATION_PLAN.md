# POS/Admin Backend Integration Plan

Updated: 2026-08-13

## Admin catalogue — implemented source/data

Admin Menu now reads `/api/v1/admin/catalogue` and writes category/item mutations through `/api/v1/admin/catalogue/*`. The BFF validates the existing employee/admin HttpOnly session and calls Supabase catalogue RPCs with the caller JWT.

Admin can create categories/items and edit item name/SKU/category/type/description/base price/publication/availability/featured/bestseller/student eligibility/image/volume/prep route/sort, per-item variants and compatible add-ons.

Admin Menu no longer imports the preview catalogue/modifier fixtures.

## POS catalogue browsing

POS browsing now reads the same shared catalogue and has no runtime preview-catalogue fallback. The checkout workspace still computes preview totals and holds order/payment state locally. Do not treat those transaction paths as authoritative; replace them as part of quote/order/POS integration so prices and cart/order transitions are validated on a trusted boundary.
