# 02 — Business Requirements Document

| Field | Value |
|-------|-------|
| Document version | 1.0 |
| Status | Approved |
| Predecessor | [01-project-charter.md](01-project-charter.md) |
| Authoritative plan | [SDLC-PLAN-v2.0](../planning/SDLC-PLAN-v2.0.md) |
| Related user stories | [03-user-stories.md](03-user-stories.md) |

All requirements below trace to the service contracts, database design, and UX design in the authoritative plan. IDs are stable and referenced consistently across the requirements, stories, and risk documents.

## 1. Target Users (Personas)

### Persona 1 — Primary Shopper ("Customer")

| Attribute | Detail |
|-----------|--------|
| Profile | Individual browsing on desktop, tablet, or mobile; may or may not be registered |
| Device mix | Mobile 375 px, tablet 768 px, desktop 1280 px (plan §7.4) |
| Technical level | Non-technical; expects self-service |

**Goals**

| ID | Goal |
|----|------|
| P1-G1 | Browse, search, filter, and compare products and categories quickly |
| P1-G2 | Build and maintain a cart with clear prices (subtotal, tax, total) |
| P1-G3 | Complete checkout in a guided, reviewable flow and receive an order number |
| P1-G4 | Retrieve order history and follow order status without contacting support |
| P1-G5 | Log in/register and stay signed in across sessions (auto token refresh) |

**Success criteria:** the shopper can go from homepage to order confirmation in under 5 minutes without documentation, on any supported breakpoint, with no assistance for registered checkout.

### Persona 2 — Store Administrator ("Admin")

| Attribute | Detail |
|-----------|--------|
| Profile | Store operations staff with elevated `ADMIN` role |
| Access | `/api/v1/admin/**` traffic only — JWT + ADMIN enforced at gateway (plan §3.6) |
| Tools | Admin dashboard + CRUD tables via `e-commerce-frontend` pages 13–14 |

**Goals**

| ID | Goal |
|----|------|
| P2-G1 | See store health at a glance: orders, revenue, users, products, recent orders |
| P2-G2 | View, filter, and update order statuses as fulfillment progresses |
| P2-G3 | Search and inspect users (including per-user order counts) for support |
| P2-G4 | Manage the catalog: create/update/delete products and categories |
| P2-G5 | Keep an audit trail of administrative actions |

**Success criteria:** the admin can manage orders, users, and catalog, and every sensitive action is recorded in `admin.audit_entries` and reflected in dashboard numbers within the freshness window.

## 2. Functional Requirements

Priorities use MoSCoW (Must, Should, Could). Sources reference the plan sections with the concrete contract.

### 2.1 Authentication & Users (plan §3.1)

| ID | Requirement | Source | Priority |
|----|-------------|--------|----------|
| FR-AUTH-01 | Allow registration with `email`, `password`, `fullName`, `phoneNumber` via `POST /api/v1/auth/register`; reject duplicate emails | plan §3.1 | Must |
| FR-AUTH-02 | Allow login via `POST /api/v1/auth/login` returning `{accessToken, refreshToken, user}` | plan §3.1 | Must |
| FR-AUTH-03 | Support access-token refresh via `POST /api/v1/auth/refresh` given a valid refresh token | plan §3.1 | Must |
| FR-AUTH-04 | Expose current user profile via `GET /api/v1/auth/profile` (JWT) | plan §3.1 | Must |
| FR-AUTH-05 | Allow updating `fullName` / `phoneNumber` via `PUT /api/v1/auth/profile` | plan §3.1 | Should |
| FR-AUTH-06 | Invalidate the session via `POST /api/v1/auth/logout` (204), revoking the refresh token | plan §3.1 | Must |
| FR-AUTH-07 | Publish `auth.user.registered` and `auth.user.updated` to Kafka for the Admin Service | plan §5.1 | Must |

### 2.2 Shopping Cart (plan §3.2)

