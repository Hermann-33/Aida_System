# POS/Admin Mocks and Placeholders Register

Updated: 2026-08-13

## No longer preview in Admin Menu or POS browsing

Admin Menu and POS browsing categories/items/prices/publication/availability/variants/add-on compatibility now come from the shared Supabase catalogue through the BFF. No runtime fallback to `PREVIEW_MENU`, `PREVIEW_CATEGORIES`, or `PREVIEW_MODIFIER_GROUPS` remains.

## Still preview

POS cart calculations/totals, order/payment/tender/receipt flows, loyalty, employee/terminal operations, branches, inventory, marketing, reporting and most settings remain preview until bounded backend tasks.

Shared catalogue reads do not make preview checkout, totals, orders or payments trusted business authority.
