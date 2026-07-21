/** Deterministic UI preview domain — Team 2 report semantics benchmark. Not production authority. */

export type PreviewCategory = 'All' | 'Coffee' | 'Iced Drinks' | 'Tea' | 'Food' | 'Pastries' | 'Favourites';
export type OrderType = 'dine_in' | 'takeaway' | 'pickup';
export type ConnectionState = 'online' | 'degraded' | 'offline' | 'syncing';
export type StudentVerification = 'verified' | 'pending' | 'expired' | 'not_applicable';

export interface PreviewMenuItem {
  id: string;
  name: string;
  category: PreviewCategory;
  priceSen: number;
  available: boolean;
  bestSeller?: boolean;
  sku: string;
  route: 'bar' | 'kitchen';
  imageTone: string;
  compactLabel: string;
}

export interface PreviewRewardOption {
  id: string;
  label: string;
  kind: 'voucher' | 'free_drink' | 'free_pastry' | 'offer';
  /** Points cost if points redemption; null if stamp/offer */
  pointsCost: number | null;
  expiresOn: string;
  eligible: boolean;
  rejectReason?: string;
}

export interface PreviewMember {
  id: string;
  displayName: string;
  kind: 'student' | 'general';
  active: boolean;
  studentVerification: StudentVerification;
  points: number;
  stamps: number;
  /** Master PRD: every 10 stamps → 1 free drink; counter resets */
  stampGoal: number;
  memberCode: string;
  rewards: PreviewRewardOption[];
}

export interface UiConceptModifierOption {
  id: string;
  label: string;
  priceDeltaSen: number;
  available?: boolean;
}

export interface UiConceptModifierGroup {
  id: string;
  name: string;
  required: boolean;
  min: number;
  max: number;
  help?: string;
  options: UiConceptModifierOption[];
}

/** Master PRD reward rules mirrored for preview labels (RM 1 = 1 pt; 10 stamps = free drink). */
export const PREVIEW_REWARD_RULES = {
  pointsPerRm: 1,
  stampsPerPurchase: 1,
  stampsForFreeDrink: 10,
  vouchers: [
    { label: 'RM 5 voucher', points: 100 },
    { label: 'RM 10 voucher', points: 180 },
    { label: 'Free pastry', points: 150 },
  ],
  note: 'Preview labels match master PRD. Free drink unlock threshold: 10 stamps. Product decision pending if merchant changes threshold.',
} as const;

export const PREVIEW_CATEGORIES: PreviewCategory[] = [
  'All',
  'Favourites',
  'Coffee',
  'Iced Drinks',
  'Tea',
  'Pastries',
  'Food',
];

export const PREVIEW_MENU: PreviewMenuItem[] = [
  { id: 'scl', name: 'Salted Caramel Latte', category: 'Favourites', priceSen: 1290, available: true, bestSeller: true, sku: 'CF-SCL', route: 'bar', imageTone: '#C92F50', compactLabel: 'SCL' },
  { id: 'latte', name: 'Latte', category: 'Coffee', priceSen: 1050, available: true, sku: 'CF-LAT', route: 'bar', imageTone: '#541A28', compactLabel: 'LAT' },
  { id: 'americano', name: 'Americano', category: 'Coffee', priceSen: 850, available: true, sku: 'CF-AME', route: 'bar', imageTone: '#2C171B', compactLabel: 'AME' },
  { id: 'capp', name: 'Cappuccino', category: 'Coffee', priceSen: 950, available: true, sku: 'CF-CAP', route: 'bar', imageTone: '#9A7F7A', compactLabel: 'CAP' },
  { id: 'mocha', name: 'Mocha', category: 'Coffee', priceSen: 1150, available: true, sku: 'CF-MOC', route: 'bar', imageTone: '#6B3A2A', compactLabel: 'MOC' },
  { id: 'iced-latte', name: 'Iced Latte', category: 'Iced Drinks', priceSen: 1150, available: true, sku: 'IC-LAT', route: 'bar', imageTone: '#5B7C99', compactLabel: 'ICE' },
  { id: 'rose-tea', name: 'Rose Lychee Tea', category: 'Tea', priceSen: 980, available: true, sku: 'TE-RLT', route: 'bar', imageTone: '#DE8D9D', compactLabel: 'RLT' },
  { id: 'croissant', name: 'Butter Croissant', category: 'Pastries', priceSen: 750, available: true, bestSeller: true, sku: 'PA-CRO', route: 'kitchen', imageTone: '#C8A345', compactLabel: 'CRO' },
  { id: 'wrap', name: 'Chicken Wrap', category: 'Food', priceSen: 1450, available: false, sku: 'FD-WRP', route: 'kitchen', imageTone: '#36735B', compactLabel: 'WRP' },
  { id: 'nuts', name: 'Trail Mix Cup', category: 'Food', priceSen: 650, available: true, sku: 'FD-NUT', route: 'kitchen', imageTone: '#B7782F', compactLabel: 'NUT' },
];