| ID | Requirement | Source | Priority |
|----|-------------|--------|----------|
| FR-CART-01 | Retrieve the current user's cart with `items[]`, `subtotal`, `tax`, `total` via `GET /api/v1/cart` (JWT) | plan §3.2 | Must |
| FR-CART-02 | Add an item (`productId`, `quantity`) via `POST /api/v1/cart/items`; validate price and stock by calling Product Service | plan §3.2 | Must |
| FR-CART-03 | Update item quantity via `PUT /api/v1/cart/items/{itemId}` | plan §3.2 | Must |
| FR-CART-04 | Remove an item via `DELETE /api/v1/cart/items/{itemId}` | plan §3.2 | Must |
| FR-CART-05 | Clear the whole cart via `DELETE /api/v1/cart` (204) | plan §3.2 | Must |
| FR-CART-06 | Publish `cart.checkout.initiated` (with `eventId`, items, shipping address) when checkout begins | plan §3.2, §5.1 | Must |
| FR-CART-07 | React to `product.catalog.{created,updated,deleted}` events so cart unit prices and stock stay consistent | plan §3.2, §5.1 | Should |

### 2.3 Product Catalog (plan §3.3)

| ID | Requirement | Source | Priority |
|----|-------------|--------|----------|
| FR-PRODUCT-01 | List products with `search`, `category`, `minPrice`, `maxPrice`, `sort`, `page`, `size` query params returning paginated `{content[], totalElements, totalPages}` via `GET /api/v1/products` | plan §3.3 | Must |
| FR-PRODUCT-02 | Return product detail (`name`, `description`, `price`, `stockQuantity`, `categories[]`) via `GET /api/v1/products/{id}` | plan §3.3 | Must |
| FR-PRODUCT-03 | Create a product via `POST /api/v1/products` (JWT) | plan §3.3 | Must |
| FR-PRODUCT-04 | Update a product via `PUT /api/v1/products/{id}` (JWT) | plan §3.3 | Must |
| FR-PRODUCT-05 | Delete a product via `DELETE /api/v1/products/{id}` (204, JWT) | plan §3.3 | Must |
| FR-PRODUCT-06 | List categories via `GET /api/v1/categories` and create one via `POST /api/v1/categories` (JWT) | plan §3.3 | Must |
| FR-PRODUCT-07 | Publish `product.catalog.created`, `product.catalog.updated`, `product.catalog.deleted` for the Cart Service | plan §3.3, §5.1 | Must |

### 2.4 Orders & Checkout (plan §3.4, §5)

| ID | Requirement | Source | Priority |
|----|-------------|--------|----------|
| FR-ORDER-01 | Place an order via existing `POST /api/v1/orders` and consume `cart.checkout.initiated` from Kafka | plan §3.4 | Must |
| FR-ORDER-02 | Support bulk order creation via existing `POST /api/v1/orders/bulk` | plan §3.4 | Could |
| FR-ORDER-03 | List the current user's orders with status via `GET /api/v1/orders` | plan §3.4 | Must |
| FR-ORDER-04 | Retrieve an order by id via `GET /api/v1/orders/{id}` | plan §3.4 | Must |
| FR-ORDER-05 | Update order status via `PATCH /api/v1/orders/{id}` and publish `order.status.changed` | plan §3.4 | Must |
| FR-ORDER-06 | Delete an order via `DELETE /api/v1/orders/{id}` | plan §3.4 | Should |
| FR-ORDER-07 | Publish `order.placed` for Admin Service (and Cart Service to clear) | plan §3.4, §5.1 | Must |
| FR-ORDER-08 | Manage customers via existing `GET/POST/PUT/DELETE /api/v1/customers{/id}` endpoints | plan §3.4 | Should |
| FR-ORDER-09 | Deduplicate `cart.checkout.initiated` events using the `eventId` idempotency key before placing an order | plan §5.3 | Must |
| FR-ORDER-10 | Simulate payment during checkout (no real PSP); record payment status against the order | plan §7.2 (screen 6) | Must |

### 2.5 Admin (plan §3.5)

