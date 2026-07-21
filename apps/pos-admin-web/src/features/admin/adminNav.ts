export interface AdminNavItem {
  label: string;
  path: string;
}

export interface AdminNavGroup {
  title: string;
  items: AdminNavItem[];
}

export const ADMIN_NAV: AdminNavGroup[] = [
  {
    title: 'Overview',
    items: [
      { label: 'Dashboard', path: '/admin' },
      { label: 'Live Ops', path: '/admin/live' },
    ],
  },
  {
    title: 'Reports',
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
    items: [
      { label: 'Branches', path: '/admin/operations/branches' },
      { label: 'Terminals', path: '/admin/operations/terminals' },
      { label: 'Shifts', path: '/admin/operations/shifts' },
      { label: 'Employees', path: '/admin/operations/employees' },
    ],
  },
  {
    title: 'Catalogue',
    items: [
      { label: 'Menu', path: '/admin/catalogue/menu' },
      { label: 'Categories', path: '/admin/catalogue/categories' },
      { label: 'Variants', path: '/admin/catalogue/variants' },
    ],
  },
  {
    title: 'Inventory',
    items: [
      { label: 'Stock', path: '/admin/inventory/stock' },
      { label: 'Recipes', path: '/admin/inventory/recipes' },
      { label: 'Wastage', path: '/admin/inventory/wastage' },
    ],
  },
  {
    title: 'Rewards',
    items: [
      { label: 'Loyalty', path: '/admin/rewards/loyalty' },
      { label: 'Stamps', path: '/admin/rewards/stamps' },
      { label: 'Offers', path: '/admin/rewards/offers' },
      { label: 'Campaigns', path: '/admin/rewards/campaigns' },
    ],
  },
  {
    title: 'System',
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