export const PREVIEW_MODIFIER_GROUPS: UiConceptModifierGroup[] = [
  {
    id: 'size',
    name: 'Size',
    required: true,
    min: 1,
    max: 1,
    help: 'Choose one size',
    options: [
      { id: 's', label: 'Small', priceDeltaSen: -50 },
      { id: 'm', label: 'Medium', priceDeltaSen: 0 },
      { id: 'l', label: 'Large', priceDeltaSen: 150 },
    ],
  },
  {
    id: 'milk',
    name: 'Milk',
    required: true,
    min: 1,
    max: 1,
    help: 'Required',
    options: [
      { id: 'whole', label: 'Whole milk', priceDeltaSen: 0 },
      { id: 'oat', label: 'Oat milk', priceDeltaSen: 150 },
      { id: 'soy', label: 'Soy milk', priceDeltaSen: 150 },
      { id: 'almond', label: 'Almond milk', priceDeltaSen: 150, available: false },
    ],
  },
  {
    id: 'sugar',
    name: 'Sugar',
    required: false,
    min: 0,
    max: 1,
    help: 'Optional · max 1',
    options: [
      { id: 'less', label: 'Less sugar', priceDeltaSen: 0 },
      { id: 'normal', label: 'Normal', priceDeltaSen: 0 },
      { id: 'extra', label: 'Extra sugar', priceDeltaSen: 0 },
    ],
  },
  {
    id: 'temp',
    name: 'Temperature',
    required: false,
    min: 0,
    max: 1,
    options: [
      { id: 'hot', label: 'Hot', priceDeltaSen: 0 },
      { id: 'iced', label: 'Iced', priceDeltaSen: 0 },
    ],
  },
  {
    id: 'extras',
    name: 'Extras',
    required: false,
    min: 0,
    max: 3,
    help: 'Optional · up to 3',
    options: [
      { id: 'shot', label: 'Extra shot', priceDeltaSen: 200 },
      { id: 'vanilla', label: 'Vanilla syrup', priceDeltaSen: 100 },
      { id: 'caramel', label: 'Caramel syrup', priceDeltaSen: 100 },
    ],
  },
];

export const PREVIEW_MEMBERS: PreviewMember[] = [
  {
    id: 'm-student',
    displayName: 'Aisyah Lim',
    kind: 'student',
    active: true,
    studentVerification: 'verified',
    points: 420,
    stamps: 7,
    stampGoal: 10,
    memberCode: 'STU-1042',
    rewards: [
      {
        id: 'r-student-ice',
        label: 'Student iced drink RM2 off',
        kind: 'offer',
        pointsCost: null,
        expiresOn: '31 Aug 2026',
        eligible: true,
      },
      {
        id: 'r-pastry-pts',
        label: 'Free pastry (150 pts)',
        kind: 'free_pastry',
        pointsCost: 150,
        expiresOn: '31 Aug 2026',
        eligible: true,
      },
      {
        id: 'r-free-drink-locked',
        label: 'Free drink (10 stamps)',
        kind: 'free_drink',
        pointsCost: null,
        expiresOn: '—',
        eligible: false,
        rejectReason: 'Needs 3 more stamps (7/10)',
      },
    ],
  },
  {
    id: 'm-general',
    displayName: 'Daniel Ong',
    kind: 'general',
    active: true,
    studentVerification: 'not_applicable',
    points: 180,
    stamps: 3,
    stampGoal: 10,
    memberCode: 'GEN-2210',
    rewards: [
      {
        id: 'r-rm5',
        label: 'RM 5 voucher (100 pts)',
        kind: 'voucher',
        pointsCost: 100,
        expiresOn: '15 Sep 2026',
        eligible: true,
      },
      {
        id: 'r-student-only',
        label: 'Student iced drink RM2 off',
        kind: 'offer',
        pointsCost: null,
        expiresOn: '31 Aug 2026',
        eligible: false,
        rejectReason: 'Student members only',
      },
    ],
  },
  {
    id: 'm-inactive',
    displayName: 'Inactive Member',
    kind: 'general',
    active: false,
    studentVerification: 'expired',
    points: 0,
    stamps: 0,
    stampGoal: 10,
    memberCode: 'GEN-0000',
    rewards: [],
  },
];

