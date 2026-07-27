# Admin sidebar redesign — collapsible nav with icon rail

Status: approved (pending written spec review)
Date: 2026-07-27
Scope: `apps/pos-admin-web`, Admin ("Aida Office") layout only

## Problem

The current admin sidebar (`src/layouts/AdminLayout.tsx`, styled in `src/layouts/layouts.css`)
already uses the Aida Signature color tokens (espresso background, cream/floral-pink text), but
it's a plain stacked list of text links with no icons, no active-state emphasis beyond a color
change, and no way to collapse it. The user wants it restyled to match a reference dark-sidebar
pattern (icon + label rows, pill-highlighted active state, a footer identity chip) that also
supports shrinking to an icon-only rail.

The reference design has ~4 nav items. The real admin nav (`ADMIN_NAV` in
`src/features/admin/adminNav.ts`) has 7 groups and ~30 routes total (Reports alone has 11). Any
collapsed/icon-only mode has to account for that density gap.

Out of scope (explicitly deferred, decided during brainstorming):
- POS layout: has no page-navigation sidebar today (it's a checkout workspace with a product
  category rail) — restyling that rail to the same tokens is a separate future task.
- Employee layout: login screen only, no sidebar exists.

## Design

### Component structure

Extract the sidebar out of `AdminLayout.tsx` into a new `src/layouts/AdminSidebar.tsx`:

- `AdminSidebar` owns:
  - `collapsed: boolean` state, persisted to `localStorage` (key `aida-admin-sidebar-collapsed`).
    Read failures (e.g. private browsing) fall back to `expanded`, silently — this is a cosmetic
    preference, not something to surface an error for.
  - `openGroup: string | null` — which group's flyout is open in collapsed mode (`null` when
    expanded, since expanded mode never shows flyouts).
- Renders from the existing `ADMIN_NAV` data plus one new field per group: `icon` (a
  `lucide-react` component reference). This means `AdminNavGroup` in `adminNav.ts` gains an
  `icon: LucideIcon` field — the nav *data* doesn't change shape otherwise, so
  `adminPageTitle()` and existing route wiring are untouched.
- `AdminLayout.tsx` shrinks to: `<UiPreviewBanner />`, `<AdminSidebar />`, `<Outlet />` inside
  `<main className="layout-main admin-main">` — same as today, just delegating the sidebar.

Two render branches inside `AdminSidebar`, controlled by `collapsed`:

- **Expanded** (default on first visit): same information as today — group title, then its
  items as full-label links — but restyled per below.
- **Collapsed**: a narrow rail (new `--aida-admin-rail` token, `4.5rem`, following the existing
  `--aida-rail-width: 5.5rem` naming pattern) showing only the 7 group icons stacked vertically,
  plus the collapse toggle above them. No group titles, no item labels — those only appear in
  the flyout.

### Visual design

- Sidebar background stays `--aida-espresso` in both modes (matches the existing look and the
  reference's dark theme).
- **Active nav item** (expanded): filled pill behind the label using `--aida-burgundy` (not
  `--aida-rose`, to keep it lower-contrast than the primary CTA rose used elsewhere), text
  `--aida-floral-pink`, replacing today's "just recolor the text" active state.
- **Hover** (expanded, non-active items): lighter pill, `--aida-burgundy` at reduced opacity
  (`color-mix(in srgb, var(--aida-burgundy) 35%, transparent)`), text brightens to
  `--aida-surface`.
- **Active group icon** (collapsed): same pill treatment applied to the icon's hit area, so
  there's still a glanceable "you are here" even with the flyout closed.
- **Group icons** (`lucide-react`): Overview → `LayoutDashboard`, Reports → `BarChart3`,
  Operations → `Store`, Catalogue → `Coffee`, Inventory → `Boxes`, Rewards → `Gift`, System →
  `Settings`.
- **Collapse toggle**: icon button (`PanelLeftClose` expanded / `PanelLeftOpen` collapsed) pinned
  above the "Aida Cafe" wordmark to reserve a consistent tap target regardless of mode.
- **Flyout panel** (collapsed only): `--aida-surface` background, `--aida-espresso` text,
  `--aida-shadow-lg`, `--aida-radius` corners — a floating popover anchored to the clicked
  group's icon (`position: absolute`, does not reflow layout), listing that group's items as the
  same link style used in expanded mode.
- Footer: existing identity chip (`session.identity?.fullName`) moves to the bottom of the
  sidebar (`margin-top: auto` in a flex column), matching the reference's footer-anchored user
  chip. In collapsed mode it shrinks to just the avatar initial in a circle.

### Interaction & accessibility

- Flyouts open on **click**, not hover — hover-to-open is unreliable on trackpads/touch, and
  this product has POS-adjacent touch surfaces.
- Clicking a different group's icon while a flyout is open closes the current one and opens the
  new one (only one open at a time).
- Closing a flyout: click its own icon again, click anywhere outside it, or press `Escape`.
- The group icon button is a real `<button aria-expanded={openGroup === group.title}>`; the
  flyout is `role="menu"` with items as focusable links (`role="menuitem"`); `Escape` returns
  focus to the triggering button. This satisfies the PRD §7 requirement for WCAG 2.2 AA and
  visible keyboard focus.
- Being on a route within a collapsed group does **not** auto-open that group's flyout — the
  icon's active-pill state is enough of a "you are here" signal, and auto-opening on every
  navigation would be noisy.
- Collapse/expand toggling never triggers navigation and never closes an open flyout by itself
  (toggling collapse while a flyout is open just closes the flyout, since collapsed state
  changing invalidates it).

### Testing

New `src/layouts/AdminSidebar.test.tsx`:
- Renders expanded by default (localStorage empty).
- Toggle button flips to collapsed; collapsed mode renders exactly 7 group icon buttons and no
  item-label text.
- Clicking a group icon in collapsed mode opens a flyout containing that group's item labels as
  links; clicking a different icon swaps the open flyout; `Escape` closes it.
- Collapsed state round-trips through `localStorage` (set collapsed, re-render/remount, still
  collapsed).
- Active route highlights the correct item (expanded) / correct group icon (collapsed).

Existing `src/features/pos/cartPermissions.test.tsx` assertion ("AdminLayout does not render POS
checkout rail") is unaffected — `AdminLayout`'s rendered *content* (banner, sidebar, outlet)
doesn't change, only the sidebar's internal structure/styling.

### New dependency

Add `lucide-react` (MIT-licensed, tree-shakeable) to `dependencies` for the 9 icons used (7
groups + 2 toggle states).

## Explicitly out of scope

- POS category rail restyle — separate follow-up task, not touched here.
- Employee layout — no sidebar exists, nothing to do.
- Changing `ADMIN_NAV`'s routes, labels, or grouping — this is a presentation-layer redesign
  only; no pages move groups or get renamed.
