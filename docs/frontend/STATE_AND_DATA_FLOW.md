# Customer State and Data Flow

Updated: 2026-08-12

## Catalogue

```text
Supabase get_catalogue()
 -> SupabaseCatalogueRepository
 -> catalogueProvider snapshot
 -> categories / featured / popular / menu providers
 -> Home + Menu + item detail

Admin DB mutation
 -> catalogue revision bump
 -> Supabase Realtime catalogue_revision event
 -> catalogueRevisionProvider
 -> catalogueProvider re-fetch
 -> UI reflects new DB state
```

Item detail uses the item's DB variants and compatible add-on IDs. Cart configuration uses those values, but local cart totals are not trusted order/quote authority.

Manual pull-to-refresh invalidates the full catalogue snapshot and re-fetches from Supabase.
