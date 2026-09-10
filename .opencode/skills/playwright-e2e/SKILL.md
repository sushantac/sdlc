---
name: playwright-e2e
description: Write Playwright E2E tests for the e-commerce frontend covering critical user flows. Use when adding or extending browser-level tests.
---

# Playwright E2E

Write browser E2E tests for the e-commerce frontend. Runner: `@playwright/test` in `e-commerce-frontend`, config `playwright.config.ts`, specs under `e2e/`.

## Coverage targets (critical flows)

1. Auth: register → login → profile
2. Browse: home → listing → filters/search → detail
3. Cart: add to cart → update qty → remove
4. Checkout: cart → address → payment → review → confirmation (assert order number)
5. Order history + order detail (status badge)
6. Admin: dashboard → orders → update status

## Structure

```
e2e/
├── auth.spec.ts
├── browse.spec.ts
├── cart.spec.ts
├── checkout.spec.ts
└── admin.spec.ts
```

## Conventions
- Base URL `http://localhost:3000`; API via the real backend (full-stack E2E) or `page.route` stubs for isolated UI tests
- Use data attributes `data-testid` (not CSS class names) for stable selectors
- `test.describe` per flow; one assertion intent per `test`
- Accessibility: run axe-core assertions on every page visited (`injectAxe`, `checkAxe`)
- Avoid `waitForTimeout`; use `expect(locator).toBeVisible()`, `toHaveText()`, `expect.poll`/`expect.waitFor` for async

## example

```ts
import { test, expect } from '@playwright/test';

test('checkout flow completes with order confirmation', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('link', { name: /add to cart/i }).first().click();
  await page.getByRole('link', { name: /cart/i }).click();
  await page.getByRole('button', { name: /checkout/i }).click();
  await page.getByLabel('Street').fill('1 Test St');
  // ...
  await expect(page.getByTestId('order-number')).toBeVisible();
});
```

## Config essentials

```ts
import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './e2e',
  timeout: 60_000,
  use: { baseURL: 'http://localhost:3000', trace: 'on-first-retry' },
  projects: [
    { name: 'chromium', use: { browserName: 'chromium' } },
  ],
});
```

## Quality gates
- `npx playwright test` green locally on all critical flows
- OK to skip: full visual regression (beyond scope) — keep to functional + axe