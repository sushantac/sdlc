# 03 — User Stories

| Field | Value |
|-------|-------|
| Document version | 1.0 |
| Status | Approved (sprint-planned) |
| Predecessor | [02-business-requirements.md](02-business-requirements.md) |
| Authoritative plan | [SDLC-PLAN-v2.0](../planning/SDLC-PLAN-v2.0.md) |
| Related risk register | [04-risk-register.md](04-risk-register.md) |

Story format: **"As a \<user\>, I want \<feature\>, so that \<value\>."** Every story maps to one or more of the 14 screens in plan §7.2 and to FR IDs from the business requirements. Estimates use modified Fibonacci points (1, 2, 3, 5, 8) and assume the foundations (gateway, compose, CI, seed data) from Sprints 0–1.

**Screen reference (plan §7.2):** S01 Home · S02 Product Listing · S03 Product Detail · S04 Shopping Cart · S05 Checkout–Address · S06 Checkout–Payment · S07 Checkout–Review · S08 Checkout–Confirmation · S09 Login · S10 Register · S11 Order History · S12 Order Detail · S13 Admin Dashboard · S14 Admin Products/Orders.

## Backlog Summary

| ID | Area | Screens | Points | FR refs |
|----|------|---------|--------|---------|
| US-01 … US-05 | Auth | S09, S10 | 16 | FR-AUTH-01…07, FR-UI-09/10/16 |
| US-06 … US-09 | Product browsing | S01, S02, S03 | 21 | FR-PRODUCT-01/02/06, FR-UI-01/02/03 |
| US-10 … US-14 | Cart | S03, S04 | 18 | FR-CART-01…07, FR-UI-04 |
| US-15 … US-19 | Checkout / orders | S05, S06, S07, S08, S12 | 23 | FR-ORDER-01…10, FR-UI-05…08/12 |
| US-20 … US-21 | Order history | S11, S12 | 8 | FR-ORDER-03/04, FR-UI-11/12 |
| US-22 … US-27 | Admin | S09, S13, S14 | 37 | FR-ADMIN-01…09, FR-UI-13/14, FR-PRODUCT-03/04/05/07 |
| **Total** | | **14 screens** | **123** | — |

## 1. Auth (Screens S09, S10)

| ID | Story | Screen | Pts | FR |
|----|-------|--------|-----|-----|
| US-01 | As a first-time customer, I want to register with full name, email, password, and phone, so that I can log in and place orders. | S10 | 3 | FR-AUTH-01, FR-UI-10 |
| US-02 | As a registered customer, I want to log in with email and password, so that I can access my cart and checkout. | S09 | 3 | FR-AUTH-02, FR-UI-09 |
| US-03 | As a logged-in customer, I want my access token to refresh automatically before expiry, so that I stay signed in without re-entering credentials. | S09 | 5 | FR-AUTH-03, FR-UI-16 |
| US-04 | As a customer, I want to log out, so that my session is ended on shared devices. | S09 | 2 | FR-AUTH-06 |
| US-05 | As a customer, I want to view and update my name and phone number, so that my profile and any shipping contact details stay current. | S09 | 3 | FR-AUTH-04, FR-AUTH-05 |

**Acceptance criteria**

- **US-01** — Given I am on the Register screen, when I submit valid `fullName`, `email`, `password` (matching confirm) and `phoneNumber`, then my account is created, I am returned to Login, and no password is stored in plaintext. Given I reuse a registered email, when I submit, then I see a duplicate-email error (register rate limit 5/min applies — plan §6.3).
- **US-02** — Given valid credentials, when I log in, then I receive `{accessToken, refreshToken, user}` and am redirected to my destination page. Given invalid credentials, when I submit, then I see an inline error. Given >10 login attempts/min, when I continue, then the gateway returns 429.
- **US-03** — Given an expired access token and a valid refresh token, when the frontend issues a request, then `lib/api.ts` calls `/api/v1/auth/refresh`, gets a new access token, and retries the original request transparently.
- **US-04** — Given a signed-in session, when I log out, then `POST /api/v1/auth/logout` returns 204, the refresh token is revoked from `auth.refresh_tokens`, and local tokens are cleared.
- **US-05** — Given I am signed in, when I update `fullName`/`phoneNumber`, then `PUT /api/v1/auth/profile` persists changes and I see the confirmation; `auth.user.updated` is published to Kafka.

## 2. Product Browsing (Screens S01, S02, S03)

| ID | Story | Screen | Pts | FR |
|----|-------|--------|-----|-----|
| US-06 | As a shopper, I want a homepage with a hero, featured products, and categories, so that I can start shopping immediately. | S01 | 5 | FR-UI-01, FR-PRODUCT-06 |
| US-07 | As a shopper, I want to search, filter by category and price range, sort, and paginate products, so that I can find the right product quickly. | S02 | 8 | FR-PRODUCT-01, FR-UI-02 |
| US-08 | As a shopper, I want a product detail page with image carousel, description, price, and stock status, so that I can decide whether to buy. | S03 | 5 | FR-PRODUCT-02, FR-UI-03 |
| US-09 | As a shopper, I want to browse products by category from the homepage and listing filters, so that I can explore the catalog thematically. | S01, S02 | 3 | FR-PRODUCT-01, FR-PRODUCT-06 |

