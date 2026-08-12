# ADR-0006: Dual repositories over one shared backend

- **Status:** Accepted
- **Date:** 2026-08-12
- **Supersedes:** ADR-0001 only where ADR-0001 implied a project-wide single active frontend; ADR-0001 remains valid evidence for the customer repository/runtime.
- **Preserves:** ADR-0002, ADR-0003, ADR-0004, ADR-0005.

## Context

The POS/Admin dashboard source is now a separate repository, while the customer Flutter app remains in `Hermann-33/Aida_System`. Both products are intended to operate on the same customer/member, catalogue, order, loyalty and operational records. Creating independent backends or divergent IDs would make order fulfilment, QR lookup, pricing and loyalty inconsistent.

The first Supabase migrations already live under the customer repository.

## Decision

AIDA is one system with:

1. customer frontend repository `Hermann-33/Aida_System`;
2. POS/Admin frontend repository `Hermann-33/Aida_System-Dashboard`;
3. one shared Supabase/backend contract, project ref `eswovqxqzfevcdwwcmuh`.

Until superseded, the canonical database migration workspace remains `Aida_System/supabase/`. The dashboard repo must not create an independent migration history.

Both clients must use the same stable server-owned identifiers, money/business rules and lifecycle semantics. Backend changes assess both consumers even when SQL is committed to only the migration-owning repo.

## Consequences

- Customer and POS/Admin can be developed/deployed independently without data-model independence.
- Cross-cutting features require coordinated contract review and often coordinated task branches.
- Dashboard preview HTTP adapters may evolve or be replaced, but must map to the shared backend rather than establish a second authority.
- A future dedicated backend repository is allowed only through a superseding ADR and migration-ownership transition plan.

## Security consequences

Customer, staff and admin access share one trust model but different authorization scopes. RLS/server operations must distinguish owner access, operational role, branch scope and privileged actions. Service credentials remain outside both clients.