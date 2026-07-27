# Admin Sidebar Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the admin ("Aida Office") sidebar's plain text-link list with a restyled, icon-labeled nav that can collapse to an icon-only rail, with each group reachable via a click-to-open flyout when collapsed.

**Architecture:** Extract the sidebar out of `AdminLayout.tsx` into a new `AdminSidebar.tsx` component that owns collapsed/expanded state (persisted to `localStorage`) and open-flyout state. `ADMIN_NAV` data gains an `icon` field per group; a new `isNavItemActive` helper centralizes the active-route matching logic reused by the collapsed rail's group highlighting.

**Tech Stack:** React 19, react-router-dom v7, Vitest + Testing Library, `lucide-react` (new dependency), plain CSS with existing Aida design tokens (`src/styles/tokens.css`).

## Global Constraints

- Spec: `docs/superpowers/specs/2026-07-27-admin-sidebar-redesign-design.md`.
- Scope is the Admin sidebar only — do not touch `PosLayout`, `EmployeeLayout`, or their CSS.
- Do not change `ADMIN_NAV`'s routes, labels, or grouping — this is presentation-layer only.
- Use only existing Aida design tokens from `src/styles/tokens.css` (no new hardcoded colors);
  add exactly one new token, `--aida-admin-rail`, for the collapsed rail width.
- `lucide-react` is the only new dependency to add.
- All file paths below are relative to `apps/pos-admin-web/` — run all commands from that
  directory.
- This repo uses `verbatimModuleSyntax: true` — type-only imports must use `import type`.
- Flyouts and the collapse toggle must be real `<button>` elements with correct `aria-*`
  attributes (no `<div onClick>`) — the project's global `:focus-visible` style already
  provides visible keyboard focus for free, so no extra focus-ring CSS is needed.

---

### Task 1: Nav data gains icons and an active-match helper

**Files:**
- Modify: `src/features/admin/adminNav.ts`
- Test: `src/features/admin/adminNav.test.ts` (create)

**Interfaces:**
- Produces: `AdminNavGroup.icon: LucideIcon` (new field on the existing interface), and
  `isNavItemActive(pathname: string, item: AdminNavItem): boolean` (new exported function).
  Task 2+ import both from `../features/admin/adminNav`.

- [ ] **Step 1: Write the failing test**

Create `src/features/admin/adminNav.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import { ADMIN_NAV, adminPageTitle, isNavItemActive } from './adminNav';

describe('ADMIN_NAV', () => {
  it('gives every group an icon component', () => {
    for (const group of ADMIN_NAV) {
      expect(group.icon).toBeTruthy();
    }
  });

  it('keeps existing page-title lookup working', () => {
    expect(adminPageTitle('/admin/operations/terminals')).toBe('Terminals');
    expect(adminPageTitle('/admin/catalogue/menu/abc123')).toBe('Menu item editor');
  });
});

describe('isNavItemActive', () => {
  it('matches the dashboard item only on exact root path', () => {
    expect(isNavItemActive('/admin', { label: 'Dashboard', path: '/admin' })).toBe(true);
    expect(isNavItemActive('/admin/live', { label: 'Dashboard', path: '/admin' })).toBe(false);
  });

  it('matches non-root items exactly or as a path prefix', () => {
    const item = { label: 'Menu', path: '/admin/catalogue/menu' };
    expect(isNavItemActive('/admin/catalogue/menu', item)).toBe(true);
    expect(isNavItemActive('/admin/catalogue/menu/abc123', item)).toBe(true);
    expect(isNavItemActive('/admin/catalogue/menu-other', item)).toBe(false);
    expect(isNavItemActive('/admin/catalogue/categories', item)).toBe(false);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test -- src/features/admin/adminNav.test.ts`
Expected: FAIL — `isNavItemActive` is not exported, and `group.icon` is `undefined`.

- [ ] **Step 3: Write minimal implementation**

Replace the full contents of `src/features/admin/adminNav.ts` with:

