# Customer UI Screen Map

Updated: 2026-08-14

This mirrored map summarizes current customer surfaces. Detailed current authority and validation are in `docs/context/ACTIVE_CONTEXT.md`, `SYSTEM_MAP.md` and `CLOSEOUT_EVIDENCE_2026-08-14.md`.

| Surface | Current status |
|---|---|
| Account entry/create | Shared customer account boundary; physical Android customer creation validated |
| Account recovery sheet | Shared recovery request boundary; delivery/callback not separately closed |
| App shell | Local presentation/navigation state |
| Home | Shared catalogue plus deferred promo/loyalty presentation |
| Rewards | Preview/deferred loyalty |
| Membership QR | Trusted member read plus minimum per-user offline member-code cache |
| Menu | Shared catalogue + revision invalidation; physical Admin-change refresh validated |
| Item detail | Shared catalogue data + local selection state |
| Cart | Local selection/estimate only; not commercial authority |
| Order checkout | Authoritative policy/quote/place; ASAP/scheduled; Pay at counter |
| Order confirmation | Persisted order identity/status; no fake progression timer |
| Order history/detail | Backend customer-order snapshots |
| Profile | Trusted member presentation plus deferred profile features |
| Edit profile | UI present; trusted write persistence deferred |

Final quote/total/order identity/schedule/status come from the backend. No trusted payment processor exists in this tranche.

The remaining cross-client gate is customer order placement -> Dashboard fulfilment transition -> customer authorized refresh. Other deferred surfaces are tracked in the roadmap and mocks/placeholders register.
