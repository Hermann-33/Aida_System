# POS/Admin Fragile Boundaries

Updated: 2026-08-23

## High-risk areas

- `src/App.tsx` / `ProtectedRoute`: UI route guards are presentation only; same-origin BFF + Supabase remain authorization authority.
- `src/auth/`: employee session semantics must not regress from HttpOnly cookies into browser-readable bearer tokens.
- `src/pages/EmployeeWelcomePage.tsx` / `PosShellPage.tsx`: live staff access must remain independent of deferred terminal/shift authority; preview repositories stay preview-only.
- `src/features/catalogue/catalogueClient.ts`: shared catalogue decoding must retain `isDrink`, `customizationGroups`, variants and compatible add-ons without inventing commercial defaults client-side. Older/missing customization arrays may safely decode to empty presentation state, but malformed trusted fields must not be used as new authority.
- `src/features/admin/AdminMenuEditorPage.tsx`: drink option controls must preserve at least one available option and exactly one available default per required group; client validation supplements but never replaces backend validation.
- `src/features/pos/posCatalogue.ts` / `ModifierSheet.tsx`: variants and Temperature/Sweetness are required single-choice groups; compatible add-ons are optional multi-select. Do not collapse this into global/per-order modifier state.
- `src/features/orders/orderClient.ts`: `optionValueIds` are selection IDs only. Do not add product/option prices, labels or totals as trusted placement input. `scheduleState`/`prepareAt` also remain server projections.
- Local POS cart arithmetic is estimate-only. Server quote is commercial authority.
- `src/preview/`: fixtures must never be promoted to live business truth.
- Manager approval/void/refund/cancel previews are not trusted privilege boundaries.
- Shift/cash, branch/terminal, loyalty, inventory and reporting remain deferred authority domains.
- Preview/live build gates must remain fail-closed against preview/auth bypass.

## Cross-repo modifier fragility

Customer Flutter and Dashboard/POS must remain contract-compatible on:

```text
catalogue item IDs
variant IDs
option group/value IDs
compatible add-on IDs
option/add-on availability/default semantics
integer-sen price deltas
order option snapshots
pricingVersion
```

A change to the standard option template, option-group requirements, ID shape or quote payload is a cross-repository contract change, not an isolated frontend edit.

## Per-line independence

Cart equality/identity must include option/add-on selections.

These configurations must never merge implicitly:

```text
Latte · Hot · Regular · no add-on
Latte · Iced · Less sweet · Boba
```

Do not reintroduce a global Add-ons ordering section/state that cannot identify the target drink.

## Admin option rules

- An unavailable option cannot remain the active default.
- Every required group needs at least one available option and exactly one available default.
- Customer-facing labels may change without changing stable option IDs.
- Price deltas are integer sen and remain backend-authoritative.
- Disabling an option changes future availability only; historical order snapshots must remain unchanged.
- Preview Admin must remain read-only.

## UI/theme rules

New modifier/Admin UI must reuse the existing Dashboard token/component language:

- `src/styles/tokens.css` colors/spacing/radii;
- Plus Jakarta Sans / Playfair typography;
- existing modifier cards/forms/buttons;
- visible focus behavior and reduced-motion handling.

Do not import Luckin/reference-app branding or create a second modifier design system.

Unavailable/selected/required state must not rely on color alone.

## Scheduling / fulfilment rules

- Customer/POS display may say `Now`, but the shared wire enum remains `asap` until a coordinated contract change.
- Do not manufacture valid schedule slots or branch hours locally.
- Do not recreate `scheduleState` from workstation time or auto-transition orders.
- Keep legal versioned fulfilment transitions and conflict refetch behavior.

## Change rules

- Define/modify server authority before changing trusted modifier semantics.
- Coordinate option/add-on/order payload changes across both repositories.
- Keep terminal/shift rails preview-only until their authoritative schema/BFF exists.
- Preserve explicit preview labeling for deferred domains.
- Do not silently change shared lifecycle strings/IDs.
- Keep local estimates clearly subordinate to quote results.

TASK-MENU-CUSTOMIZATION-001 validation evidence is in `docs/context/MENU_CUSTOMIZATION_2026-08-23.md`.
