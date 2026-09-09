# AIDA Café Session Bootstrap

Updated: 2026-09-10

This file is kept as a compatibility entry point for older instructions.

The canonical fresh-agent context now lives under `docs/ai/`, modeled after the durable context/prompt structure used by Cheaters Market Docs.

## Start here

Read:

1. `docs/ai/BOOTSTRAP.md`
2. `docs/ai/context/CURRENT_STATE.md`
3. `docs/ai/CONTEXT_MANIFEST.yaml`

For a copy/paste prompt into a fresh ChatGPT, Codex, Claude, Astra, or similar session, use:

- `docs/ai/prompts/FRESH_CHAT_BOOTSTRAP.md`

Task-specific reusable prompts are indexed at:

- `docs/ai/prompts/README.md`

## Stable project rules

- AIDA Café is one product across the customer app, POS/Admin Dashboard and one shared Supabase backend.
- Customer repo: `Hermann-33/Aida_System`, default `master`.
- Dashboard repo: `Hermann-33/Aida_System-Dashboard`, default `main`.
- Shared Supabase ref: `eswovqxqzfevcdwwcmuh`.
- Canonical migrations live only under `Hermann-33/Aida_System/supabase/`.
- `supabase/drafts/` is preserved future work, not deployed migration state.
- Project-level governance and `docs/ai/**` are mirrored across both repositories.
- Neither frontend is authoritative for trusted business outcomes.
- Use dedicated bounded-task branches; do not implement directly on `master`/`main`.
- Run `docs/ai/playbooks/CONTEXT_UPDATE_PROTOCOL.md` after material project changes.

Do not copy stale project status out of this compatibility file. Current status belongs in `docs/ai/context/CURRENT_STATE.md` and `docs/context/ACTIVE_CONTEXT.md`.
