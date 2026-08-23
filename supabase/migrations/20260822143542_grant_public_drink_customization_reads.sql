-- The public catalogue RPC exposes available per-item drink choices to anon
-- callers. RLS already scopes those rows; this grant completes the invoker
-- privilege required by the SQL-language get_catalogue() function.

grant select on public.catalogue_item_option_values to anon;
