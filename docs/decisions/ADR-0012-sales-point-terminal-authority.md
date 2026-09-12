# ADR-0012 — Trusted sales-point and terminal authority

- **Status:** Accepted
- **Date:** 2026-09-10
- **Task:** `TASK-OPS-002`
- **Preserves:** ADR-0006, ADR-0008, ADR-0010, ADR-0011

## Context

ADR-0011 established branch identity and employee branch scope, but live POS orders still had no trusted sales-point or terminal identity. Dashboard preview fixtures contained terminal/location concepts that could not be used as commercial or audit authority.

AIDA needs a physical POS origin that cannot be forged by React state before shifts, cash reconciliation, inventory attribution, reporting or payment-device integrations can be trusted.

## Decision

Supabase is authoritative for sales points and terminals under branches.

### Topology

```text
branch
  -> sales point
      -> terminal
          + authenticated employee branch scope
          -> POS order
```

`public.sales_points` owns stable server UUIDs, branch relationship, code/name and active state.

`public.terminals` owns stable server UUIDs, sales-point relationship, code/name, activation/revocation state and last-seen timestamp.

The initial physical topology is:

```text
BR-MAIN — Main Café
  SP-MAIN — Main Counter
    POS-MAIN-01 — Main Counter POS 1
```

No preview-only sales point, printer, KDS or payment-device status is promoted into trusted data.

### Terminal activation

An Admin/Owner issues a short-lived, single-use terminal activation code.

- the code expires after 15 minutes;
- the stored code is bcrypt-hashed;
- an authenticated employee must redeem it;
- ordinary staff must be authorized for the terminal branch;
- possession of the code is not employee authentication.

Successful activation generates a high-entropy terminal credential. Supabase stores only a SHA-256 hash of that credential.

The Dashboard BFF places the plaintext credential in an HttpOnly, `SameSite=Lax` cookie (and `Secure` on HTTPS). React never reads or persists the reusable terminal credential.

Terminal resolution revalidates:

- employee authentication and enabled employee role;
- current employee branch scope;
- credential expiry/revocation;
- active terminal;
- active sales point;
- active branch.

Removing a staff branch assignment therefore invalidates that staff member's use of the terminal immediately without requiring terminal revocation.

### POS placement

The previous credentialless `place_pos_order(jsonb)` signature is not executable by client roles.

Trusted POS placement uses:

```text
place_pos_order(jsonb, terminal_credential)
```

The BFF forwards the employee caller JWT plus the HttpOnly terminal credential server-to-server. The browser order payload continues to carry item/configuration intent only and does not supply trusted `branchId`, `salesPointId` or `terminalId`.

The backend resolves and validates the operational topology before persistence.

### Immutable attribution

New terminal-origin POS orders persist:

```text
branch_id
sales_point_id
terminal_id
sales_point_code_snapshot
sales_point_name_snapshot
terminal_code_snapshot
```

Order snapshots expose branch, sales-point and terminal identity. The attribution is immutable with the order's other trusted persisted fields.

Customer orders remain terminal-free. Historical orders are not retroactively assigned fabricated sales-point or terminal data.

### Admin surfaces

Live Admin Locations, Terminals and Employees may display/mutate only trusted capabilities backed by current RPC contracts.

Phase 1 does not claim authority for:

- employee Auth-user creation, password/PIN management or role mutation;
- shifts/cash;
- printer/KDS/payment-device health;
- inventory pools;
- branch hours, closures or slot capacity.

## Security consequences

- operational tables use RLS + FORCE RLS;
- terminal credential and one-time-code tables live in the private schema;
- ordinary client roles have no direct topology-table mutation grants;
- branch and assignment writes remain RPC/BFF-only;
- Admin/Owner controls topology mutation and activation-code issuance;
- the reusable terminal secret is never browser-readable;
- POS placement fails closed without both employee and terminal authority.

## Apple App Review consequences

This decision adds no customer iOS permission, tracking SDK, payment mechanism or customer personal-data collection.

It does not change AIDA's physical-goods payment rule and introduces no StoreKit/In-App Purchase dependency.

No Phase 1 App Store blocker is introduced. The pre-existing requirement to promote in-app customer account deletion before submission remains tracked for Phase 3.

## Migration ownership

Canonical executable migrations remain in `Hermann-33/Aida_System/supabase/migrations/`.

Live Phase 1 migrations:

```text
20260910023510 create_operational_sales_points_and_terminals
20260910023552 harden_operational_topology_rls_and_indexes
20260910040814 revoke_direct_branch_mutation_grants
20260910041057 enforce_terminal_branch_scope_on_resolution
```

Both repositories must keep this ADR and related shared governance/contracts synchronized.