**Acceptance criteria**

- **US-06** — Given a shopper with no cart or session, when the homepage loads, then it shows hero, featured products, and categories rendered from `GET /api/v1/products`/`/categories`; LCP < 2.5 s and Lighthouse ≥ 90 live (NFR-PERF-02/03).
- **US-07** — Given the listing screen, when I apply `search`/`category`/`minPrice`/`maxPrice`/`sort`/`page`/`size`, then results re-fetch server-side with correct `totalElements`/`totalPages` and reflect in the URL; empty states show a clear message; p95 < 200 ms (NFR-PERF-01).
- **US-08** — Given a product url like `/products/{id}`, when it loads, then title, description, price, stock quantity, and categories match `GET /api/v1/products/{id}`; out-of-stock items disable the add-to-cart control and show a message.
- **US-09** — Given a category filter selected from homepage or sidebar, when browsing, then only products in that category are listed and the count updates; changing category resets pagination.

## 3. Cart (Screens S03, S04)

| ID | Story | Screen | Pts | FR |
|----|-------|--------|-----|-----|
| US-10 | As a customer, I want to view my cart with items, quantities, subtotal, tax, and total, so that I can review before checkout. | S04 | 3 | FR-CART-01, FR-UI-04 |
| US-11 | As a customer, I want to add a product with a quantity, so that items are collected for purchase with valid current pricing and stock. | S03, S04 | 5 | FR-CART-02 |
| US-12 | As a customer, I want to update quantities and remove items, so that my cart matches my intent. | S04 | 3 | FR-CART-03, FR-CART-04 |
| US-13 | As a customer, I want to clear my whole cart, so that I can start fresh. | S04 | 2 | FR-CART-05 |
| US-14 | As a customer, I want cart unit prices and stock to track catalog changes, so that I am not surprised by stale totals at checkout. | S04 | 5 | FR-CART-07 |

**Acceptance criteria**

- **US-10** — Given a cart with items, when I open the cart, then I see each item (name, unit price, quantity), `subtotal`, `tax`, and `total` from `GET /api/v1/cart`; empty carts show an empty state with a CTA to the catalog.
- **US-11** — Given a product with stock ≥ quantity, when I click "Add to cart", then `POST /api/v1/cart/items` returns the updated cart and a toast confirms the add. Given requested quantity exceeds stock (validated against Product Service), when I submit, then the add is rejected with a stock error (plan §3.2 dependency).
- **US-12** — Given a cart item, when I change its quantity, then `PUT /api/v1/cart/items/{itemId}` updates totals; when I delete it, then `DELETE /api/v1/cart/items/{itemId}` removes it and totals recompute.
- **US-13** — Given a non-empty cart, when I confirm "Clear cart", then `DELETE /api/v1/cart` returns 204 and the UI shows the empty state.
- **US-14** — Given a `product.catalog.updated`/`deleted` event, when the cart receives it, then unit prices refresh and deleted/out-of-stock items are flagged or removed; a stale-price warning appears during checkout review.

## 4. Checkout & Orders (Screens S05, S06, S07, S08, S12)

| ID | Story | Screen | Pts | FR |
|----|-------|--------|-----|-----|
| US-15 | As a customer, I want to enter a shipping address with validation, so that the order can be routed for delivery. | S05 | 3 | FR-UI-05, FR-ORDER-08 |
| US-16 | As a customer, I want a simulated payment step showing an order summary, so that I can complete the purchase without a real PSP. | S06 | 5 | FR-ORDER-10, FR-UI-06 |
| US-17 | As a customer, I want a final review step, so that I can confirm items, address, and payment before placing the order. | S07 | 2 | FR-UI-07 |
| US-18 | As a customer, I want to place the order and see a confirmation with my order number, so that I have proof of purchase. | S08 | 8 | FR-ORDER-01/07/09, FR-UI-08 |
| US-19 | As a customer, I want to see order status on the order detail page, so that I can follow fulfillment progress. | S12 | 5 | FR-ORDER-05, FR-UI-12 |

**Acceptance criteria**

- **US-15** — Given the checkout address step, when I submit an invalid form (missing fields, bad format), then validation errors appear linked to inputs via `aria-describedby` (NFR-ACC-04). Given valid address data, when I proceed, then step 2 unlocks and the address is carried to review.
- **US-16** — Given a valid address, when I simulate payment (card fields accept test values), then `payment` is recorded with its status against the order and a summary of items/totals is shown.
- **US-17** — Given cart, address, and payment data, when review renders, then items, shipping address, and payment method are all shown and editable via back-steps before placing.
- **US-18** — Given review confirmed, when I click "Place order", then `cart.checkout.initiated` (with `eventId`, items, shippingAddress) is published, Order API consumes it **idempotently** (US-09/eventId dedup per plan §5.3), `order.placed` is published, and the confirmation shows the order number. Given the same event re-delivered, when it is processed again, then no duplicate order is created (idempotency key machinery at FR-ORDER-09).
- **US-19** — Given an order, when status changes (e.g., via admin `PUT /api/v1/admin/orders/{id}/status`), then `order.status.changed` updates the timeline on the order detail page with timestamps.

