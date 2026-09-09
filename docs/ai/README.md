# AIDA Café AI Context

This directory is the durable operating context for fresh ChatGPT, Codex, Claude, Astra, or other coding-agent sessions working on AIDA Café.

Start with:

1. `BOOTSTRAP.md`
2. `context/CURRENT_STATE.md`
3. `CONTEXT_MANIFEST.yaml`

Then load only the subsystem docs and reusable prompt relevant to the task.

## Directory map

- `context/**` — concise current project state.
- `playbooks/**` — repeatable operating procedures.
- `prompts/**` — copy/paste prompts for fresh agents and common task classes.
- `PROJECT_MEMORY.md` — source-of-truth hierarchy and durable-memory model.
- `CONTEXT_MANIFEST.yaml` — task-to-context routing map.

## Core rule

AIDA is one product across two repositories and one shared Supabase backend. A fresh agent must never treat one frontend as the whole system or treat client state as authoritative business truth.

The prompt files are starting contracts, not substitutes for inspecting current code, Git state, accepted ADRs, or live Supabase state when the task depends on it.