| ID | Requirement | Source | Priority |
|----|-------------|--------|----------|
| FR-ADMIN-01 | Return dashboard metrics `{totalOrders, totalRevenue, totalUsers, totalProducts, recentOrders[]}` via `GET /api/v1/admin/dashboard` | plan §3.5 | Must |
| FR-ADMIN-02 | List orders with `status` filter and pagination via `GET /api/v1/admin/orders` | plan §3.5 | Must |
| FR-ADMIN-03 | Show full order details via `GET /api/v1/admin/orders/{id}` | plan §3.5 | Must |
| FR-ADMIN-04 | Update order status via `PUT /api/v1/admin/orders/{id}/status` | plan §3.5 | Must |
| FR-ADMIN-05 | List users with `search` and pagination via `GET /api/v1/admin/users` | plan §3.5 | Should |
| FR-ADMIN-06 | Show user details incl. `orderCount` via `GET /api/v1/admin/users/{id}` | plan §3.5 | Should |
| FR-ADMIN-07 | Enforce `JWT + ADMIN role` on every `/api/v1/admin/**` gateway route | plan §3.6 | Must |
| FR-ADMIN-08 | Record admin actions in `admin.audit_entries` (entity, action, performed_by, details) | plan §4.1 | Should |
| FR-ADMIN-09 | Consume `order.placed`, `order.status.changed`, `auth.user.registered`; perform startup sync for dashboard snapshots | plan §3.5, §5.1, §23 fix 14 | Must |

### 2.6 Frontend UI (plan §7)

| ID | Requirement | Source | Priority |
|----|-------------|--------|----------|
| FR-UI-01 | Render homepage with hero, featured products, and categories (screen 1) | plan §7.2 | Must |
| FR-UI-02 | Render product listing with grid, sidebar filters, search, and pagination (screen 2) | plan §7.2 | Must |
| FR-UI-03 | Render product detail with image carousel, description, and "add to cart" (screen 3) | plan §7.2 | Must |
| FR-UI-04 | Render shopping cart with items, quantities, and order summary (screen 4) | plan §7.2 | Must |
| FR-UI-05 | Provide checkout step 1 — shipping address form with validation (screen 5) | plan §7.2 | Must |
| FR-UI-06 | Provide checkout step 2 — simulated payment with order summary (screen 6) | plan §7.2 | Must |
| FR-UI-07 | Provide checkout step 3 — final review before placing (screen 7) | plan §7.2 | Must |
| FR-UI-08 | Show confirmation with order number and success message (screen 8) | plan §7.2 | Must |
| FR-UI-09 | Render login screen with email/password and register link (screen 9) | plan §7.2 | Must |
| FR-UI-10 | Render registration screen with full name, email, password, confirm (screen 10) | plan §7.2 | Must |
| FR-UI-11 | Render order history table with status badges (screen 11) | plan §7.2 | Must |
| FR-UI-12 | Render order detail with status timeline, items, and totals (screen 12) | plan §7.2 | Should |
| FR-UI-13 | Render admin dashboard with stats cards, charts, and recent orders (screen 13) | plan §7.2 | Must |
| FR-UI-14 | Render admin products/orders CRUD tables with search/filter (screen 14) | plan §7.2 | Must |
| FR-UI-15 | Support responsive layouts at 375 / 768 / 1280 / 1536 px breakpoints | plan §7.4 | Must |
| FR-UI-16 | Implement client API layer (`lib/api.ts`) with JWT attachment and token refresh | plan §1.1, §23 fix 5 | Must |
| FR-UI-17 | Route all frontend traffic through the API Gateway (`:8080`), never direct to services | plan §1.1, §3.6 | Must |
| FR-UI-18 | Use design tokens (colors, typography, spacing, radius) and the 18 shadcn/ui components listed in the plan | plan §7.1, §7.3 | Must |

## 3. Non-Functional Requirements

### 3.1 Security — NFR-SEC

