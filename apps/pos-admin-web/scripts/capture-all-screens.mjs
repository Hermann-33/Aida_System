/**
 * Capture POS + Admin preview screens with route/heading assertions and duplicate-hash fail.
 * Requires: npm run dev on :5173, Playwright Chromium.
 * Usage: node scripts/capture-all-screens.mjs
 */
import { chromium } from '@playwright/test';
import { createHash } from 'node:crypto';
import { mkdir, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const BASE = process.env.CAPTURE_URL || 'http://localhost:5173';
const OUT = path.join(ROOT, 'docs_screenshots', 'all-screens');
const ZIP = path.join(ROOT, 'docs_screenshots', 'aida-pos-admin-all-screens.zip');

/** Intentional near-duplicates allowed only when listed together (visually different states). */
const ALLOWED_RELATED = new Set([]);

const ADMIN_SHOTS = [
  ['30-admin-01-dashboard-today', '/admin', /Dashboard|Overview|Today/i, 'admin'],
  ['30-admin-02-dashboard-month', '/admin?period=month', /Dashboard|Overview|Month/i, 'admin'],
  ['30-admin-03-live-ops', '/admin/live', /Live/i, 'admin'],
  ['30-admin-04-branch-compare', '/admin/reports/branches', /Branch/i, 'admin'],
  ['30-admin-05-sales', '/admin/reports/sales', /Sales/i, 'admin'],
  ['30-admin-06-transactions', '/admin/reports/transactions', /Transaction/i, 'admin'],
  ['30-admin-07-products', '/admin/reports/products', /Product/i, 'admin'],
  ['30-admin-08-payments', '/admin/reports/payments', /Payment/i, 'admin'],
  ['30-admin-09-shift-cash', '/admin/reports/shifts', /Shift|Cash|Variance/i, 'admin'],
  ['30-admin-10-rewards-report', '/admin/reports/rewards', /Reward|Offer/i, 'admin'],
  ['30-admin-11-voids', '/admin/reports/voids', /Void|Refund/i, 'admin'],
  ['30-admin-12-branches', '/admin/operations/branches', /Branch|Organisation|Sales point/i, 'admin'],
  ['30-admin-13-terminals', '/admin/operations/terminals', /Terminal/i, 'admin'],
  ['30-admin-14-shifts', '/admin/operations/shifts', /Shift/i, 'admin'],
  ['30-admin-15-employees', '/admin/operations/employees', /Employee/i, 'admin'],
  ['30-admin-16-menu', '/admin/catalogue/menu', /Menu/i, 'admin'],
  ['30-admin-17-categories', '/admin/catalogue/categories', /Categor/i, 'admin'],
  ['30-admin-18-variants', '/admin/catalogue/variants', /Variant|Modifier/i, 'admin'],
  ['30-admin-19-inventory', '/admin/inventory/stock', /Stock|Inventory/i, 'admin'],
  ['30-admin-20-recipes', '/admin/inventory/recipes', /Recipe/i, 'admin'],
  ['30-admin-21-wastage', '/admin/inventory/wastage', /Wastage|Spoil/i, 'admin'],
  ['30-admin-22-loyalty', '/admin/rewards/loyalty', /Loyalty|Points/i, 'admin'],
  ['30-admin-23-offers', '/admin/rewards/offers', /Offer|Student/i, 'admin'],
  ['30-admin-24-campaigns', '/admin/rewards/campaigns', /Campaign/i, 'admin'],
  ['30-admin-25-audit', '/admin/system/audit', /Audit/i, 'admin'],
  ['30-admin-26-integrations', '/admin/system/integrations', /Integration/i, 'admin'],
  ['30-admin-27-settings', '/admin/system/settings', /Setting/i, 'admin'],
];

async function assertRoute(page, { urlRe, headingRe, product, name }) {
  const url = page.url();
  if (urlRe && !urlRe.test(url)) {
    throw new Error(`[${name}] Expected URL ${urlRe}, got ${url}`);
  }
  if (product === 'admin') {
    await page.locator('[data-product="admin"], .layout-admin, h1:has-text("Aida Office")').first().waitFor({ timeout: 15000 }).catch(() => {});
    const productAttr = await page.locator('[data-product="admin"]').count();
    const officeHeading = await page.getByRole('heading', { name: /Aida Office|Executive Dashboard|Live/i }).count();
    if (!productAttr && !officeHeading) {
      throw new Error(`[${name}] Missing Admin shell — landed on wrong page (${url})`);
    }
    if (/\/employee(?:\/|$|\?)/.test(url)) {
      throw new Error(`[${name}] Unexpected Employee Access while capturing Admin`);
    }
  }
  if (product === 'pos' && !/\/pos/.test(url) && !/\/employee/.test(url)) {
    // pos shots may be on /pos
  }
  if (headingRe) {
    const heading = page.getByRole('heading', { name: headingRe }).first();
    await heading.waitFor({ timeout: 12000 }).catch(() => {
      throw new Error(`[${name}] Missing heading ${headingRe} at ${url}`);
    });
  }
  const banner = page.getByText(/UI PREVIEW — SAMPLE DATA/i);
  if (await banner.count()) {
    /* ok */
  } else if (product === 'admin' || product === 'pos') {
    console.warn(`[${name}] Preview banner not visible`);
  }
}

async function shot(page, name) {
  const file = path.join(OUT, `${name}.png`);
  await page.waitForTimeout(280);
  await page.screenshot({ path: file, fullPage: false });
  console.log('  ✓', name);
  return file;
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

async function verifyHashes() {
  const files = (await readdir(OUT)).filter((f) => f.endsWith('.png')).sort();
  const hashes = new Map();
  const dupes = [];
  for (const f of files) {
    const buf = await readFile(path.join(OUT, f));
    const h = createHash('sha256').update(buf).digest('hex');
    if (hashes.has(h)) {
      const other = hashes.get(h);
      const key = [other, f].sort().join('|');
      if (!ALLOWED_RELATED.has(key)) {
        dupes.push(`${other} === ${f}`);
      }
    } else {
      hashes.set(h, f);
    }
  }
  if (dupes.length) {
    throw new Error(`Duplicate screenshot hashes:\n${dupes.join('\n')}`);
  }
  console.log(`Hash check OK — ${files.length} unique PNGs`);
  return files.length;
}

async function main() {
  await rm(OUT, { recursive: true, force: true });
  await mkdir(OUT, { recursive: true });

  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: 1366, height: 768 },
    deviceScaleFactor: 1,
  });
  const page = await context.newPage();

  console.log('Employee / auth…');
  await clearStorage(page);
  await page.goto(`${BASE}/employee`, { waitUntil: 'networkidle' });
  await assertRoute(page, { urlRe: /\/employee/, headingRe: /Activate this terminal/i, name: 'enrol' });
  await shot(page, '00-employee-terminal-enrol');

  await page.getByLabel(/enrolment code/i).fill('AIDA-EXPIRED');
  await page.getByRole('button', { name: /activate terminal/i }).click();
  await page.waitForTimeout(400);
  await shot(page, '00-employee-terminal-enrol-expired');

  await page.getByRole('button', { name: /reset preview terminal/i }).click();
  await page.getByLabel(/enrolment code/i).fill('AIDA-482731');
  await page.getByRole('button', { name: /activate terminal/i }).click();
  await page.getByRole('heading', { name: /sign in/i }).waitFor({ timeout: 15000 });
  await shot(page, '00-employee-sign-in-password');

  await page.getByRole('tab', { name: /badge \+ pin/i }).click();
  await shot(page, '00-employee-sign-in-badge');

  await page.getByRole('tab', { name: /^password$/i }).click();
  await login(page, 'preview.dual', 'preview123');
  await page.waitForURL(/select-role|\/pos|\/admin/, { timeout: 15000 });
  if (page.url().includes('select-role')) {
    await assertRoute(page, { headingRe: /Choose workspace/i, name: 'role-select' });
    await shot(page, '00-employee-role-select');
  }
  await logoutIfPresent(page);

  console.log('POS…');
  await clearStorage(page);
  await enrol(page);
  await login(page, 'preview.staff', 'preview123');
  await page.waitForURL(/\/pos/, { timeout: 15000 });
  await assertRoute(page, { urlRe: /\/pos/, headingRe: /Open shift|Aida Counter/i, product: 'pos', name: 'open-shift' });
  await shot(page, '10-pos-open-shift');

  await page.getByLabel(/opening float/i).fill('100');
  await page.getByRole('button', { name: /open shift/i }).click();
  await page.getByText(/new sale|menu/i).first().waitFor({ timeout: 15000 });
  await assertRoute(page, { urlRe: /\/pos/, product: 'pos', name: 'new-sale' });
  await shot(page, '11-pos-counter-new-sale');

  await page.getByRole('tab', { name: /^Coffee$/i }).click().catch(async () => {
    await page.getByRole('button', { name: /^Coffee$/i }).click();
  });
  await page.waitForTimeout(350);
  await shot(page, '12-pos-menu-coffee');

  await page.getByRole('button', { name: /Salted Caramel Latte|Latte/i }).first().click();
  await page.getByRole('dialog').waitFor({ timeout: 8000 });
  await page.getByRole('button', { name: /add to order/i }).waitFor({ state: 'visible' });
  await shot(page, '13-pos-modifier-sheet');

  const medium = page.getByLabel(/^Medium$/i);
  if (await medium.count()) await medium.check().catch(async () => medium.click());
  await page.getByRole('button', { name: /add to order/i }).click();
  await page.waitForTimeout(350);
  await shot(page, '14-pos-cart-with-item');

  // Ensure coffee category shot is visually different: already captured after All/new-sale
  await page.getByRole('button', { name: /^Member$/i }).click();
  await page.waitForTimeout(300);
  await shot(page, '15-pos-member-panel');
  const scan = page.getByRole('button', { name: /scan member/i });
  if (await scan.count()) {
    await scan.click();
    await page.waitForTimeout(200);
  } else {
    await page.getByPlaceholder(/search|member|id/i).fill('Aisyah');
    await page.waitForTimeout(300);
    const opt = page.getByRole('option').first();
    if (await opt.count()) await opt.click();
  }
  const apply = page.getByRole('button', { name: /apply/i }).first();
  if (await apply.count() && await apply.isEnabled()) await apply.click();
  await shot(page, '16-pos-member-reward-applied');

  await page.getByRole('button', { name: /^New Sale$/i }).click();
  // Add item if cart empty after member rail
  if (await page.getByRole('button', { name: /^Pay$/i }).isDisabled().catch(() => true)) {
    await page.getByRole('button', { name: /Salted Caramel Latte|Americano|Latte/i }).first().click();
    if (await page.getByRole('dialog').count()) {
      await page.getByRole('button', { name: /add to order/i }).click();
    }
  }
  await page.getByRole('button', { name: /^Pay$/i }).click();
  await page.getByRole('heading', { name: /payment/i }).waitFor({ timeout: 8000 });
  await shot(page, '17-pos-payment-cash');

  const cashInput = page.getByLabel(/cash received|tender/i);
  if (await cashInput.count()) {
    await cashInput.fill('50');
    await page.waitForTimeout(200);
    await shot(page, '18-pos-payment-cash-change');
    await page.getByRole('button', { name: /confirm payment|complete sale/i }).click();
  } else {
    await page.getByRole('button', { name: /complete sale|confirm payment/i }).click();
  }

  await page.getByRole('heading', { name: /sale complete|receipt/i }).waitFor({ timeout: 10000 });
  await shot(page, '19-pos-receipt-complete');

  // New sale then non-cash path
  await page.locator('button.order-ribbon__pay', { hasText: /new sale/i }).click().catch(async () => {
    await page.getByRole('button', { name: /^New Sale$/i }).click();
  });
  await page.waitForTimeout(300);
  await page.getByRole('button', { name: /Salted Caramel Latte|Americano|Latte/i }).first().click().catch(() => {});
  if (await page.getByRole('dialog').count()) {
    await page.getByRole('button', { name: /add to order/i }).click();
  }
  if (await page.getByRole('button', { name: /^Pay$/i }).isEnabled().catch(() => false)) {
    await page.getByRole('button', { name: /^Pay$/i }).click();
    const card = page.getByLabel(/^Card$/i);
    if (await card.count()) await card.check().catch(async () => card.click());
    const decline = page.getByRole('button', { name: /simulate decline/i });
    if (await decline.count()) {
      await decline.click();
      await shot(page, '20-pos-payment-declined');
    } else {
      await shot(page, '20-pos-payment-card');
    }
    await page.getByRole('button', { name: /^Back$/i }).click().catch(() => {});
  }

  await page.getByRole('button', { name: /^Orders$/i }).click();
  await page.waitForTimeout(300);
  await shot(page, '21-pos-orders');

  await page.getByRole('button', { name: /^Shift$/i }).click();
  await page.waitForTimeout(300);
  await shot(page, '22-pos-shift-controls');

  await page.getByRole('button', { name: /^Terminal$/i }).click();
  await page.waitForTimeout(300);
  await shot(page, '23-pos-terminal-health');

  const offlineSelect = page.locator('select').filter({ hasText: /Offline/i });
  if (await offlineSelect.count()) {
    await offlineSelect.selectOption('offline');
    await shot(page, '24-pos-offline');
  } else {
    await shot(page, '24-pos-offline');
  }

  await page.getByRole('button', { name: /^Shift$/i }).click();
  await page.getByRole('button', { name: /close shift/i }).click();
  await page.getByRole('heading', { name: /close shift/i }).waitFor({ timeout: 10000 });
  await shot(page, '25-pos-close-shift');

  console.log('Admin…');
  await logoutIfPresent(page);
  await clearStorage(page);
  await enrol(page);
  await login(page, 'preview.admin', 'preview123');
  await page.waitForURL(/\/admin/, { timeout: 15000 });
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.getByText(/Aida Office|Executive Dashboard/i).first().waitFor({ timeout: 15000 });
  await assertRoute(page, {
    urlRe: /\/admin/,
    headingRe: /Executive Dashboard/i,
    product: 'admin',
    name: 'admin-first',
  });

  for (const [name, route, headingRe] of ADMIN_SHOTS) {
    await page.goto(`${BASE}${route}`, { waitUntil: 'networkidle' });
    // Preview session must survive reload via sessionStorage
    await assertRoute(page, {
      urlRe: new RegExp(route.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/\\\/\\\?.*/, '.*')),
      headingRe,
      product: 'admin',
      name,
    });
    await shot(page, name);
  }

  await browser.close();

  await writeFile(
    path.join(OUT, 'README.txt'),
    [
      'Aida Counter + Aida Office — corrected UI preview screenshots',
      `Captured: ${new Date().toISOString()}`,
      `Base: ${BASE}`,
      'Preview only. Enrol AIDA-482731. Demo accounts — see docs/AIDA_UI_VALIDATION.md',
      '',
    ].join('\n'),
  );

  const count = await verifyHashes();

  try {
    await rm(ZIP, { force: true });
  } catch {
    /* ignore */
  }
  execFileSync(
    'powershell.exe',
    ['-NoProfile', '-Command', `Compress-Archive -Path '${OUT}\\*' -DestinationPath '${ZIP}' -Force`],
    { stdio: 'inherit' },
  );

  console.log('\nDone.', count, 'PNGs →', ZIP);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