export interface PreviewTxn {
  order: string;
  when: string;
  staff: string;
  salesPoint: 'Main Counter' | 'Snack Station';
  method: 'Cash' | 'Card' | 'E-wallet';
  /** Net line total charged (sen) */
  totalSen: number;
  status: 'Completed' | 'Refunded' | 'Voided';
  member?: string;
  discountSen: number;
  refundSen: number;
}

export const PREVIEW_TRANSACTIONS: PreviewTxn[] = [
  { order: 'A-10521', when: '21 Jul 2026 10:14', staff: 'Nadia', salesPoint: 'Main Counter', method: 'Cash', totalSen: 38900, status: 'Completed', member: 'Aisyah Lim', discountSen: 2000, refundSen: 0 },
  { order: 'A-10520', when: '21 Jul 2026 10:02', staff: 'Nadia', salesPoint: 'Main Counter', method: 'E-wallet', totalSen: 25700, status: 'Completed', discountSen: 0, refundSen: 0 },
  { order: 'A-10519', when: '21 Jul 2026 09:48', staff: 'Hafiz', salesPoint: 'Snack Station', method: 'Card', totalSen: 19800, status: 'Completed', discountSen: 0, refundSen: 0 },
  { order: 'A-10518', when: '21 Jul 2026 09:31', staff: 'Nadia', salesPoint: 'Main Counter', method: 'Cash', totalSen: 45200, status: 'Completed', member: 'Daniel Ong', discountSen: 5000, refundSen: 0 },
  { order: 'A-10517', when: '21 Jul 2026 09:12', staff: 'Hafiz', salesPoint: 'Snack Station', method: 'E-wallet', totalSen: 32000, status: 'Completed', discountSen: 0, refundSen: 0 },
  { order: 'A-10516', when: '21 Jul 2026 08:55', staff: 'Nadia', salesPoint: 'Main Counter', method: 'Card', totalSen: 61000, status: 'Completed', discountSen: 0, refundSen: 0 },
  { order: 'A-10515', when: '21 Jul 2026 08:40', staff: 'Nadia', salesPoint: 'Main Counter', method: 'Cash', totalSen: 27500, status: 'Completed', discountSen: 0, refundSen: 0 },
  { order: 'A-10514', when: '21 Jul 2026 08:22', staff: 'Hafiz', salesPoint: 'Snack Station', method: 'Cash', totalSen: 18900, status: 'Completed', discountSen: 0, refundSen: 0 },
  { order: 'A-10513', when: '21 Jul 2026 08:05', staff: 'Nadia', salesPoint: 'Main Counter', method: 'E-wallet', totalSen: 54000, status: 'Completed', member: 'Aisyah Lim', discountSen: 2000, refundSen: 0 },
  { order: 'A-10512', when: '21 Jul 2026 07:50', staff: 'Hafiz', salesPoint: 'Snack Station', method: 'Card', totalSen: 41000, status: 'Completed', discountSen: 0, refundSen: 0 },
  { order: 'A-10511', when: '21 Jul 2026 07:35', staff: 'Nadia', salesPoint: 'Main Counter', method: 'Cash', totalSen: 36800, status: 'Completed', discountSen: 0, refundSen: 0 },
  { order: 'A-10510', when: '21 Jul 2026 07:18', staff: 'Nadia', salesPoint: 'Main Counter', method: 'E-wallet', totalSen: 29500, status: 'Completed', discountSen: 0, refundSen: 0 },
  { order: 'A-10509', when: '21 Jul 2026 07:02', staff: 'Hafiz', salesPoint: 'Snack Station', method: 'Cash', totalSen: 22000, status: 'Refunded', discountSen: 0, refundSen: 22000 },
  { order: 'A-10508', when: '21 Jul 2026 06:48', staff: 'Nadia', salesPoint: 'Main Counter', method: 'Card', totalSen: 63000, status: 'Completed', discountSen: 0, refundSen: 0 },
];

