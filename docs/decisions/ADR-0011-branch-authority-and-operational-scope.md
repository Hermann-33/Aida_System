# ADR-0011 — Trusted branch authority and operational scope

- **Status:** Accepted
- **Date:** 2026-09-10
- **Task:** `TASK-OPS-001`
- **Preserves:** ADR-0006, ADR-0008, ADR-0010

## Context

AIDA's accepted order architecture originally used one global café scope. That was sufficient for the first end-to-end ordering tranche, but it left branch identity, employee location scope, future terminal ownership, inventory pools, scheduling capacity and reporting without a trusted parent entity.

The Dashboard already contained preview-only branch and sales-point screens, while live `orders` had no branch foreign key and ordinary staff could read and transition the global queue.

Building terminals, shifts, inventory or branch-aware reporting on top of that global assumption would create incompatible authority later.

## Decision

Supabase becomes authoritative for café branch identity and employee operational branch scope.

### Branch directory

`public.branches` owns stable server UUIDs, branch code/name, timezone, contact/location text, active state and the single active default-branch designation.

The initial trusted branch is:

```text
BR-MAIN — Main Café
timezone: Asia/Kuala_Lumpur
active: true
default: true
```

A partial unique index enforces at most one default branch and the schema requires a default branch to be active. Admin/Owner mutation occurs through trusted RPCs; public/customer access is read-only and active-only.

### Employee scope

`public.employee_branch_assignments` is the trusted mapping between employee profiles and branches.

- ordinary `staff` may operate only assigned branches;
- `admin` and `owner` remain global operational roles in this tranche;
- a staff role must have at least one assignment;
- employee role promotion with no existing assignment is compatibility-seeded to the current default branch;
- demotion to `customer` removes employee branch assignments.

Browser route state and preview fixtures are not branch authorization.

### Order branch identity

Every order has immutable `orders.branch_id`.

Existing orders are backfilled to the initial default branch. Existing customer and POS request payloads remain compatible: until explicit branch selection is introduced, placement resolves to the active default branch server-side.

Order snapshots expose:

```text
branchId
branch {
  id
  code
  name
  timezone
}
```

Staff order reads and fulfilment transitions are branch-scoped. Customer ownership rules remain unchanged.

### Compatibility boundary

This ADR does **not** introduce client-supplied trusted branch authority.

The current customer app and POS can continue placing orders without `branchId`. A later coordinated contract task may add explicit branch selection, but the backend must validate the requested branch, availability and actor scope before persistence.

## Deferred from this ADR

The following remain separate bounded tasks:

- branch opening hours, closures and per-slot capacity;
- customer branch selector / pickup-location UX;
- POS selected-branch workflow;
- sales points and terminal/device authority;
- shifts and cash reconciliation;
- branch inventory pools and stock movements;
- branch-specific catalogue availability/pricing;
- branch-scoped reporting/accounting;
- delivery.

## Security consequences

- public tables use RLS + FORCE RLS;
- public clients receive read-only branch data only;
- branch mutation and employee assignment mutation require Admin/Owner authority;
- no service-role credential is introduced into either client;
- ordinary staff no longer receive global order visibility solely because they are staff;
- order branch identity becomes part of the immutable commercial/operational snapshot.

## Migration ownership

Canonical executable migrations remain in `Hermann-33/Aida_System/supabase/migrations/`.

Live migrations:

```text
20260910014434 create_branch_location_authority
20260910014457 index_employee_branch_assignment_actor
```

Both repositories must keep this ADR and the related shared contracts/context synchronized.
