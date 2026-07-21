import { test, expect, type Page } from '@playwright/test';

const FORBIDDEN = /\/api(?:\/|$|\?)|:3001(?:\/|$)|:3011(?:\/|$)|neon\.tech|render\.com|railway\.app/i;

async function enrolPreview(page: Page) {
  await page.goto('/employee');
  await page.evaluate(() => {
    try {
      sessionStorage.clear();
      localStorage.clear();
    } catch {
      /* ignore */
    }
  });
  await page.goto('/employee', { waitUntil: 'networkidle' });

  const reset = page.getByRole('button', { name: /reset preview terminal/i });
  if (await reset.count()) {
    await reset.click();
    await page.waitForTimeout(200);
  }

  const enrol = page.getByLabel(/enrolment code/i);
  await expect(enrol).toBeVisible({ timeout: 15_000 });
  await enrol.fill('AIDA-482731');
  await page.getByRole('button', { name: /activate terminal/i }).click();
  await expect(page.getByRole('heading', { name: /sign in/i })).toBeVisible({ timeout: 15_000 });
  await expect(page.locator('#emp-username')).toBeVisible({ timeout: 10_000 });
}

async function login(page: Page, username: string, password: string) {
  await page.locator('#emp-username').fill(username);
  await page.locator('#emp-password').fill(password);
  await page.getByRole('button', { name: /^sign in$/i }).click();
}

test.describe('Preview closure gate (no backend)', () => {
  test('preview banner on employee access', async ({ page }) => {
    const hits: string[] = [];
    page.on('request', (req) => {
      if (FORBIDDEN.test(req.url())) hits.push(req.url());
    });
    await enrolPreview(page);
    await expect(page.getByText(/UI PREVIEW — SAMPLE DATA/i).first()).toBeVisible();
    expect(hits, `Forbidden requests: ${hits.join(', ')}`).toEqual([]);
  });

  test('staff routes to POS and is blocked from Admin', async ({ page }) => {
    const hits: string[] = [];
    page.on('request', (req) => {
      if (FORBIDDEN.test(req.url())) hits.push(req.url());
    });
    await enrolPreview(page);
    await login(page, 'preview.staff', 'preview123');
    await expect(page).toHaveURL(/\/pos/, { timeout: 15_000 });
    await expect(page.getByText(/UI PREVIEW — SAMPLE DATA/i).first()).toBeVisible();
    await page.goto('/admin');
    await expect(page).toHaveURL(/\/unauthorized/, { timeout: 10_000 });
    await expect(page.getByRole('heading', { name: /Unauthorized/i })).toBeVisible();
    expect(hits).toEqual([]);
  });

  test('admin routes to Office and is blocked from POS checkout', async ({ page }) => {
    const hits: string[] = [];
    page.on('request', (req) => {
      if (FORBIDDEN.test(req.url())) hits.push(req.url());
    });
    await enrolPreview(page);
    await login(page, 'preview.admin', 'preview123');
    await expect(page).toHaveURL(/\/admin/, { timeout: 15_000 });
    await expect(page.getByRole('heading', { name: /Executive Dashboard|Aida Office/i }).first()).toBeVisible();
    await page.goto('/pos');
    await expect(page).not.toHaveURL(/\/pos$/, { timeout: 10_000 });
    expect(hits).toEqual([]);
  });

  test('dual-role requires explicit workspace selection', async ({ page }) => {
    await enrolPreview(page);
    await login(page, 'preview.dual', 'preview123');
    await expect(page).toHaveURL(/select-role/, { timeout: 15_000 });
    await expect(page.getByRole('heading', { name: /Choose workspace/i })).toBeVisible();
    await expect(page.getByText(/UI PREVIEW — SAMPLE DATA/i).first()).toBeVisible();
  });

  test('sales points and ad publishing pages render', async ({ page }) => {
    await enrolPreview(page);
    await login(page, 'preview.admin', 'preview123');
    await page.goto('/admin/operations/sales-points');
    await expect(page.getByRole('heading', { name: /Sales points/i })).toBeVisible();
    await page.goto('/admin/rewards/ads');
    await expect(page.getByRole('heading', { name: /Ad and banner publishing/i })).toBeVisible();
  });

  test('runtime network isolation across POS open-shift', async ({ page }) => {
    const hits: string[] = [];
    page.on('request', (req) => {
      if (FORBIDDEN.test(req.url())) hits.push(req.url());
    });
    await enrolPreview(page);
    await login(page, 'preview.staff', 'preview123');
    await expect(page).toHaveURL(/\/pos/);
    await page.getByLabel(/opening float/i).fill('50');
    await page.getByRole('button', { name: /open shift/i }).click();
    await expect(page.getByText(/new sale|menu/i).first()).toBeVisible({ timeout: 15_000 });
    expect(hits, `Forbidden: ${hits.join(', ')}`).toEqual([]);
  });
});
