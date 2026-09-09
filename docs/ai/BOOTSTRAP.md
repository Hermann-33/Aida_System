# AIDA Café Agent Bootstrap

Use this at the start of every substantial AIDA task.

## Bootstrap sequence

1. Read root `AGENTS.md`.
2. Read `docs/ai/context/CURRENT_STATE.md`.
3. Read `docs/ai/CONTEXT_MANIFEST.yaml`.
4. Inspect the current default-branch/PR state of every repository touched by the task.
5. Identify whether the task is customer-only, Dashboard-only, shared-backend, or cross-repository.
6. Read the matching contracts, ADRs, subsystem docs and reusable prompt.
7. Inspect current implementation before trusting historical notes.
8. If Supabase state matters and a connection is available, verify live state rather than inferring it from migrations or chat.
9. State genuine unknowns instead of filling them with assumptions.

## Project topology

- Customer app: `Hermann-33/Aida_System` — Flutter / Dart / Riverpod — default `master`.
- POS/Admin Dashboard: `Hermann-33/Aida_System-Dashboard` — React / TypeScript / Vite — default `main`.
- Shared backend: Supabase project `Aida System`, ref `eswovqxqzfevcdwwcmuh`, region `ap-southeast-1`.
- Canonical migration workspace: `Hermann-33/Aida_System/supabase/`.

## Trust boundary

Never accept frontend-computed or preview values as authority for identity, roles, catalogue pricing, modifier validity, order status, payment state, loyalty, inventory, branch/terminal scope, reporting or audit.

## End-of-task

After a logical project change:

1. Run the checks appropriate to the touched subsystem.
2. Inspect final diff/status.
3. Update `ACTIVE_CONTEXT.md`, `HANDOFF.md` and `AUDIT_LOG.md` when the task materially changes project state.
4. Update architecture/contracts/security/Supabase/frontend/dashboard docs when their facts changed.
5. Run `docs/ai/playbooks/CONTEXT_UPDATE_PROTOCOL.md`.
6. Keep mirrored governance docs synchronized across both repositories.
7. Do not claim a check passed unless it actually ran.