```ts
import type { LucideIcon } from 'lucide-react';
import { BarChart3, Boxes, Coffee, Gift, LayoutDashboard, Settings, Store } from 'lucide-react';

export interface AdminNavItem {
  label: string;
  path: string;
}

export interface AdminNavGroup {
  title: string;
  icon: LucideIcon;
  items: AdminNavItem[];
}

export const ADMIN_NAV: AdminNavGroup[] = [
  {
    title: 'Overview',
    icon: LayoutDashboard,
    items: [
      { label: 'Dashboard', path: '/admin' },
      { label: 'Live Ops', path: '/admin/live' },
    ],
  },
  {
    title: 'Reports',
    icon: BarChart3,
    items: [
      { label: 'Sales', path: '/admin/reports/sales' },
      { label: 'Branches', path: '/admin/reports/branches' },
      { label: 'Transactions', path: '/admin/reports/transactions' },
      { label: 'Products', path: '/admin/reports/products' },
      { label: 'Payments', path: '/admin/reports/payments' },
      { label: 'Shifts cash', path: '/admin/reports/shifts' },
      { label: 'Rewards', path: '/admin/reports/rewards' },
      { label: 'Members', path: '/admin/reports/members' },
      { label: 'Voids/Refunds', path: '/admin/reports/voids' },
      { label: 'Inventory', path: '/admin/reports/inventory' },
      { label: 'Exports', path: '/admin/reports/exports' },
    ],
  },
  {
    title: 'Operations',
    icon: Store,
    items: [
      { label: 'Branches', path: '/admin/operations/branches' },
      { label: 'Sales points', path: '/admin/operations/sales-points' },
      { label: 'Terminals', path: '/admin/operations/terminals' },
      { label: 'Shifts', path: '/admin/operations/shifts' },
      { label: 'Employees', path: '/admin/operations/employees' },
    ],
  },
  {
    title: 'Catalogue',
    icon: Coffee,
    items: [
      { label: 'Menu', path: '/admin/catalogue/menu' },
      { label: 'Categories', path: '/admin/catalogue/categories' },
      { label: 'Variants', path: '/admin/catalogue/variants' },
    ],
  },
  {
    title: 'Inventory',
    icon: Boxes,
    items: [
      { label: 'Stock', path: '/admin/inventory/stock' },
      { label: 'Recipes', path: '/admin/inventory/recipes' },
      { label: 'Wastage', path: '/admin/inventory/wastage' },
    ],
  },
  {
    title: 'Rewards',
    icon: Gift,
    items: [
      { label: 'Loyalty', path: '/admin/rewards/loyalty' },
      { label: 'Stamps', path: '/admin/rewards/stamps' },
      { label: 'Offers', path: '/admin/rewards/offers' },
      { label: 'Campaigns', path: '/admin/rewards/campaigns' },
      { label: 'Ad publishing', path: '/admin/rewards/ads' },
    ],
  },
  {
    title: 'System',
    icon: Settings,
    items: [
      { label: 'Audit', path: '/admin/system/audit' },
      { label: 'Integrations', path: '/admin/system/integrations' },
      { label: 'Settings', path: '/admin/system/settings' },
    ],
  },
];

const MENU_EDITOR_RE = /^\/admin\/catalogue\/menu\/[^/]+$/;

export function adminPageTitle(pathname: string): string {
  if (MENU_EDITOR_RE.test(pathname)) return 'Menu item editor';
  for (const group of ADMIN_NAV) {
    const item = group.items.find((i) => i.path === pathname);
    if (item) return item.label;
  }
  return 'Admin';
}

/** Whether `pathname` is on or under `item.path` — used to highlight the
 * right nav entry (expanded) or group icon (collapsed) for the current route,
 * including nested routes like the menu item editor. */
export function isNavItemActive(pathname: string, item: AdminNavItem): boolean {
  if (item.path === '/admin') return pathname === '/admin';
  return pathname === item.path || pathname.startsWith(`${item.path}/`);
}
```

This requires `lucide-react` to be installed before it type-checks — install it now:

