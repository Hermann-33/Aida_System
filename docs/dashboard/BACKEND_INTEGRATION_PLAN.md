# POS/Admin Backend Integration Plan

Updated: 2026-08-14

Current detailed architecture is defined by the accepted ADRs and shared contracts. This mirrored file records implementation status and the remaining closeout work.

## Implemented and validated

- Local Dashboard and installed Android app use the same shared backend.
- Real Owner/Admin/Staff test identities exist.
- Protected Members is integrated; a physical Android customer creation appeared there.
- Admin Menu and POS browse the shared catalogue.
- A real Owner price change propagated to the installed Android customer app.
- TASK-AUTH-005 preview/live navigation regression is fixed.
- Order policy, quote, place, queue, detail and status backend endpoints exist.

Hosted deployment remains deferred for the current local-demo topology.

## Remaining TASK-CLOSEOUT-001 work

Dashboard React must finish the live ordering surfaces:

- cart remains selection intent only;
- final quote totals come from the backend;
- ASAP and scheduled pickup use server policy;
- retries reuse the same placement request ID for the same intended order;
- persisted order identity/schedule/status come from the backend;
- sale clears only after successful persistence;
- live Orders uses the backend queue instead of preview transactions;
- fulfilment changes use the current status version and refetch on conflict;
- the order board uses short polling/refetch through the existing application boundary.

Legal progression:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready -> completed
```

Current scheduling defaults: Asia/Kuala_Lumpur, 15-minute lead, 15-minute slots, 7-day maximum advance. Branch hours/capacity are not modeled.

No trusted payment processor exists. The authoritative demo path is Pay at counter / unpaid.

## Completion proof

Run the full Dashboard validation suite and prove customer placement -> persisted order -> Dashboard transition -> customer authorized refresh. See `docs/context/CLOSEOUT_EVIDENCE_2026-08-14.md` for dated evidence.
