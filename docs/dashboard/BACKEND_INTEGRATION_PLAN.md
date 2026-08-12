# POS/Admin Backend Integration Plan

Updated: 2026-08-12

## Admin catalogue — implemented source/data

Admin Menu now reads `/api/v1/admin/catalogue` and writes category/item mutations through `/api/v1/admin/catalogue/*`. The BFF validates the existing employee/admin HttpOnly session and calls Supabase catalogue RPCs with the caller JWT.

Admin can create categories/items and edit item name/SKU/category/type/description/base price/publication/availability/featured/bestseller/student eligibility/image/volume/prep route/sort, per-item variants and compatible add-ons.

Admin Menu no longer imports the preview catalogue/modifier fixtures.

## POS

The checkout workspace still contains preview transaction/catalogue wiring. Do not treat it as catalogue authority. Replace it as part of authoritative quote/order/POS integration so prices and cart/order transitions are validated together.
