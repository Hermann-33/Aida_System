# ADR-0013 — Parallel Phase 1–3 Audit and Phase 4–7 Implementation

**Status:** Accepted  
**Date:** 2026-09-14

## Decision

By explicit owner direction, the independent Phase 1–3 code audit may run in parallel with implementation of Phases 4–7.

This supersedes earlier governance text that blocked Phase 4 until the combined Phase 1–3 audit finished.

## Constraints

- Phase 4–7 still execute strictly in dependency order.
- Every phase still requires its plan, implementation, migrations, regressions, client validation, advisors and synchronized documentation before `COMPLETE`.
- Existing Phase 1–3 PRs remain unmerged during the audit.
- A valid blocking audit finding reopens the affected earlier phase and must be reconciled before final acceptance.
- Later work must not weaken any Phase 1–3 trust boundary to avoid an audit finding.
- Phase 8 does not begin until Phase 7 is `COMPLETE` and the current audit findings have been reconciled.

## Rationale

The audit is independent verification rather than an implementation dependency. Parallel work reduces idle time while preserving the requirement to correct any substantive earlier-phase finding.