function sumTx(periodRows: PreviewTxn[]) {
  const completed = periodRows.filter((t) => t.status === 'Completed');
  const discountsSen = periodRows.reduce((s, t) => s + t.discountSen, 0);
  const refundsSen = periodRows.reduce((s, t) => s + t.refundSen, 0);
  const netSalesSen = completed.reduce((s, t) => s + t.totalSen, 0);
  const grossSalesSen = netSalesSen + discountsSen + refundsSen;
  const cashSalesSen = completed.filter((t) => t.method === 'Cash').reduce((s, t) => s + t.totalSen, 0);
  const nonCashSalesSen = completed.filter((t) => t.method !== 'Cash').reduce((s, t) => s + t.totalSen, 0);
  const orders = completed.length;
  return {
    grossSalesSen,
    discountsSen,
    refundsSen,
    netSalesSen,
    orders,
    aovSen: orders ? Math.round(netSalesSen / orders) : 0,
    cashSalesSen,
    nonCashSalesSen,
    openShifts: 2,
    varianceAlerts: 1,
    pointsIssued: Math.round(netSalesSen / 100),
    stampsIssued: orders,
    rewardRedemptions: periodRows.filter((t) => t.discountSen > 0).length,
  };
}

/** Derived from PREVIEW_TRANSACTIONS — keep dashboard/reports in sync. */
export const FIXTURE_TODAY = sumTx(PREVIEW_TRANSACTIONS);

/** Month = today × ~25 for demo scale (labelled sample). */
export const FIXTURE_MONTH = {
  grossSalesSen: FIXTURE_TODAY.grossSalesSen * 25,
  discountsSen: FIXTURE_TODAY.discountsSen * 25,
  refundsSen: FIXTURE_TODAY.refundsSen * 25,
  netSalesSen: FIXTURE_TODAY.netSalesSen * 25,
  orders: FIXTURE_TODAY.orders * 25,
  aovSen: FIXTURE_TODAY.aovSen,
  cashSalesSen: FIXTURE_TODAY.cashSalesSen * 25,
  nonCashSalesSen: FIXTURE_TODAY.nonCashSalesSen * 25,
  openShifts: 2,
  varianceAlerts: 1,
  pointsIssued: FIXTURE_TODAY.pointsIssued * 25,
  stampsIssued: FIXTURE_TODAY.stampsIssued * 25,
  rewardRedemptions: FIXTURE_TODAY.rewardRedemptions * 25,
} as const;

export const PREVIEW_SALES_BY_POINT = (() => {
  const completed = PREVIEW_TRANSACTIONS.filter((t) => t.status === 'Completed');
  const main = completed.filter((t) => t.salesPoint === 'Main Counter').reduce((s, t) => s + t.totalSen, 0);
  const snack = completed.filter((t) => t.salesPoint === 'Snack Station').reduce((s, t) => s + t.totalSen, 0);
  return [
    { point: 'Main Counter', sen: main },
    { point: 'Snack Station', sen: snack },
  ];
})();

/** Alias for POS orders rail */
export const PREVIEW_SALES_ROWS = PREVIEW_TRANSACTIONS.map((t) => ({
  order: t.order,
  when: t.when,
  staff: t.staff,
  salesPoint: t.salesPoint,
  method: t.method,
  totalSen: t.totalSen,
  status: t.status,
  member: t.member,
}));

export interface PreviewKpi {
  label: string;
  value: string;
  hint: string;
}