## 5. Order History (Screens S11, S12)

| ID | Story | Screen | Pts | FR |
|----|-------|--------|-----|-----|
| US-20 | As a customer, I want a table of my past orders with status badges, so that I can track all purchases. | S11 | 5 | FR-ORDER-03, FR-UI-11 |
| US-21 | As a customer, I want to open an order and see items, totals, and status timeline, so that I can review a specific order in detail. | S12 | 3 | FR-ORDER-04, FR-UI-12 |

**Acceptance criteria**

- **US-20** — Given a signed-in customer, when Order History loads, then I see my orders from `GET /api/v1/orders` with status badges (req. FR-ORDER-03) ordered newest-first; the table is keyboard-navigable and readable at all 4 breakpoints (NFR-ACC-03, NFR-PERF-related responsive rule §7.4).
- **US-21** — Given an order id, when I click into it, then the detail page shows the full item list, totals, and a status timeline consistent with `order.status.changed` events; missing/cancelled orders show an informative state rather than an error.

## 6. Admin (Screens S09, S13, S14)

| ID | Story | Screen | Pts | FR |
|----|-------|--------|-----|-----|
| US-22 | As an administrator, I want my login to be recognized as `ADMIN`, so that only authorized staff can manage the store. | S09 | 3 | FR-ADMIN-07 |
| US-23 | As an administrator, I want a dashboard with orders, revenue, users, products, and recent orders, so that I can monitor store health at a glance. | S13 | 8 | FR-ADMIN-01, FR-UI-13 |
| US-24 | As an administrator, I want to view, filter, and update the status of orders, so that orders are processed and customers see accurate statuses. | S14 | 8 | FR-ADMIN-02/03/04 |
| US-25 | As an administrator, I want to search users and see each user's order count, so that I can resolve customer issues quickly. | S14 | 5 | FR-ADMIN-05/06 |
| US-26 | As an administrator, I want to create, update, and delete products and categories, so that the catalog stays current. | S14 | 8 | FR-PRODUCT-03/04/05/07, FR-UI-14 |
| US-27 | As a platform owner, I want admin actions recorded in an audit trail, so that store operations are accountable. | S13, S14 | 5 | FR-ADMIN-08 |

**Acceptance criteria**

- **US-22** — Given an admin account, when I log in, then my tokens carry the `ADMIN` role claim and the gateway allows `/api/v1/admin/**`; given a non-admin JWT, when I call an admin route, then the gateway returns 403 (plan §3.6). Public product GET routes remain open (NFR-SEC-04).
- **US-23** — Given admin access, when the dashboard loads, then `GET /api/v1/admin/dashboard` renders `totalOrders`, `totalRevenue`, `totalUsers`, `totalProducts`, and `recentOrders[]` as stat cards and charts; numbers reflect consumed Kafka events (plan §3.5).
- **US-24** — Given the admin orders table, when I filter by `status` and paginate, then results match `GET /api/v1/admin/orders`; when I set a new status via `PUT /api/v1/admin/orders/{id}/status`, then the UI updates and `order.status.changed` is published, so the customer's timeline updates.
- **US-25** — Given the admin users view, when I search by name/email, then `GET /api/v1/admin/users` returns paginated matches; when I open a user, then user details plus `orderCount` (FR-ADMIN-06) are shown.
- **US-26** — Given catalog admin view, when I create/update/delete a product or create a category, then the corresponding product/category endpoints run, `product.catalog.*` events are published, and the storefront reflects changes; destructive actions require a confirmation dialog (shadcn `Dialog`).
- **US-27** — Given any admin mutation (status, user view with PII, catalog writes), when it succeeds, then an `admin.audit_entries` row is written with `entity_type`, `entity_id`, `action`, `performed_by`, `performed_at`, `details`; the audit trail is retained in the `admin` schema (plan §4.1).

## 7. Delivery Plan & Estimation

Points are final estimates for the backlog above; foundations (gateway, compose, CI scaffolding, seed scripts) are accounted by Sprints 0–1 tooling phases (plan §20, phases 0–2, 8–10).

| Sprint (plan §17.2) | Focus | Stories in sprint |
|---------------------|-------|-------------------|
| 1 (Week 2) | Backend Core | US-01, US-02, US-04, US-11, US-12, US-13, US-22 (backend of auth/cart/product/gateway) |
| 2 (Week 3) | Backend Extended | US-14, US-18, US-19, US-24, US-27, US-26 (order events, admin, idempotency) |
| 3 (Week 4) | Frontend + QA | US-03, US-05, US-06, US-07, US-08, US-09, US-10, US-15, US-16, US-17, US-20, US-21, US-23, US-25 |

Stories are done only when: code merged via a reviewed PR (plan §13.1), unit coverage ≥ 80% on the touched service (plan §10.2), affected E2E flow green (plan §10.4), and no new high/critical vulnerabilities (plan §22.5). Retrospectives track velocity for adjustments (plan §17).