| ID | Requirement | Source | Priority |
|----|-------------|--------|----------|
| NFR-SEC-01 | Passwords stored only as bcrypt hashes; never as plaintext or reversible ciphertext | plan §4.1, §23 | Must |
| NFR-SEC-02 | Access tokens short-lived; refresh tokens stored/rotated via `auth.refresh_tokens` and revoked on logout | plan §3.1, §4.1 | Must |
| NFR-SEC-03 | All service-to-service calls authenticated with `INTERNAL_API_KEY` and validated against `app.internal.allowed-services` allow-list | plan §4.4 | Must |
| NFR-SEC-04 | Role-based access: only `JWT + ADMIN` can reach `/api/v1/admin/**`; public reads allowed for `GET /api/v1/products(/{id})` and `GET /api/v1/categories` | plan §3.6 | Must |
| NFR-SEC-05 | Rate limiting at the gateway: login 10/min, register 5/min, products 200/min, cart 50/min, orders 30/min, default 100/min | plan §6.3 | Must |
| NFR-SEC-06 | CORS configurable per environment (default `http://localhost:3000`), credentials allowed, max-age 3600 | plan §6.2 | Must |
| NFR-SEC-07 | PII masking on all request/response logging (email, phone, tokens) | plan §14.3, §23 fix 9 | Must |
| NFR-SEC-08 | Input validation on all API bodies and query params; `detect-secrets` pre-commit hook blocks secret commits | plan §9.2, §13.1 | Must |
| NFR-SEC-09 | Zero high/critical vulnerabilities at merge (Snyk every PR, weekly scheduled scan, ZAP pre-deploy, Semgrep SAST) | plan §10.6, §11.3, §22.5 | Must |
| NFR-SEC-10 | HTTPS/TLS and transport security documented for production deployment | plan §23 fix 15 | Should |

### 3.2 Performance — NFR-PERF

| ID | Requirement | Source | Priority |
|----|-------------|--------|----------|
| NFR-PERF-01 | API latency p95 < 200 ms under load | plan §10.5, §22.5 | Must |
| NFR-PERF-02 | Lighthouse Largest Contentful Paint (LCP) < 2.5 s | plan §10.5, §22.5 | Must |
| NFR-PERF-03 | Lighthouse overall score ≥ 90 | plan §22.5, §9 (qa-accessibility) | Must |
| NFR-PERF-04 | Sustain 100 concurrent users (5-min load) and ramp to 500 (10-min stress) without SLO breach | plan §10.5 | Must |
| NFR-PERF-05 | Server-side pagination/filtering for all lists; skeletons for loading states | plan §3.3, §7.3 | Should |

### 3.3 Availability — NFR-AVAIL

| ID | Requirement | Source | Priority |
|----|-------------|--------|----------|
| NFR-AVAIL-01 | RTO ≤ 1 hour, RPO ≤ 24 hours | plan §16.2 | Must |
| NFR-AVAIL-02 | PostgreSQL `pg_dump` daily, 30-day retention | plan §16.1 | Must |
| NFR-AVAIL-03 | Redis RDB snapshots every 6 hours, 7-day retention | plan §16.1 | Must |
| NFR-AVAIL-04 | Kafka topic retention 7 days for replay recovery | plan §5.2, §16.1 | Should |
| NFR-AVAIL-05 | Every compose service has a healthcheck and supports graceful shutdown (`shutdown: graceful`) | plan §8.2, §23 fix 10 | Must |
| NFR-AVAIL-06 | Container boot ordering driven by healthchecks (`pg_isready`, `redis-cli ping`) before dependents start | plan §8.2 | Must |

### 3.4 Scalability — NFR-SCALE

| ID | Requirement | Source | Priority |
|----|-------------|--------|----------|
| NFR-SCALE-01 | Stateless services (gateway, auth, cart, product, admin) horizontally scalable via multiple compose replicas | plan §1.1, §21.1 | Should |
| NFR-SCALE-02 | Redis used for cache + distributed locks to offload hot catalog reads | plan §1.1, §4.1 | Must |
| NFR-SCALE-03 | All list endpoints paginated server-side to bound result sets | plan §3.3, §3.5 | Must |
| NFR-SCALE-04 | `max_connections = 200` budgeted across services (HikariCP pool sizing with headroom); single-Postgres bottleneck tracked in risk R-04 | plan §4.3 | Must |
| NFR-SCALE-05 | Kafka topics partitioned (3 partitions) to allow parallel consumers and scale out | plan §5.2, §23 fix 13 | Should |

