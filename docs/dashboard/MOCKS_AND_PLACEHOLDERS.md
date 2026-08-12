# POS/Admin Mocks and Placeholders Register

Updated: 2026-08-12

## No longer preview in Admin Menu

Admin Menu categories/items/prices/publication/availability/variants/add-on compatibility now come from the shared Supabase catalogue through the BFF. The conflicting dashboard preview catalogue is not promoted to production data.

## Still preview

POS cart/order/payment/tender/receipt flows, checkout-specific catalogue fixture wiring, loyalty, employee/terminal operations, branches, inventory, marketing, reporting and most settings remain preview until bounded backend tasks.

The remaining POS fixture must not be used as shared menu authority.