Run: `npm install lucide-react@^1.27.0`
Expected: `package.json` gains `"lucide-react": "^1.27.0"` under `dependencies`; `package-lock.json` updates.

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test -- src/features/admin/adminNav.test.ts`
Expected: PASS (all 4 tests)

- [ ] **Step 5: Commit**

```bash
git add src/features/admin/adminNav.ts src/features/admin/adminNav.test.ts package.json package-lock.json
git commit -m "Add group icons and active-route matching to ADMIN_NAV"
```

---

### Task 2: AdminSidebar component — expanded mode

**Files:**
- Create: `src/layouts/AdminSidebar.tsx`
- Create: `src/layouts/AdminSidebar.test.tsx`
- Modify: `src/layouts/AdminLayout.tsx`
- Modify: `src/layouts/layouts.css:70-122` (replace the existing `.admin-sidebar`/`.admin-nav-*` block)

**Interfaces:**
- Consumes: `ADMIN_NAV` (`AdminNavGroup[]`), `AdminNavItem`, `isNavItemActive` from
  `../features/admin/adminNav`; `getEmployeeSession`, `subscribeEmployeeSession` from
  `../auth/employeeSession` (same as the code being replaced used).
- Produces: `AdminSidebar` component (default export none — named export only), rendered by
  `AdminLayout`. No collapse behavior yet (Task 3) — always renders expanded.

- [ ] **Step 1: Write the failing test**

Create `src/layouts/AdminSidebar.test.tsx`:

```tsx
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { cleanup, render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { AdminSidebar } from './AdminSidebar';

function renderSidebar(initialPath = '/admin') {
  return render(
    <MemoryRouter initialEntries={[initialPath]}>
      <AdminSidebar />
    </MemoryRouter>,
  );
}

beforeEach(() => {
  window.localStorage.clear();
});

afterEach(() => {
  cleanup();
});

describe('AdminSidebar (expanded)', () => {
  it('renders every group title and item label', () => {
    renderSidebar();
    expect(screen.getByText('Overview')).toBeInTheDocument();
    expect(screen.getByText('Reports')).toBeInTheDocument();
    expect(screen.getByText('Dashboard')).toBeInTheDocument();
    expect(screen.getByText('Terminals')).toBeInTheDocument();
  });

  it('marks the current route\'s link active', () => {
    renderSidebar('/admin/operations/terminals');
    expect(screen.getByRole('link', { name: 'Terminals' })).toHaveClass(
      'admin-nav-link--active',
    );
    expect(screen.getByRole('link', { name: 'Dashboard' })).not.toHaveClass(
      'admin-nav-link--active',
    );
  });

  it('shows the signed-in identity and product title', () => {
    renderSidebar();
    expect(screen.getByText('Aida Office')).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test -- src/layouts/AdminSidebar.test.tsx`
Expected: FAIL — cannot find module `./AdminSidebar`.

- [ ] **Step 3: Write minimal implementation**

Create `src/layouts/AdminSidebar.tsx`:

```tsx
import { useSyncExternalStore } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { getEmployeeSession, subscribeEmployeeSession } from '../auth/employeeSession';
import { ADMIN_NAV } from '../features/admin/adminNav';

export function AdminSidebar() {
  const location = useLocation();
  const session = useSyncExternalStore(
    subscribeEmployeeSession,
    getEmployeeSession,
    getEmployeeSession,
  );

  return (
    <aside className="admin-sidebar">
      <div className="admin-sidebar__header">
        <p className="brand-script">Aida Cafe</p>
      </div>

      <p className="admin-product-title">Aida Office</p>
      <p className="layout-sub">{session.identity?.fullName ?? 'Admin'}</p>

      <nav aria-label="Admin modules" className="admin-nav">
        {ADMIN_NAV.map((group) => {
          const Icon = group.icon;
          return (
            <div key={group.title} className="admin-nav-group">
              <p className="admin-nav-group__title">
                <Icon size={16} aria-hidden="true" />
                {group.title}
              </p>
              <ul className="admin-nav-list">
                {group.items.map((item) => (
                  <li key={item.path}>
                    <NavLink
                      to={item.path}
                      className={({ isActive }) =>
                        isActive || (item.path === '/admin' && location.pathname === '/admin')
                          ? 'admin-nav-link admin-nav-link--active'
                          : 'admin-nav-link'
                      }
                      end={item.path === '/admin'}
                    >
                      {item.label}
                    </NavLink>
                  </li>
                ))}
              </ul>
            </div>
          );
        })}
      </nav>
    </aside>
  );
}
```

Modify `src/layouts/AdminLayout.tsx` — replace its full contents with:

```tsx
import { Outlet } from 'react-router-dom';
import { UiPreviewBanner } from '../shared/components/UiPreviewBanner';
import { AdminSidebar } from './AdminSidebar';
import './layouts.css';

/**
 * Admin layout — separate product tree.
 * Must never render POS checkout controls or POS navigation.
 */
export function AdminLayout() {
  return (
    <div className="layout layout-admin" data-product="admin">
      <UiPreviewBanner />
      <AdminSidebar />
      <main className="layout-main admin-main">
        <Outlet />
      </main>
    </div>
  );
}
```

In `src/layouts/layouts.css`, delete lines 70–122 (the old `.admin-sidebar` through
`.admin-nav-list li` block — everything between `.layout-admin { ... }` and `.admin-main { ... }`)
and replace with:

```css
.admin-sidebar {
  width: var(--aida-admin-sidebar);
  min-width: var(--aida-admin-sidebar);
  background: var(--aida-espresso);
  color: var(--aida-cream);
  padding: var(--aida-space-6) var(--aida-space-4);
  overflow-y: auto;
  display: flex;
  flex-direction: column;
}

.admin-sidebar__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--aida-space-2);
  margin-bottom: var(--aida-space-2);
}

.admin-product-title {
  margin: 0 0 var(--aida-space-1);
  font-weight: 700;
}

.admin-nav {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.admin-nav-group {
  margin-top: var(--aida-space-5);
}

.admin-nav-group:first-child {
  margin-top: var(--aida-space-4);
}

.admin-nav-group__title {
  display: flex;
  align-items: center;
  gap: var(--aida-space-2);
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--aida-taupe);
  margin: 0 0 var(--aida-space-2);
}

.admin-nav-link {
  display: block;
  padding: 0.5rem var(--aida-space-3);
  border-radius: var(--aida-radius-sm);
  color: var(--aida-latte);
  text-decoration: none;
  font-size: 0.9rem;
  font-weight: 500;
  transition: background var(--aida-transition), color var(--aida-transition);
}

.admin-nav-link:hover {
  background: color-mix(in srgb, var(--aida-burgundy) 35%, transparent);
  color: var(--aida-surface);
}

.admin-nav-link--active {
  background: var(--aida-burgundy);
  color: var(--aida-floral-pink);
  font-weight: 700;
}

.admin-nav-list {
  list-style: none;
  padding: 0;
  margin: var(--aida-space-2) 0 0;
  display: flex;
  flex-direction: column;
  gap: var(--aida-space-1);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test -- src/layouts/AdminSidebar.test.tsx`
Expected: PASS (all 3 tests)

Run: `npm run test -- src/features/pos/cartPermissions.test.tsx`
Expected: PASS — confirms `AdminLayout` still renders "Aida Office" and no POS chrome, unchanged
by the extraction.

- [ ] **Step 5: Commit**

```bash
git add src/layouts/AdminSidebar.tsx src/layouts/AdminSidebar.test.tsx src/layouts/AdminLayout.tsx src/layouts/layouts.css
git commit -m "Extract AdminSidebar with icons and pill active-state"
```

---

### Task 3: Collapse toggle with icon-only rail

**Files:**
- Modify: `src/layouts/AdminSidebar.tsx`
- Modify: `src/layouts/AdminSidebar.test.tsx`
- Modify: `src/layouts/layouts.css`
- Modify: `src/styles/tokens.css:53-55` (add the new rail-width token next to
  `--aida-admin-sidebar`)

**Interfaces:**
- Produces: `AdminSidebar` now reads/writes a `boolean` collapsed preference via
  `window.localStorage` key `'aida-admin-sidebar-collapsed'` (string `'true'`/`'false'`). Task 4
  consumes the same `collapsed` state (added here) to gate flyout rendering.

- [ ] **Step 1: Write the failing test**

Add to `src/layouts/AdminSidebar.test.tsx` (append a new `describe` block after the existing
one, keep the existing `renderSidebar`/`beforeEach`/`afterEach` at the top):

```tsx
import userEvent from '@testing-library/user-event';

// ...(existing describe('AdminSidebar (expanded)', ...) block stays)...

describe('AdminSidebar (collapse toggle)', () => {
  it('starts expanded when there is no stored preference', () => {
    renderSidebar();
    expect(screen.getByRole('button', { name: 'Collapse sidebar' })).toBeInTheDocument();
  });

  it('collapses to 7 icon-only group buttons on toggle, hiding text labels', async () => {
    const user = userEvent.setup();
    renderSidebar();

    await user.click(screen.getByRole('button', { name: 'Collapse sidebar' }));

    expect(screen.queryByText('Dashboard')).not.toBeInTheDocument();
    expect(screen.queryByText('Overview')).not.toBeInTheDocument();
    expect(
      screen.getAllByRole('button', {
        name: /^(Overview|Reports|Operations|Catalogue|Inventory|Rewards|System)$/,
      }),
    ).toHaveLength(7);
    expect(screen.getByRole('button', { name: 'Expand sidebar' })).toBeInTheDocument();
  });

  it('persists collapsed state across a remount', async () => {
    const user = userEvent.setup();
    const { unmount } = renderSidebar();
    await user.click(screen.getByRole('button', { name: 'Collapse sidebar' }));
    unmount();

    renderSidebar();
    expect(screen.getByRole('button', { name: 'Expand sidebar' })).toBeInTheDocument();
    expect(screen.queryByText('Dashboard')).not.toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test -- src/layouts/AdminSidebar.test.tsx`
Expected: FAIL — no "Collapse sidebar" button exists yet.

- [ ] **Step 3: Write minimal implementation**

In `src/styles/tokens.css`, in the `:root` block right after the `--aida-admin-sidebar: 16rem;`
line, add:

```css
  --aida-admin-rail: 4.5rem;
```

Replace the full contents of `src/layouts/AdminSidebar.tsx` with:

```tsx
import { useEffect, useState } from 'react';
import { useSyncExternalStore } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { PanelLeftClose, PanelLeftOpen } from 'lucide-react';
import { getEmployeeSession, subscribeEmployeeSession } from '../auth/employeeSession';
import { ADMIN_NAV } from '../features/admin/adminNav';

const COLLAPSE_STORAGE_KEY = 'aida-admin-sidebar-collapsed';

function readCollapsedPreference(): boolean {
  try {
    return window.localStorage.getItem(COLLAPSE_STORAGE_KEY) === 'true';
  } catch {
    return false;
  }
}

function writeCollapsedPreference(value: boolean) {
  try {
    window.localStorage.setItem(COLLAPSE_STORAGE_KEY, String(value));
  } catch {
    // Cosmetic preference only — not worth surfacing an error for.
  }
}

export function AdminSidebar() {
  const location = useLocation();
  const session = useSyncExternalStore(
    subscribeEmployeeSession,
    getEmployeeSession,
    getEmployeeSession,
  );
  const [collapsed, setCollapsed] = useState(readCollapsedPreference);

  useEffect(() => {
    writeCollapsedPreference(collapsed);
  }, [collapsed]);

  return (
    <aside className={collapsed ? 'admin-sidebar admin-sidebar--collapsed' : 'admin-sidebar'}>
      <div className="admin-sidebar__header">
        {!collapsed && <p className="brand-script">Aida Cafe</p>}
        <button
          type="button"
          className="admin-sidebar__toggle"
          aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          onClick={() => setCollapsed((c) => !c)}
        >
          {collapsed ? <PanelLeftOpen size={20} /> : <PanelLeftClose size={20} />}
        </button>
      </div>

      {!collapsed && (
        <>
          <p className="admin-product-title">Aida Office</p>
          <p className="layout-sub">{session.identity?.fullName ?? 'Admin'}</p>
        </>
      )}

      <nav aria-label="Admin modules" className="admin-nav">
        {ADMIN_NAV.map((group) => {
          const Icon = group.icon;

          if (collapsed) {
            return (
              <div key={group.title} className="admin-nav-group admin-nav-group--collapsed">
                <button type="button" className="admin-nav-group__icon-btn" aria-label={group.title}>
                  <Icon size={20} />
                </button>
              </div>
            );
          }

          return (
            <div key={group.title} className="admin-nav-group">
              <p className="admin-nav-group__title">
                <Icon size={16} aria-hidden="true" />
                {group.title}
              </p>
              <ul className="admin-nav-list">
                {group.items.map((item) => (
                  <li key={item.path}>
                    <NavLink
                      to={item.path}
                      className={({ isActive }) =>
                        isActive || (item.path === '/admin' && location.pathname === '/admin')
                          ? 'admin-nav-link admin-nav-link--active'
                          : 'admin-nav-link'
                      }
                      end={item.path === '/admin'}
                    >
                      {item.label}
                    </NavLink>
                  </li>
                ))}
              </ul>
            </div>
          );
        })}
      </nav>
    </aside>
  );
}
```

In `src/layouts/layouts.css`, append after the `.admin-nav-list` rule:

```css
.admin-sidebar--collapsed {
  width: var(--aida-admin-rail);
  min-width: var(--aida-admin-rail);
  padding: var(--aida-space-6) var(--aida-space-2);
}

.admin-sidebar--collapsed .admin-sidebar__header {
  justify-content: center;
}

.admin-sidebar__toggle {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 2.25rem;
  height: 2.25rem;
  border-radius: var(--aida-radius-xs);
  border: none;
  background: transparent;
  color: var(--aida-cream);
  cursor: pointer;
}

.admin-sidebar__toggle:hover {
  background: color-mix(in srgb, var(--aida-burgundy) 45%, transparent);
}

.admin-nav-group--collapsed {
  display: flex;
  justify-content: center;
}

.admin-nav-group__icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 2.75rem;
  height: 2.75rem;
  border-radius: var(--aida-radius-sm);
  border: none;
  background: transparent;
  color: var(--aida-latte);
  cursor: pointer;
}

.admin-nav-group__icon-btn:hover {
  background: color-mix(in srgb, var(--aida-burgundy) 35%, transparent);
  color: var(--aida-surface);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test -- src/layouts/AdminSidebar.test.tsx`
Expected: PASS (all 6 tests)

- [ ] **Step 5: Commit**

```bash
git add src/layouts/AdminSidebar.tsx src/layouts/AdminSidebar.test.tsx src/layouts/layouts.css src/styles/tokens.css
git commit -m "Add collapsible icon-only rail mode to AdminSidebar"
```

---

### Task 4: Group flyout on icon click

**Files:**
- Modify: `src/layouts/AdminSidebar.tsx`
- Modify: `src/layouts/AdminSidebar.test.tsx`
- Modify: `src/layouts/layouts.css`

**Interfaces:**
- Consumes: `isNavItemActive` from `../features/admin/adminNav` (added in Task 1, unused until
  now).
- Produces: no new exports — this is purely internal interaction behavior on `AdminSidebar`.

- [ ] **Step 1: Write the failing test**

Append to `src/layouts/AdminSidebar.test.tsx`:

```tsx
describe('AdminSidebar (group flyout)', () => {
  async function collapse(user: ReturnType<typeof userEvent.setup>) {
    await user.click(screen.getByRole('button', { name: 'Collapse sidebar' }));
  }

  it('opens a flyout with that group\'s items on icon click', async () => {
    const user = userEvent.setup();
    renderSidebar();
    await collapse(user);

    await user.click(screen.getByRole('button', { name: 'Reports' }));

    const flyout = screen.getByRole('menu');
    expect(within(flyout).getByText('Sales')).toBeInTheDocument();
    expect(within(flyout).getByText('Members')).toBeInTheDocument();
  });

  it('swaps to a different group\'s flyout on another icon click', async () => {
    const user = userEvent.setup();
    renderSidebar();
    await collapse(user);

    await user.click(screen.getByRole('button', { name: 'Reports' }));
    await user.click(screen.getByRole('button', { name: 'Operations' }));

    const flyout = screen.getByRole('menu');
    expect(within(flyout).getByText('Terminals')).toBeInTheDocument();
    expect(within(flyout).queryByText('Sales')).not.toBeInTheDocument();
  });

  it('closes the flyout on Escape and returns focus to its trigger button', async () => {
    const user = userEvent.setup();
    renderSidebar();
    await collapse(user);

    const reportsButton = screen.getByRole('button', { name: 'Reports' });
    await user.click(reportsButton);
    expect(screen.getByRole('menu')).toBeInTheDocument();

    // Tab into the flyout so focus genuinely leaves the trigger button —
    // otherwise this test would pass even if Escape didn't restore it.
    await user.tab();
    expect(screen.getByRole('menuitem', { name: 'Sales' })).toHaveFocus();

    await user.keyboard('{Escape}');
    expect(screen.queryByRole('menu')).not.toBeInTheDocument();
    expect(reportsButton).toHaveFocus();
  });

  it('closes the flyout when clicking its own icon again', async () => {
    const user = userEvent.setup();
    renderSidebar();
    await collapse(user);

    await user.click(screen.getByRole('button', { name: 'Reports' }));
    expect(screen.getByRole('menu')).toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: 'Reports' }));
    expect(screen.queryByRole('menu')).not.toBeInTheDocument();
  });

  it('highlights the active group icon when collapsed', async () => {
    const user = userEvent.setup();
    renderSidebar('/admin/operations/terminals');
    await collapse(user);

    expect(screen.getByRole('button', { name: 'Operations' })).toHaveClass(
      'admin-nav-group__icon-btn--active',
    );
    expect(screen.getByRole('button', { name: 'Reports' })).not.toHaveClass(
      'admin-nav-group__icon-btn--active',
    );
  });
});
```

Add `within` to the existing `@testing-library/react` import at the top of the file:

```tsx
import { cleanup, render, screen, within } from '@testing-library/react';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test -- src/layouts/AdminSidebar.test.tsx`
Expected: FAIL — clicking a group icon does nothing yet, no `role="menu"` exists.

- [ ] **Step 3: Write minimal implementation**

Replace the full contents of `src/layouts/AdminSidebar.tsx` with:

```tsx
import { useEffect, useRef, useState } from 'react';
import { useSyncExternalStore } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { PanelLeftClose, PanelLeftOpen } from 'lucide-react';
import { getEmployeeSession, subscribeEmployeeSession } from '../auth/employeeSession';
import { ADMIN_NAV, isNavItemActive } from '../features/admin/adminNav';

const COLLAPSE_STORAGE_KEY = 'aida-admin-sidebar-collapsed';

function readCollapsedPreference(): boolean {
  try {
    return window.localStorage.getItem(COLLAPSE_STORAGE_KEY) === 'true';
  } catch {
    return false;
  }
}

function writeCollapsedPreference(value: boolean) {
  try {
    window.localStorage.setItem(COLLAPSE_STORAGE_KEY, String(value));
  } catch {
    // Cosmetic preference only — not worth surfacing an error for.
  }
}

export function AdminSidebar() {
  const location = useLocation();
  const session = useSyncExternalStore(
    subscribeEmployeeSession,
    getEmployeeSession,
    getEmployeeSession,
  );
  const [collapsed, setCollapsed] = useState(readCollapsedPreference);
  const [openGroup, setOpenGroup] = useState<string | null>(null);
  // One button can be "the" open trigger at a time — keyed by group title so
  // Escape can restore focus to wherever the flyout was actually opened from.
  const groupButtonRefs = useRef<Record<string, HTMLButtonElement | null>>({});

  useEffect(() => {
    writeCollapsedPreference(collapsed);
    setOpenGroup(null);
  }, [collapsed]);

  useEffect(() => {
    if (!openGroup) return;
    function onKeyDown(e: KeyboardEvent) {
      if (e.key !== 'Escape') return;
      groupButtonRefs.current[openGroup]?.focus();
      setOpenGroup(null);
    }
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [openGroup]);

  function toggleGroup(title: string) {
    setOpenGroup((current) => (current === title ? null : title));
  }

  return (
    <aside className={collapsed ? 'admin-sidebar admin-sidebar--collapsed' : 'admin-sidebar'}>
      <div className="admin-sidebar__header">
        {!collapsed && <p className="brand-script">Aida Cafe</p>}
        <button
          type="button"
          className="admin-sidebar__toggle"
          aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          onClick={() => setCollapsed((c) => !c)}
        >
          {collapsed ? <PanelLeftOpen size={20} /> : <PanelLeftClose size={20} />}
        </button>
      </div>

      {!collapsed && (
        <>
          <p className="admin-product-title">Aida Office</p>
          <p className="layout-sub">{session.identity?.fullName ?? 'Admin'}</p>
        </>
      )}

      <nav aria-label="Admin modules" className="admin-nav">
        {ADMIN_NAV.map((group) => {
          const Icon = group.icon;
          const groupActive = group.items.some((item) =>
            isNavItemActive(location.pathname, item),
          );

          if (collapsed) {
            const isOpen = openGroup === group.title;
            return (
              <div key={group.title} className="admin-nav-group admin-nav-group--collapsed">
                <button
                  type="button"
                  ref={(el) => {
                    groupButtonRefs.current[group.title] = el;
                  }}
                  className={
                    groupActive
                      ? 'admin-nav-group__icon-btn admin-nav-group__icon-btn--active'
                      : 'admin-nav-group__icon-btn'
                  }
                  aria-haspopup="menu"
                  aria-expanded={isOpen}
                  aria-label={group.title}
                  onClick={() => toggleGroup(group.title)}
                >
                  <Icon size={20} />
                </button>
                {isOpen && (
                  <div className="admin-nav-flyout" role="menu">
                    <p className="admin-nav-flyout__title">{group.title}</p>
                    <ul className="admin-nav-list">
                      {group.items.map((item) => (
                        <li key={item.path}>
                          <NavLink
                            role="menuitem"
                            to={item.path}
                            className={({ isActive }) =>
                              isActive || (item.path === '/admin' && location.pathname === '/admin')
                                ? 'admin-nav-link admin-nav-link--active'
                                : 'admin-nav-link'
                            }
                            end={item.path === '/admin'}
                            onClick={() => setOpenGroup(null)}
                          >
                            {item.label}
                          </NavLink>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            );
          }

          return (
            <div key={group.title} className="admin-nav-group">
              <p className="admin-nav-group__title">
                <Icon size={16} aria-hidden="true" />
                {group.title}
              </p>
              <ul className="admin-nav-list">
                {group.items.map((item) => (
                  <li key={item.path}>
                    <NavLink
                      to={item.path}
                      className={({ isActive }) =>
                        isActive || (item.path === '/admin' && location.pathname === '/admin')
                          ? 'admin-nav-link admin-nav-link--active'
                          : 'admin-nav-link'
                      }
                      end={item.path === '/admin'}
                    >
                      {item.label}
                    </NavLink>
                  </li>
                ))}
              </ul>
            </div>
          );
        })}
      </nav>
    </aside>
  );
}
```

Note: clicking outside an open flyout to close it is handled for free — every item link's
`onClick` closes it, and clicking a different group icon or the same one again also closes/swaps
it. A true click-anywhere-else dismissal is deliberately not added: this sidebar has no other
interactive chrome behind it in the same stacking context that would make an open flyout feel
stuck, and adding a global `mousedown` listener would be extra complexity for a case the tests
don't need. (If real usage shows people expect click-outside-to-close, that's a one-effect
follow-up.)

In `src/layouts/layouts.css`, append:

```css
.admin-nav-group--collapsed {
  position: relative;
}

.admin-sidebar--collapsed {
  overflow: visible;
}

.admin-nav-group__icon-btn--active {
  background: var(--aida-burgundy);
  color: var(--aida-floral-pink);
}

.admin-nav-flyout {
  position: absolute;
  left: calc(100% + var(--aida-space-2));
  top: 0;
  z-index: 30;
  min-width: 12rem;
  background: var(--aida-surface);
  color: var(--aida-espresso);
  border-radius: var(--aida-radius);
  box-shadow: var(--aida-shadow-lg);
  padding: var(--aida-space-3);
}

.admin-nav-flyout__title {
  margin: 0 0 var(--aida-space-2);
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--aida-taupe);
}

.admin-nav-flyout .admin-nav-link {
  color: var(--aida-burgundy);
}

.admin-nav-flyout .admin-nav-link:hover {
  background: var(--aida-blush);
  color: var(--aida-espresso);
}

.admin-nav-flyout .admin-nav-link--active {
  background: var(--aida-blush);
  color: var(--aida-burgundy);
}
```

(The earlier `.admin-nav-group--collapsed { display: flex; justify-content: center; }` rule from
Task 3 stays — this adds `position: relative` as a second rule on the same selector, so the
icon button stays centered and the flyout anchors correctly. `.admin-sidebar--collapsed`
similarly gains an `overflow: visible` rule alongside its Task 3 width rules, so the flyout isn't
clipped by the sidebar's own bounds.)

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test -- src/layouts/AdminSidebar.test.tsx`
Expected: PASS (all 11 tests)

- [ ] **Step 5: Commit**

```bash
git add src/layouts/AdminSidebar.tsx src/layouts/AdminSidebar.test.tsx src/layouts/layouts.css
git commit -m "Add click-to-open group flyouts to the collapsed admin rail"
```

---

### Task 5: Footer identity chip, full verification, and manual check

**Files:**
- Modify: `src/layouts/AdminSidebar.tsx`
- Modify: `src/layouts/AdminSidebar.test.tsx`
- Modify: `src/layouts/layouts.css`

**Interfaces:**
- No new exports or consumers — this is the final visual polish pass plus whole-suite
  verification.

- [ ] **Step 1: Write the failing test**

Append to `src/layouts/AdminSidebar.test.tsx`:

```tsx
describe('AdminSidebar (footer identity)', () => {
  it('shows a footer avatar initial in both modes, and the full name only when expanded', async () => {
    const user = userEvent.setup();
    renderSidebar();

    expect(screen.getByTestId('admin-sidebar-avatar')).toHaveTextContent('A');
    expect(screen.getByTestId('admin-sidebar-footer-name')).toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: 'Collapse sidebar' }));

    expect(screen.getByTestId('admin-sidebar-avatar')).toHaveTextContent('A');
    expect(screen.queryByTestId('admin-sidebar-footer-name')).not.toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test -- src/layouts/AdminSidebar.test.tsx`
Expected: FAIL — no element with `data-testid="admin-sidebar-avatar"` exists yet.

- [ ] **Step 3: Write minimal implementation**

In `src/layouts/AdminSidebar.tsx`:

1. Remove this block (the identity line moves to the footer instead):

```tsx
      {!collapsed && (
        <>
          <p className="admin-product-title">Aida Office</p>
          <p className="layout-sub">{session.identity?.fullName ?? 'Admin'}</p>
        </>
      )}
```

Replace it with just the product title (identity moves out of here):

```tsx
      {!collapsed && <p className="admin-product-title">Aida Office</p>}
```

2. Add a footer after the closing `</nav>` tag, still inside `<aside>...</aside>`:

```tsx
      <div className="admin-sidebar__footer">
        <span className="admin-sidebar__avatar" data-testid="admin-sidebar-avatar" aria-hidden="true">
          {(session.identity?.fullName ?? 'Admin').charAt(0).toUpperCase()}
        </span>
        {!collapsed && (
          <span className="admin-sidebar__footer-name" data-testid="admin-sidebar-footer-name">
            {session.identity?.fullName ?? 'Admin'}
          </span>
        )}
      </div>
```

In `src/layouts/layouts.css`, append:

```css
.admin-sidebar__footer {
  margin-top: auto;
  padding-top: var(--aida-space-4);
  border-top: 1px solid color-mix(in srgb, var(--aida-cream) 20%, transparent);
  display: flex;
  align-items: center;
  gap: var(--aida-space-2);
}

.admin-sidebar--collapsed .admin-sidebar__footer {
  justify-content: center;
}

.admin-sidebar__avatar {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 2rem;
  height: 2rem;
  border-radius: 999px;
  background: var(--aida-floral-pink);
  color: var(--aida-espresso);
  font-weight: 700;
  font-size: 0.85rem;
  flex-shrink: 0;
}

.admin-sidebar__footer-name {
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--aida-cream);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test -- src/layouts/AdminSidebar.test.tsx`
Expected: PASS (all 12 tests)

- [ ] **Step 5: Run the full verification pass**

Run: `npm run test`
Expected: all suites PASS, including `src/features/pos/cartPermissions.test.tsx` and the a11y
tests.

Run: `npm run typecheck`
Expected: no errors (confirms `lucide-react`'s types and the `LucideIcon` type import resolve
correctly).

Run: `npm run lint`
Expected: no errors (confirms the new `<button>`-based flyout triggers don't trip
`react/rules-of-hooks` or other configured rules).

- [ ] **Step 6: Manual check in the browser**

Run: `npm run dev`, open the admin dashboard (e.g. `http://localhost:5173/admin` after signing
in via UI Preview Mode), and confirm:
- Sidebar shows icons next to each group title, active page has a filled pill highlight.
- Clicking the collapse toggle shrinks it to a narrow icon rail.
- Clicking a group icon while collapsed opens a flyout with that group's pages; clicking a page
  navigates there and closes the flyout.
- Reloading the page keeps whichever collapsed/expanded state you left it in.

- [ ] **Step 7: Commit**

```bash
git add src/layouts/AdminSidebar.tsx src/layouts/AdminSidebar.test.tsx src/layouts/layouts.css
git commit -m "Move admin sidebar identity chip to a bottom-anchored footer"
```