function rm(sen: number) {
  return `RM ${(sen / 100).toLocaleString('en-MY', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

export function overviewKpis(period: 'today' | 'month'): PreviewKpi[] {
  const d = period === 'today' ? FIXTURE_TODAY : FIXTURE_MONTH;
  return [
    { label: 'Gross sales', value: rm(d.grossSalesSen), hint: 'Before discounts · sample' },
    { label: 'Discounts / rewards', value: rm(d.discountsSen), hint: 'Sample' },
    { label: 'Refunds / voids', value: rm(d.refundsSen), hint: 'Sample impact' },
    { label: 'Net sales', value: rm(d.netSalesSen), hint: 'Gross − discounts − refunds' },
    { label: 'Orders', value: String(d.orders), hint: period === 'today' ? 'Today' : 'This month' },
    { label: 'Avg order value', value: rm(d.aovSen), hint: 'Net ÷ orders' },
    { label: 'Cash sales', value: rm(d.cashSalesSen), hint: 'Soft POS · sample' },
    { label: 'Non-cash sales', value: rm(d.nonCashSalesSen), hint: 'Card + e-wallet' },
    { label: 'Open shifts', value: String(d.openShifts), hint: 'Main Café' },
    { label: 'Variance alerts', value: String(d.varianceAlerts), hint: 'Needs attention' },
  ];
}

export const PREVIEW_OVERVIEW_KPIS = overviewKpis('today');

export const PREVIEW_HOURLY_SALES = [12, 28, 45, 62, 58, 71, 55, 48, 42, 38, 29, 18];

export interface PreviewTerminal {
  id: string;
  code: string;
  branch: string;
  salesPoint: string;
  status: 'active' | 'revoked' | 'pending';
  lastSeen?: string;
  heartbeat?: string;
  printer?: string;
  kds?: string;
  paymentDevice?: string;
}

export const PREVIEW_TERMINALS: PreviewTerminal[] = [
  { id: 't1', code: 'POS-MAIN-01', branch: 'Main Café', salesPoint: 'Main Counter', status: 'active', lastSeen: 'Today 10:12', heartbeat: '8s ago', printer: 'Online', kds: 'Online', paymentDevice: 'Ready' },
  { id: 't2', code: 'POS-SNACK-01', branch: 'Main Café', salesPoint: 'Snack Station', status: 'active', lastSeen: 'Today 09:55', heartbeat: '22s ago', printer: 'Degraded', kds: 'Online', paymentDevice: 'Ready' },
  { id: 't3', code: 'POS-MAIN-02', branch: 'Main Café', salesPoint: 'Main Counter', status: 'pending' },
];

export interface PreviewShiftRow {
  id: string;
  staff: string;
  terminal: string;
  salesPoint: string;
  status: 'open' | 'locked' | 'closed';
  openedAt: string;
  openingFloatSen: number;
  cashSalesSen: number;
  expectedSen: number | null;
  actualSen: number | null;
  varianceSen: number | null;
}

export const PREVIEW_SHIFT_ROWS: PreviewShiftRow[] = [
  { id: 's1', staff: 'Nadia', terminal: 'POS-MAIN-01', salesPoint: 'Main Counter', status: 'open', openedAt: 'Today 08:00', openingFloatSen: 10000, cashSalesSen: 128400, expectedSen: null, actualSen: null, varianceSen: null },
  { id: 's2', staff: 'Hafiz', terminal: 'POS-SNACK-01', salesPoint: 'Snack Station', status: 'locked', openedAt: 'Today 07:45', openingFloatSen: 8000, cashSalesSen: 69600, expectedSen: null, actualSen: null, varianceSen: null },
  { id: 's3', staff: 'Aina', terminal: 'POS-MAIN-01', salesPoint: 'Main Counter', status: 'closed', openedAt: 'Yesterday 14:00', openingFloatSen: 10000, cashSalesSen: 210000, expectedSen: 220000, actualSen: 216500, varianceSen: -3500 },
];

export interface PreviewEmployee {
  id: string;
  name: string;
  username: string;
  role: 'staff' | 'admin' | 'dual';
  branches: string[];
  isGlobalManager: boolean;
  active: boolean;
  permissions: string[];
}

export const PREVIEW_EMPLOYEES: PreviewEmployee[] = [
  { id: 'e1', name: 'Nadia Rahman', username: 'nadia', role: 'staff', branches: ['Main Café'], isGlobalManager: false, active: true, permissions: ['shift', 'sale', 'apply_reward', 'reprint'] },
  { id: 'e2', name: 'Hafiz Ali', username: 'hafiz', role: 'staff', branches: ['Main Café'], isGlobalManager: false, active: true, permissions: ['shift', 'sale', 'apply_reward'] },
  { id: 'e3', name: 'Siti Manager', username: 'siti', role: 'admin', branches: ['Main Café'], isGlobalManager: true, active: true, permissions: ['reports', 'catalogue', 'employees', 'terminals', 'audit', 'approve_variance'] },
  { id: 'e4', name: 'Amir Dual', username: 'amir', role: 'dual', branches: ['Main Café'], isGlobalManager: false, active: true, permissions: ['shift', 'sale', 'reports_branch'] },
];

export const PREVIEW_ORG = {
  organisation: 'Aida Café',
  inventoryCode: 'INV-MAIN',
  branches: [
    {
      id: 'br-main',
      name: 'Main Café',
      code: 'BR-MAIN',
      status: 'open' as const,
      hours: '07:00–22:00 MYT',
      orderTypes: ['Dine-in', 'Takeaway', 'Pickup'],
      salesPoints: [
        { id: 'sp-main', name: 'Main Counter', code: 'SP-MAIN', terminals: ['POS-MAIN-01', 'POS-MAIN-02'], inventory: 'INV-MAIN' },
        { id: 'sp-snack', name: 'Snack Station', code: 'SP-SNACK', terminals: ['POS-SNACK-01'], inventory: 'INV-MAIN' },
      ],
    },
  ],
};

export const PREVIEW_VARIANCE_THRESHOLD_SEN = 2000;