### 3.5 Observability — NFR-OBS

| ID | Requirement | Source | Priority |
|----|-------------|--------|----------|
| NFR-OBS-01 | Prometheus metrics exported by every service; Grafana dashboards for the platform | plan §14.1 | Must |
| NFR-OBS-02 | Structured JSON logs with `traceId`/`spanId` and PII masking | plan §14.3 | Must |
| NFR-OBS-03 | Distributed tracing via Jaeger + OpenTelemetry across gateway and services | plan §1.2, §14.1 | Must |
| NFR-OBS-04 | Log aggregation with Loki + Promtail | plan §14.1 | Must |
| NFR-OBS-05 | Alert rules: `HighErrorRate` (5xx > 5% for 5 min), `HighLatency` (p95 > 0.5 s for 5 min), `ServiceDown` (1 min) routed via Alertmanager | plan §14.2 | Must |
| NFR-OBS-06 | Correlation IDs propagate across service calls to correlate one user request | plan §22.4, §14.3 | Must |

### 3.6 Accessibility — NFR-ACC

| ID | Requirement | Source | Priority |
|----|-------------|--------|----------|
| NFR-ACC-01 | WCAG 2.1 AA compliance across all 14 screens | plan §7.5, §22.5 | Must |
| NFR-ACC-02 | Text contrast ratio ≥ 4.5:1 | plan §7.5 | Must |
| NFR-ACC-03 | All interactive elements keyboard-focusable with visible focus states | plan §7.5 | Must |
| NFR-ACC-04 | Alt text on images, ARIA labels on inputs, errors linked via `aria-describedby`, skip-to-content link, semantic HTML | plan §7.5 | Must |
| NFR-ACC-05 | Zero WCAG 2.1 AA violations from axe-core audits gated in CI | plan §22.5, §22.3 | Must |

## 4. Traceability & Verification

| Requirement Set | Verified By | Plan Reference |
|-----------------|-------------|----------------|
| FR-AUTH-01..07 | Spring Security integration tests, Playwright login/register flows | plan §10.3, §10.4 |
| FR-CART-01..07 | Cart integration tests (Testcontainers), E2E add-to-cart flow, Kafka event tests | plan §10.3, §10.4 |
| FR-PRODUCT-01..07 | Product search/filter integration tests (k6 scenarios for perf), E2E browse flow | plan §10.3–10.5 |
| FR-ORDER-01..10 | Idempotent-consumer tests, order E2E (login→browse→cart→checkout→confirmation) | plan §5.3, §10.4 |
| FR-ADMIN-01..09 | Admin Playwright suite, role-based access security tests | plan §10.3, §10.4 |
| FR-UI-01..18 | Playwright E2E, Lighthouse + axe-core (accessibility), Vitest unit tests | plan §10.2, §10.4, §22.3 |
| NFR-SEC | ZAP, Snyk, Semgrep, dependency-check, security integration tests | plan §10.6, §11.3 |
| NFR-PERF | k6 load/stress, Lighthouse CI | plan §10.5, §9 (qa-performance) |
| NFR-AVAIL | Backup scheduling + restore drills, healthcheck script | plan §16, §23 fixes 12/16 |
| NFR-SCALE | k6 ramp to 500 users, pool sizing review | plan §10.5 |
| NFR-OBS | Grafana dashboards, alert firing tests | plan §14.2 |
| NFR-ACC | axe-core + Lighthouse accessibility gates | plan §7.5, §22.5 |

## 5. Traceable Backlog Hand-off

Every FR maps to at least one user story in [03-user-stories.md](03-user-stories.md); acceptance criteria in the story references the FR IDs above. Change requests to any FR must update the stories and re-run affected verification gates before merge.