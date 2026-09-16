-- Phase 8 local-regression fixture only.
-- The clean canonical database intentionally has no inventory administration data.
-- Seed one synthetic inventory item so the reporting regression can author an
-- inventory movement through the trusted Phase 5 RPC. This database is disposable
-- and is destroyed at the end of the workflow.

insert into public.inventory_items (sku, name, base_unit, is_active)
values ('P8-REPORT-STOCK', 'Phase 8 Reporting Stock', 'unit', true)
on conflict (sku) do nothing;
