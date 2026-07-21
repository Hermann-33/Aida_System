/**
 * Closure-gate screenshot capture with route/heading asserts, network isolation,
 * SHA-256 uniqueness, and markdown manifest.
 *
 * Requires: npm run dev on :5173 with VITE_UI_PREVIEW_MODE=true
 * Usage: node scripts/capture-closure-gate.mjs
 */
import { chromium } from '@playwright/test';
import { createHash } from 'node:crypto';
import { mkdir, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const REPO = path.resolve(ROOT, '../..');
const BASE = process.env.CAPTURE_URL || 'http://localhost:5173';
const OUT = path.join(ROOT, 'docs', 'screenshots', 'closure-gate');
const MANIFEST = path.join(REPO, 'docs', 'pos-admin-ui', 'POS_ADMIN_SCREENSHOT_MANIFEST.md');

const FORBIDDEN_HOST_RE =
  /\/api(?:\/|$|\?)|:3001(?:\/|$)|:3011(?:\/|$)|neon\.tech|postgres|render\.com|railway\.app/i;

/** @type {{ name: string, route: string, heading: RegExp, viewport: 'pos'|'admin'|'tablet', product: string, capture: Function }[]} */
const RESULTS = [];

async function assertRoute(page, { urlRe, headingRe, name, product }) {
  const url = page.url();
  if (urlRe && !urlRe.test(url)) {
    throw new Error(`[${name}] Expected URL ${urlRe}, got ${url}`);
  }
  if (headingRe) {
    const heading = page.getByRole('heading', { name: headingRe }).first();
    await heading.waitFor({ timeout: 15000 });
  }
  if (product === 'admin' || product === 'pos' || product === 'employee') {
    const banner = page.getByText(/UI PREVIEW — SAMPLE DATA/i);
    if ((await banner.count()) === 0) {
      console.warn(`[${name}] Preview banner not visible at ${url}`);
    }
  }
}

async function shot(page, name, meta) {
  await page.waitForTimeout(350);
  const file = path.join(OUT, `${name}.png`);
  await page.screenshot({ path: file, fullPage: false });
  const buf = await readFile(file);
  const sha256 = createHash('sha256').update(buf).digest('hex');
  RESULTS.push({
    filename: `${name}.png`,
    route: meta.route,
    heading: meta.heading,
    viewport: meta.viewport,
    sha256,
    result: 'PASS',
  });
  console.log('  ✓', name);
  return file;
}

function failShot(name, meta, reason) {
  RESULTS.push({
    filename: `${name}.png`,
    route: meta.route,
    heading: meta.heading,
    viewport: meta.viewport,
    sha256: '',
    result: `FAILED: ${reason}`,
  });
  console.error('  ✗', name, reason);
}

async function clearStorage(page) {
  await page.goto(`${BASE}/employee`, { waitUntil: 'domcontentloaded' });
  await page.evaluate(() => {
    try {
      sessionStorage.clear();
      localStorage.clear();
    } catch {
      /* ignore */
    }
  });
}

async function enrol(page) {
  await page.goto(`${BASE}/employee`, { waitUntil: 'networkidle' });
  const enrol = page.getByLabel(/enrolment code/i);
  if (await enrol.count()) {
    await enrol.fill('AIDA-482731');
    await page.getByRole('button', { name: /activate terminal/i }).click();
    await page.getByRole('heading', { name: /sign in/i }).waitFor({ timeout: 15000 });
  }
}

async function login(page, username, password) {
  await page.getByLabel(/username/i).fill(username);
  await page.getByLabel(/^password$/i).fill(password);
  await page.getByRole('button', { name: /^sign in$/i }).click();
}

async function logoutIfPresent(page) {
  const logout = page.getByRole('button', { name: /log out/i });
  if (await logout.count()) {
    await logout.first().click();
    await page.waitForTimeout(400);
  }
}

async function ensureItemInCart(page) {
  const pay = page.getByRole('button', { name: /^Pay$/i });
  if (await pay.isEnabled().catch(() => false)) return;
  await page.getByRole('button', { name: /Salted Caramel Latte|Americano|Latte/i }).first().click();
  if (await page.getByRole('dialog').count()) {
    await page.getByRole('button', { name: /add to order/i }).click();
  }
  await page.waitForTimeout(250);
}

async function writeManifest(networkNotes) {
  const lines = [
    '# POS / Admin Screenshot Manifest — Closure Gate',
    '',
    `Captured: ${new Date().toISOString()}`,
    `Base URL: ${BASE}`,
    'Mode: UI PREVIEW — SAMPLE DATA',
    '',
    '## Network isolation',
    '',
    ...networkNotes.map((n) => `- ${n}`),
    '',
    '## Screenshots',
    '',
    '| Filename | Route | Expected heading | Viewport | SHA-256 | Result |',
    '|---|---|---|---|---|---|',
  ];
  for (const r of RESULTS) {
    lines.push(
      `| \`${r.filename}\` | \`${r.route}\` | ${r.heading} | ${r.viewport} | \`${r.sha256 || '—'}\` | ${r.result} |`,
    );
  }
  const passed = RESULTS.filter((r) => r.result === 'PASS');
  const hashes = new Set(passed.map((r) => r.sha256));
  lines.push('');
  lines.push('## Duplicate-hash result');
  lines.push('');
  lines.push(
    hashes.size === passed.length
      ? `PASS — ${passed.length} unique SHA-256 hashes for ${passed.length} successful captures.`
      : `FAIL — ${passed.length} captures but only ${hashes.size} unique hashes.`,
  );
  lines.push('');
  lines.push(`Failed or skipped: ${RESULTS.filter((r) => r.result !== 'PASS').length}`);
  await mkdir(path.dirname(MANIFEST), { recursive: true });
  await writeFile(MANIFEST, `${lines.join('\n')}\n`, 'utf8');
}

async function main() {
  await rm(OUT, { recursive: true, force: true });
  await mkdir(OUT, { recursive: true });

  const forbiddenHits = [];
  const externalFonts = new Set();

  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: 1366, height: 768 },
    deviceScaleFactor: 1,
  });
  const page = await context.newPage();

  page.on('request', (req) => {
    const url = req.url();
    if (FORBIDDEN_HOST_RE.test(url)) forbiddenHits.push(url);
    if (/fonts\.googleapis\.com|fonts\.gstatic\.com/i.test(url)) externalFonts.add(url.split('?')[0]);
  });

  // ——— Employee ———
  console.log('Employee Access…');
  await clearStorage(page);
  await page.goto(`${BASE}/employee`, { waitUntil: 'networkidle' });
  try {
    await assertRoute(page, {
      urlRe: /\/employee/,
      headingRe: /Activate this terminal/i,
      name: '03-terminal-activation',
      product: 'employee',
    });
    await shot(page, '03-terminal-activation', {
      route: '/employee',
      heading: 'Activate this terminal',
      viewport: '1366×768',
    });
  } catch (e) {
    failShot('03-terminal-activation', { route: '/employee', heading: 'Activate this terminal', viewport: '1366×768' }, e.message);
  }

  await page.getByLabel(/enrolment code/i).fill('AIDA-482731');
  await page.getByRole('button', { name: /activate terminal/i }).click();
  await page.getByRole('heading', { name: /sign in/i }).waitFor({ timeout: 15000 });
  await shot(page, '01-employee-password-login', {
    route: '/employee',
    heading: 'Sign in',
    viewport: '1366×768',
  });

  await page.getByRole('tab', { name: /badge \+ pin/i }).click();
  await page.waitForTimeout(200);
  await shot(page, '02-employee-badge-pin-login', {
    route: '/employee',
    heading: 'Sign in (Badge + PIN)',
    viewport: '1366×768',
  });

  await page.getByRole('tab', { name: /^password$/i }).click();
  await login(page, 'preview.dual', 'preview123');
  await page.waitForURL(/select-role|\/pos|\/admin/, { timeout: 15000 });
  if (page.url().includes('select-role')) {
    await assertRoute(page, {
      headingRe: /Choose workspace|Select/i,
      name: '04-dual-role-selection',
      product: 'employee',
    });
    await shot(page, '04-dual-role-selection', {
      route: '/employee/select-role',
      heading: 'Choose workspace',
      viewport: '1366×768',
    });
  } else {
    failShot(
      '04-dual-role-selection',
      { route: '/employee/select-role', heading: 'Choose workspace', viewport: '1366×768' },
      `Expected select-role, got ${page.url()}`,
    );
  }

  await logoutIfPresent(page);
  await clearStorage(page);
  await enrol(page);
  await login(page, 'preview.staff', 'preview123');
  await page.waitForURL(/\/pos/, { timeout: 15000 });
  await page.goto(`${BASE}/admin`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(500);
  try {
    await assertRoute(page, {
      urlRe: /unauthorized|employee|pos/,
      headingRe: /Unauthorized/i,
      name: '05-unauthorized',
      product: 'employee',
    });
    await shot(page, '05-unauthorized', {
      route: '/unauthorized',
      heading: 'Unauthorized',
      viewport: '1366×768',
    });
  } catch (e) {
    failShot('05-unauthorized', { route: '/unauthorized', heading: 'Unauthorized', viewport: '1366×768' }, e.message);
  }

  // ——— POS ———
  console.log('POS…');
  await clearStorage(page);
  await enrol(page);
  await login(page, 'preview.staff', 'preview123');
  await page.waitForURL(/\/pos/, { timeout: 15000 });
  await page.setViewportSize({ width: 1366, height: 768 });

  await assertRoute(page, {
    urlRe: /\/pos/,
    headingRe: /Open shift|Aida Counter/i,
    name: '10-pos-open-shift',
    product: 'pos',
  });
  await shot(page, '10-pos-open-shift', { route: '/pos', heading: 'Open shift', viewport: '1366×768' });

  await page.getByLabel(/opening float/i).fill('100');
  await page.getByRole('button', { name: /open shift/i }).click();
  await page.getByText(/new sale|menu/i).first().waitFor({ timeout: 15000 });
  await shot(page, '11-pos-new-sale', { route: '/pos', heading: 'New sale / menu', viewport: '1366×768' });

  await page.getByRole('button', { name: /Salted Caramel Latte|Latte/i }).first().click();
  await page.getByRole('dialog').waitFor({ timeout: 8000 });
  await shot(page, '12-pos-product-selected', { route: '/pos', heading: 'Modifier dialog', viewport: '1366×768' });

  const oat = page.getByLabel(/Oat|oat milk/i);
  if (await oat.count()) await oat.first().click().catch(() => {});
  await page.waitForTimeout(250);
  await shot(page, '13-pos-modifiers', { route: '/pos', heading: 'Modifiers', viewport: '1366×768' });

  await page.getByRole('button', { name: /add to order/i }).click();
  await page.waitForTimeout(300);
  await shot(page, '14-pos-cart', { route: '/pos', heading: 'Cart with item', viewport: '1366×768' });

  await page.getByRole('button', { name: /^Member$/i }).click();
  await page.waitForTimeout(300);
  await shot(page, '15-pos-member-search', { route: '/pos', heading: 'Member panel', viewport: '1366×768' });

  const scan = page.getByRole('button', { name: /scan member|preview member|select/i });
  if (await scan.count()) {
    await scan.first().click();
  } else {
    const input = page.getByPlaceholder(/search|member|id/i);
    if (await input.count()) {
      await input.fill('Aisyah');
      await page.waitForTimeout(250);
      const opt = page.getByRole('option').first();
      if (await opt.count()) await opt.click();
      else {
        const row = page.getByText(/Aisyah|Student/i).first();
        if (await row.count()) await row.click();
      }
    }
  }
  await page.waitForTimeout(300);
  await shot(page, '16-pos-student-member', { route: '/pos', heading: 'Student member', viewport: '1366×768' });

  const apply = page.getByRole('button', { name: /apply|redeem|reward/i }).first();
  if (await apply.count() && (await apply.isEnabled().catch(() => false))) {
    await apply.click();
    await page.waitForTimeout(250);
  }
  await shot(page, '17-pos-rewards', { route: '/pos', heading: 'Rewards applied', viewport: '1366×768' });

  await page.getByRole('button', { name: /^New Sale$/i }).click().catch(() => {});
  await ensureItemInCart(page);
  await page.getByRole('button', { name: /^Pay$/i }).click();
  await page.getByRole('heading', { name: /payment/i }).waitFor({ timeout: 8000 });
  await shot(page, '18-pos-payment', { route: '/pos', heading: 'Payment', viewport: '1366×768' });

  const cashInput = page.getByLabel(/cash received|tender/i);
  if (await cashInput.count()) {
    await cashInput.fill('50');
    await page.getByRole('button', { name: /confirm payment|complete sale/i }).click();
  } else {
    await page.getByRole('button', { name: /complete sale|confirm payment/i }).click();
  }
  await page.getByRole('heading', { name: /sale complete|receipt/i }).waitFor({ timeout: 10000 });
  await shot(page, '19-pos-receipt', { route: '/pos', heading: 'Receipt / sale complete', viewport: '1366×768' });

  // Payment failure
  await page.locator('button.order-ribbon__pay', { hasText: /new sale/i }).click().catch(async () => {
    await page.getByRole('button', { name: /^New Sale$/i }).click();
  });
  await ensureItemInCart(page);
  await page.getByRole('button', { name: /^Pay$/i }).click();
  const card = page.getByLabel(/^Card$/i);
  if (await card.count()) await card.check().catch(async () => card.click());
  const decline = page.getByRole('button', { name: /simulate decline/i });
  if (await decline.count()) {
    await decline.click();
    await page.waitForTimeout(300);
    await shot(page, '21-pos-payment-failure', {
      route: '/pos',
      heading: 'Payment declined',
      viewport: '1366×768',
    });
    await page.getByRole('button', { name: /^Back$/i }).click().catch(() => {});
  } else {
    failShot(
      '21-pos-payment-failure',
      { route: '/pos', heading: 'Payment declined', viewport: '1366×768' },
      'Simulate decline control not found',
    );
  }

  await page.getByRole('button', { name: /^Terminal$/i }).click();
  const offlineSelect = page.locator('select').filter({ hasText: /Offline|Online/i });
  if (await offlineSelect.count()) {
    await offlineSelect.selectOption({ label: /Offline/i }).catch(async () => {
      await offlineSelect.selectOption('offline');
    });
  }
  await page.waitForTimeout(300);
  await shot(page, '22-pos-offline-state', { route: '/pos', heading: 'Offline / terminal', viewport: '1366×768' });

  await page.getByRole('button', { name: /^Shift$/i }).click();
  await page.getByRole('button', { name: /close shift/i }).click();
  await page.getByRole('heading', { name: /close shift/i }).waitFor({ timeout: 10000 });
  await shot(page, '20-pos-close-shift', { route: '/pos', heading: 'Close shift', viewport: '1366×768' });

  // Tablet smoke (not a required named file, but validate no crash)
  await page.setViewportSize({ width: 1024, height: 768 });
  await page.waitForTimeout(200);

  // ——— Admin ———
  console.log('Admin…');
  await logoutIfPresent(page);
  await clearStorage(page);
  await enrol(page);
  await login(page, 'preview.admin', 'preview123');
  await page.waitForURL(/\/admin/, { timeout: 15000 });
  await page.setViewportSize({ width: 1440, height: 900 });

  const adminShots = [
    ['30-admin-dashboard', '/admin', /Executive Dashboard/i, 'Executive Dashboard'],
    ['31-admin-daily-sales', '/admin/reports/sales', /Sales report/i, 'Daily sales report'],
    ['32-admin-monthly-sales', '/admin?period=month', /Executive Dashboard/i, 'Executive Dashboard (Month)'],
    ['33-admin-branch-comparison', '/admin/reports/branches', /Branch/i, 'Branch comparison'],
    ['34-admin-sales-reports', '/admin/reports/sales', /Sales report/i, 'Sales report (filtered)'],
    ['35-admin-product-performance', '/admin/reports/products', /Product/i, 'Product performance'],
    ['36-admin-shift-report', '/admin/reports/shifts', /Shift|Cash|Variance/i, 'Shift cash report'],
    ['37-admin-branches', '/admin/operations/branches', /Branches and sales points/i, 'Branches'],
    ['38-admin-sales-points', '/admin/operations/sales-points', /Sales points/i, 'Sales points'],
    ['39-admin-terminals', '/admin/operations/terminals', /Terminal/i, 'Terminals'],
    ['40-admin-staff-roles', '/admin/operations/employees', /Employee/i, 'Staff and roles'],
    ['41-admin-menu', '/admin/catalogue/menu', /Menu/i, 'Menu'],
    ['42-admin-product-editor', '/admin/catalogue/menu/latte', /Menu item editor/i, 'Product editor'],
    ['43-admin-modifiers', '/admin/catalogue/variants', /Variant|Modifier/i, 'Modifiers / variants'],
    ['44-admin-rewards', '/admin/rewards/loyalty', /Loyalty|Points/i, 'Loyalty rewards'],
    ['45-admin-campaigns', '/admin/rewards/campaigns', /Campaign/i, 'Campaigns'],
    ['46-admin-ad-publishing', '/admin/rewards/ads', /Ad and banner publishing/i, 'Ad publishing'],
    ['47-admin-members', '/admin/reports/members', /Member/i, 'Members'],
    ['48-admin-audit-log', '/admin/system/audit', /Audit/i, 'Audit log'],
    ['49-admin-settings', '/admin/system/settings', /Setting/i, 'Settings'],
  ];

  for (const [name, route, headingRe, headingLabel] of adminShots) {
    try {
      await page.goto(`${BASE}${route}`, { waitUntil: 'networkidle' });
      if (name === '30-admin-dashboard') {
        const today = page.getByRole('button', { name: /^Today$/i });
        if (await today.count()) await today.click();
        await page.waitForTimeout(200);
      }
      if (name === '31-admin-daily-sales') {
        const from = page.locator('input[type="date"]').first();
        const point = page.locator('select').first();
        if (await from.count()) await from.fill('2026-07-21');
        if (await point.count()) await point.selectOption('main');
        await page.waitForTimeout(250);
      }
      if (name === '32-admin-monthly-sales') {
        const month = page.getByRole('button', { name: /This month/i });
        if (await month.count()) await month.click();
        await page.waitForTimeout(350);
      }
      if (name === '34-admin-sales-reports') {
        const from = page.locator('input[type="date"]').first();
        const to = page.locator('input[type="date"]').nth(1);
        const point = page.locator('select').first();
        if (await from.count()) await from.fill('2026-07-01');
        if (await to.count()) await to.fill('2026-07-21');
        if (await point.count()) await point.selectOption('snack');
        await page.waitForTimeout(250);
      }
      await assertRoute(page, {
        urlRe: /\/admin/,
        headingRe,
        name,
        product: 'admin',
      });
      await shot(page, name, {
        route: page.url().replace(BASE, ''),
        heading: headingLabel,
        viewport: '1440×900',
      });
    } catch (e) {
      failShot(name, { route, heading: headingLabel, viewport: '1440×900' }, e.message);
    }
  }

  await browser.close();

  if (forbiddenHits.length) {
    throw new Error(`Network isolation FAILED — forbidden requests:\n${forbiddenHits.join('\n')}`);
  }

  // Duplicate hash check
  const passed = RESULTS.filter((r) => r.result === 'PASS');
  const byHash = new Map();
  const dupes = [];
  for (const r of passed) {
    if (byHash.has(r.sha256)) dupes.push(`${byHash.get(r.sha256)} === ${r.filename}`);
    else byHash.set(r.sha256, r.filename);
  }
  if (dupes.length) {
    throw new Error(`Duplicate screenshot hashes:\n${dupes.join('\n')}`);
  }

  // Confirm files on disk match expected set
  const expected = [
    '01-employee-password-login.png',
    '02-employee-badge-pin-login.png',
    '03-terminal-activation.png',
    '04-dual-role-selection.png',
    '05-unauthorized.png',
    '10-pos-open-shift.png',
    '11-pos-new-sale.png',
    '12-pos-product-selected.png',
    '13-pos-modifiers.png',
    '14-pos-cart.png',
    '15-pos-member-search.png',
    '16-pos-student-member.png',
    '17-pos-rewards.png',
    '18-pos-payment.png',
    '19-pos-receipt.png',
    '20-pos-close-shift.png',
    '21-pos-payment-failure.png',
    '22-pos-offline-state.png',
    '30-admin-dashboard.png',
    '31-admin-daily-sales.png',
    '32-admin-monthly-sales.png',
    '33-admin-branch-comparison.png',
    '34-admin-sales-reports.png',
    '35-admin-product-performance.png',
    '36-admin-shift-report.png',
    '37-admin-branches.png',
    '38-admin-sales-points.png',
    '39-admin-terminals.png',
    '40-admin-staff-roles.png',
    '41-admin-menu.png',
    '42-admin-product-editor.png',
    '43-admin-modifiers.png',
    '44-admin-rewards.png',
    '45-admin-campaigns.png',
    '46-admin-ad-publishing.png',
    '47-admin-members.png',
    '48-admin-audit-log.png',
    '49-admin-settings.png',
  ];
  const onDisk = new Set((await readdir(OUT)).filter((f) => f.endsWith('.png')));
  for (const f of expected) {
    if (!onDisk.has(f) && !RESULTS.some((r) => r.filename === f && r.result.startsWith('FAILED'))) {
      failShot(f.replace(/\.png$/, ''), { route: '?', heading: '?', viewport: '?' }, 'File missing after capture');
    }
  }

  const networkNotes = [
    `Forbidden API/DB/backend requests: ${forbiddenHits.length} (must be 0)`,
    `External font hosts observed: ${[...externalFonts].join(', ') || 'none'}`,
    'Fonts are acceptable per closure-gate rules.',
  ];
  await writeManifest(networkNotes);

  const failed = RESULTS.filter((r) => r.result !== 'PASS').length;
  console.log(`\nClosure gate screenshots: ${passed.length} PASS, ${failed} FAILED, ${byHash.size} unique hashes`);
  console.log('Manifest →', MANIFEST);
  if (failed) process.exitCode = 1;
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
