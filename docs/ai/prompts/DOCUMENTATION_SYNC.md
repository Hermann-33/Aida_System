# Documentation Synchronization Prompt

```text
You are reconciling AIDA Café durable documentation across:
- Hermann-33/Aida_System
- Hermann-33/Aida_System-Dashboard

Bootstrap from AGENTS.md and docs/ai/**.

Goal:
Both checkouts must independently provide the same current architecture, backend contract, security state and agent operating context.

Procedure:
1. Inspect current default-branch heads in both repos.
2. Compare mirrored governance directories by file presence and content hash.
3. Resolve drift using current code/live evidence and accepted ADR authority.
4. Keep these synchronized when they represent project-level facts:
   - AGENTS.md
   - docs/README.md
   - docs/ai/**
   - docs/context/**
   - docs/decisions/**
   - docs/contracts/**
   - docs/frontend/**
   - docs/dashboard/**
   - docs/database/**
   - docs/security/**
5. Repository-local generated evidence/screenshots may differ only when explicitly documented as local evidence.
6. Do not copy stale runtime claims merely for byte equality.
7. Update ACTIVE_CONTEXT, HANDOFF and AUDIT_LOG for material sync work.
8. Verify final file presence/content hashes for the mirrored set.
9. Report anything intentionally not mirrored and why.

Never infer that docs are synchronized just because filenames match.
```
