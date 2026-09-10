# E-Commerce Platform — Complete SDLC Plan (v2.0)

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Repository Structure](#2-repository-structure)
3. [Service Contracts](#3-service-contracts)
4. [Database Design](#4-database-design)
5. [Kafka Event Design](#5-kafka-event-design)
6. [API Gateway Configuration](#6-api-gateway-configuration)
7. [UX/UI Design](#7-ux--ui-design)
8. [Docker Compose](#8-docker-compose)
9. [Makefile & DX](#9-makefile--dx)
10. [QA Strategy](#10-qa-strategy)
11. [CI/CD Pipelines](#11-cicd-pipelines)
12. [Git Branching Strategy](#12-git-branching-strategy)
13. [Code Review Process](#13-code-review-process)
14. [Monitoring & Observability](#14-monitoring--observability)
15. [Versioning & Release Management](#15-versioning--release-management)
16. [Disaster Recovery](#16-disaster-recovery)
17. [Sprint Retrospectives](#17-sprint-retrospectives)
18. [AI Documentation](#18-ai-documentation)
19. [SDLC Documentation Artifacts](#19-sdlc-documentation-artifacts)
20. [Execution Phases](#20-execution-phases)
21. [Resource Summary](#21-resource-summary)
22. [Final Checklist](#22-final-checklist)
23. [Fixes Applied](#23-fixes-applied)
24. [Agent Structure](#24-agent-structure)
25. [Skills Structure](#25-skills-structure)
26. [GitHub Strategy](#26-github-strategy)

---

## 1. Architecture Overview

### 1.1 System Architecture Diagram

```
                              ┌──────────────────────┐
                              │    Next.js Frontend    │
                              │      :3000             │
                              │  lib/api.ts (JWT +     │
                              │  token refresh)        │
                              └──────────┬─────────────┘
                                         │
                              ┌──────────▼─────────────┐
                              │    API Gateway          │
                              │  Spring Cloud Gateway   │
                              │  :8080                  │
                              │  - JWT validation       │
                              │  - Rate limiting        │
                              │  - CORS (configurable)  │
                              │  - Request logging      │
                              └──────────┬─────────────┘
                                         │
        ┌────────────┬────────────┬──────┴──────┬────────────┬────────────┐
        │            │            │             │            │            │
   ┌────▼────┐ ┌────▼────┐ ┌────▼────┐  ┌─────▼─────┐ ┌───▼───┐ ┌────▼────┐
   │  Auth   │ │  Cart   │ │ Product │  │   Order   │ │ Admin │ │  Kafka  │
   │ Service │ │ Service │ │ Service │  │  Mgmt API │ │Service│ │         │
   │ :8081   │ │ :8082   │ │ :8083   │  │  :8084    │ │:8085  │ │         │
   │         │ │         │ │         │  │           │ │       │ │         │
   │ Internal│ │ Calls   │ │ Returns │  │ Consumes  │ │Syncs  │ │         │
   │ API Key │ │ Product │ │ data    │  │ Kafka     │ │on     │ │         │
   │         │ │ Service │ │         │  │ events    │ │startup│ │         │
   └────┬────┘ └────┬────┘ └────┬────┘  └─────┬─────┘ └───┬───┘ └─────────┘
        │            │            │             │            │
        └────────────┴────────────┴──────┬──────┴────────────┘
                                         │
                              ┌──────────▼─────────────┐
                              │    PostgreSQL 16        │
                              │       :5432             │
                              │   max_connections: 200  │
                              │   ┌─────┬─────┬──────┐ │
                              │   │auth │cart │product│ │
                              │   ├─────┼─────┼──────┤ │
                              │   │orders│ admin│     │ │
                              │   └─────┴─────┴──────┘ │
                              │   Liquibase (all)       │
                              └─────────────────────────┘
                                         │
                              ┌──────────▼─────────────┐
                              │    Redis :6379          │
                              │  (cache + locks)        │
                              └─────────────────────────┘
```

### 1.2 Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Frontend | Next.js (App Router) | 14.x |
| UI Library | React | 18.x |
| Language (Frontend) | TypeScript | 5.x |
| Styling | Tailwind CSS | 3.x |
| UI Components | shadcn/ui | Latest |
| Backend | Spring Boot | 3.4.x |
| Language (Backend) | Java | 21 LTS |
| Security | Spring Security (OAuth2 Resource Server) | Latest |
| ORM | Spring Data JPA / Hibernate | Latest |
| Database | PostgreSQL (with pgvector) | 16 |
| Schema Management | Liquibase | Latest |
| Cache | Redis | 7 |
| Messaging | Apache Kafka (KRaft) | 3.7.0 |
| API Docs | SpringDoc OpenAPI | 2.7.0 |
| Resilience | Resilience4j | 2.2.0 |
| Container | Docker + Docker Compose | Latest |
| CI/CD | GitHub Actions | - |
| Monitoring | Prometheus + Grafana + Loki | Latest |
| Tracing | Jaeger (OpenTelemetry) | 1.57 |
| API Gateway | Spring Cloud Gateway | Latest |
| Testing | JUnit 5, Mockito, Testcontainers, Vitest, Playwright | Latest |

---

## 2. Repository Structure

### 2.1 Monorepo Layout

```
/Projects/Library/
├── sdlc/                          # Orchestrator repo
│   ├── docker-compose.yml         # ALL 23 services with profiles
│   ├── Makefile                   # Build, test, dev commands
│   ├── docs/                      # SDLC documentation (15 docs)
│   ├── planning/                  # This plan
│   ├── scripts/                   # Seed, QA, backup scripts
│   ├── monitoring/                # Prometheus, Grafana, Loki configs
│   ├── .github/workflows/         # CI/CD for orchestrator
│   ├── .pre-commit-config.yaml    # Pre-commit hooks
│   ├── .editorconfig              # Editor settings
│   ├── .env.example               # Environment template
│   ├── .gitignore
│   └── README.md
│
├── api-gateway/                   # NEW — Spring Cloud Gateway
│   ├── src/
│   ├── pom.xml
│   ├── Dockerfile
│   ├── .github/workflows/
│   └── README.md
│
├── auth-service/                  # NEW — Authentication & Users
│   ├── src/
│   ├── pom.xml
│   ├── Dockerfile
│   ├── .github/workflows/
│   └── README.md
│
├── cart-service/                  # NEW — Shopping Cart
│   ├── src/
│   ├── pom.xml
│   ├── Dockerfile
│   ├── .github/workflows/
│   └── README.md
│
├── product-service/               # NEW — Product Catalog & Search
│   ├── src/
│   ├── pom.xml
│   ├── Dockerfile
│   ├── .github/workflows/
│   └── README.md
│
├── order-management-api/          # EXISTING — Orders, Customers, Payments
│   ├── src/
│   ├── pom.xml
│   ├── Dockerfile
│   ├── .github/workflows/
│   └── README.md
│
├── admin-service/                 # NEW — Admin Dashboard
│   ├── src/
│   ├── pom.xml
│   ├── Dockerfile
│   ├── .github/workflows/
│   └── README.md
│
└── e-commerce-frontend/           # NEW — Next.js 14
    ├── src/
    ├── package.json
    ├── Dockerfile
    ├── .github/workflows/
    └── README.md
```

### 2.2 Repository Summary

| # | Repo Name | Type | Framework | Port |
|---|-----------|------|-----------|------|
| 1 | `sdlc/` | Orchestrator | Docker Compose + Docs | — |
| 2 | `api-gateway/` | New | Spring Cloud Gateway | 8080 |
| 3 | `auth-service/` | New | Spring Boot 3.4 | 8081 |
| 4 | `cart-service/` | New | Spring Boot 3.4 | 8082 |
| 5 | `product-service/` | New | Spring Boot 3.4 | 8083 |
| 6 | `order-management-api/` | Existing | Spring Boot 3.4 | 8084 |
| 7 | `admin-service/` | New | Spring Boot 3.4 | 8085 |
| 8 | `e-commerce-frontend/` | New | Next.js 14 | 3000 |

---

## 3. Service Contracts

### 3.1 Auth Service (`auth-service` — Port 8081)

| Method | Endpoint | Body | Response | Auth |
|--------|----------|------|----------|------|
| POST | `/api/v1/auth/register` | `{email, password, fullName, phoneNumber}` | `{id, email, fullName}` | No |
| POST | `/api/v1/auth/login` | `{email, password}` | `{accessToken, refreshToken, user}` | No |
| POST | `/api/v1/auth/refresh` | `{refreshToken}` | `{accessToken}` | No |
| GET | `/api/v1/auth/profile` | — | `{id, email, fullName, phoneNumber}` | JWT |
| PUT | `/api/v1/auth/profile` | `{fullName, phoneNumber}` | `{id, email, fullName}` | JWT |
| POST | `/api/v1/auth/logout` | — | 204 No Content | JWT |

**Database schema:** `auth`
**Tables:** `users`, `refresh_tokens`
**Kafka events published:** `auth.user.registered`, `auth.user.updated`

### 3.2 Cart Service (`cart-service` — Port 8082)

| Method | Endpoint | Body | Response | Auth |
|--------|----------|------|----------|------|
| GET | `/api/v1/cart` | — | `{id, items[], subtotal, tax, total}` | JWT |
| POST | `/api/v1/cart/items` | `{productId, quantity}` | `{id, items[], subtotal, total}` | JWT |
| PUT | `/api/v1/cart/items/{itemId}` | `{quantity}` | `{id, items[], subtotal, total}` | JWT |
| DELETE | `/api/v1/cart/items/{itemId}` | — | `{id, items[], subtotal, total}` | JWT |
| DELETE | `/api/v1/cart` | — | 204 No Content | JWT |

**Database schema:** `cart`
**Tables:** `carts`, `cart_items`
**Dependencies:** Calls Product Service (REST) for price/stock validation
**Kafka events subscribed:** `product.catalog.updated`, `order.placed`
**Kafka events published:** `cart.checkout.initiated`

### 3.3 Product Service (`product-service` — Port 8083)

| Method | Endpoint | Query Params | Response | Auth |
|--------|----------|-------------|----------|------|
| GET | `/api/v1/products` | `search, category, minPrice, maxPrice, sort, page, size` | `{content[], totalElements, totalPages}` | No |
| GET | `/api/v1/products/{id}` | — | `{id, name, description, price, stockQuantity, categories[]}` | No |
| POST | `/api/v1/products` | — | `{id, name, ...}` | JWT |
| PUT | `/api/v1/products/{id}` | — | `{id, name, ...}` | JWT |
| DELETE | `/api/v1/products/{id}` | — | 204 No Content | JWT |
| GET | `/api/v1/categories` | — | `[{id, name, description}]` | No |
| POST | `/api/v1/categories` | — | `{id, name, description}` | JWT |

**Database schema:** `product`
**Tables:** `products`, `categories`, `product_categories`
**Kafka events published:** `product.catalog.created`, `product.catalog.updated`, `product.catalog.deleted`

### 3.4 Order Management API (`order-management-api` — Port 8084) — EXISTING

| Method | Endpoint | Notes |
|--------|----------|-------|
| POST | `/api/v1/orders` | Existing — add Kafka producer for `order.placed` |
| POST | `/api/v1/orders/bulk` | Existing |
| GET | `/api/v1/orders` | Existing |
| GET | `/api/v1/orders/{id}` | Existing |
| PATCH | `/api/v1/orders/{id}` | Existing — add Kafka producer for `order.status.changed` |
| DELETE | `/api/v1/orders/{id}` | Existing |
| GET | `/api/v1/customers` | Existing |
| GET | `/api/v1/customers/{id}` | Existing |
| POST | `/api/v1/customers` | Existing |
| PUT | `/api/v1/customers/{id}` | Existing |
| DELETE | `/api/v1/customers/{id}` | Existing |
| GET | `/api/v1/products` | Existing |
| GET | `/api/v1/products/{id}` | Existing |
| POST | `/api/v1/products` | Existing |
| PUT | `/api/v1/products/{id}` | Existing |
| DELETE | `/api/v1/products/{id}` | Existing |

**Changes needed:** Add Kafka consumer for `cart.checkout.initiated` + producers for order events

### 3.5 Admin Service (`admin-service` — Port 8085)

| Method | Endpoint | Query Params | Response | Auth |
|--------|----------|-------------|----------|------|
| GET | `/api/v1/admin/dashboard` | — | `{totalOrders, totalRevenue, totalUsers, totalProducts, recentOrders[]}` | JWT |
| GET | `/api/v1/admin/orders` | `status, page, size` | `{content[], totalElements}` | JWT |
| GET | `/api/v1/admin/orders/{id}` | — | `{order details}` | JWT |
| PUT | `/api/v1/admin/orders/{id}/status` | — | `{status}` | JWT |
| GET | `/api/v1/admin/users` | `search, page, size` | `{content[], totalElements}` | JWT |
| GET | `/api/v1/admin/users/{id}` | — | `{user details, orderCount}` | JWT |

**Database schema:** `admin`
**Tables:** `dashboard_snapshots`, `audit_entries`
**Kafka events subscribed:** `order.placed`, `order.status.changed`, `auth.user.registered`

### 3.6 API Gateway (`api-gateway` — Port 8080)

| Route | Target | Auth Required |
|-------|--------|---------------|
| `/api/v1/auth/**` | auth-service:8081 | No (login/register) |
| `/api/v1/cart/**` | cart-service:8082 | Yes (JWT) |
| `/api/v1/products/**` | product-service:8083 | No (GET), Yes (POST/PUT/DELETE) |
| `/api/v1/categories/**` | product-service:8083 | No (GET), Yes (POST) |
| `/api/v1/orders/**` | order-api:8084 | Yes (JWT) |
| `/api/v1/customers/**` | order-api:8084 | Yes (JWT) |
| `/api/v1/admin/**` | admin-service:8085 | Yes (JWT + ADMIN role) |

---

## 4. Database Design

### 4.1 Single PostgreSQL with 5 Schemas

```
PostgreSQL 16 (pgvector)
├── auth schema
│   ├── users (id, email, password_hash, full_name, phone_number, role, created_at, updated_at)
│   └── refresh_tokens (id, user_id, token, expires_at, created_at)
│
├── cart schema
│   ├── carts (id, user_id, created_at, updated_at)
│   └── cart_items (id, cart_id, product_id, quantity, unit_price, created_at, updated_at)
│
├── product schema
│   ├── products (id, name, description, price, stock_quantity, created_at, updated_at)
│   ├── categories (id, name, description, created_at, updated_at)
│   └── product_categories (product_id, category_id)
│
├── orders schema (existing — Liquibase-managed)
│   ├── customers (id, email, full_name, phone_number, ...)
│   ├── addresses (id, customer_id, street, city, state, postal_code, country, ...)
│   ├── orders (id, customer_id, order_number, status, total_amount, ...)
│   ├── order_items (id, order_id, product_id, quantity, unit_price, ...)
│   ├── payments (id, order_id, amount, payment_method, status, ...)
│   └── ... (audit_log, event_store, idempotency_keys, outbox)
│
└── admin schema
    ├── dashboard_snapshots (id, metric_name, metric_value, recorded_at)
    └── audit_entries (id, entity_type, entity_id, action, performed_by, performed_at, details)
```

### 4.2 Migration Naming Convention (Liquibase — Standardized)

```
db/{service}/changelog/
├── db.changelog-master.xml
└── v1.0/
    ├── 01_create_users_table.xml
    ├── 02_create_refresh_tokens_table.xml
    └── ...
```

### 4.3 PostgreSQL Configuration

```yaml
# docker-compose.yml
postgres:
  image: pgvector/pg16
  command: >
    postgres
    -c max_connections=200
    -c shared_buffers=256MB
    -c effective_cache_size=768MB
    -c work_mem=4MB
    -c maintenance_work_mem=128MB
  environment:
    POSTGRES_DB: ecommerce
    POSTGRES_USER: ecommerce
    POSTGRES_PASSWORD: secret
```

### 4.4 Service-to-Service Authentication

```yaml
# application.yml (per service)
app:
  internal:
    api-key: ${INTERNAL_API_KEY:internal-service-key-12345}
    allowed-services:
      - cart-service
      - admin-service
      - order-api
```

---

## 5. Kafka Event Design

### 5.1 Topic Definitions

| Topic | Producer | Consumer(s) | Payload |
|-------|----------|-------------|---------|
| `auth.user.registered` | Auth Service | Admin Service | `{userId, email, fullName, registeredAt}` |
| `auth.user.updated` | Auth Service | Admin Service | `{userId, email, fullName, updatedAt}` |
| `cart.checkout.initiated` | Cart Service | Order API | `{eventId, cartId, userId, items[], shippingAddress}` |
| `product.catalog.created` | Product Service | Cart Service | `{productId, name, price, stockQuantity}` |
| `product.catalog.updated` | Product Service | Cart Service | `{productId, name, price, stockQuantity}` |
| `product.catalog.deleted` | Product Service | Cart Service | `{productId}` |
| `order.placed` | Order API | Admin Service, Cart Service | `{orderId, orderNumber, userId, totalAmount, items[]}` |
| `order.status.changed` | Order API | Admin Service | `{orderId, orderNumber, oldStatus, newStatus, changedAt}` |

### 5.2 Topic Configuration

```yaml
topics:
  - name: auth.user.registered
    partitions: 3
    replicationFactor: 1
    retentionMs: 604800000  # 7 days
  - name: auth.user.updated
    partitions: 3
    replicationFactor: 1
    retentionMs: 604800000
  - name: cart.checkout.initiated
    partitions: 3
    replicationFactor: 1
    retentionMs: 604800000
  - name: product.catalog.created
    partitions: 3
    replicationFactor: 1
    retentionMs: 604800000
  - name: product.catalog.updated
    partitions: 3
    replicationFactor: 1
    retentionMs: 604800000
  - name: product.catalog.deleted
    partitions: 3
    replicationFactor: 1
    retentionMs: 604800000
  - name: order.placed
    partitions: 3
    replicationFactor: 1
    retentionMs: 604800000
  - name: order.status.changed
    partitions: 3
    replicationFactor: 1
    retentionMs: 604800000
```

### 5.3 Kafka Consumer Idempotency

```java
// Event payload with idempotency key
public record CartCheckoutEvent(
    String eventId,          // UUID - idempotency key
    Long cartId,
    Long userId,
    List<CartItem> items,
    Address shippingAddress,
    LocalDateTime occurredAt
) {}

// Consumer deduplication
@Service
public class CheckoutEventConsumer {
    
    private final IdempotencyKeyRepository idempotencyRepo;
    private final OrderService orderService;
    
    @KafkaListener(topics = "cart.checkout.initiated")
    public void handleCheckout(CartCheckoutEvent event) {
        if (idempotencyRepo.existsById(event.eventId())) {
            log.warn("Duplicate event ignored: {}", event.eventId());
            return;
        }
        
        orderService.placeOrder(event);
        
        idempotencyRepo.save(new IdempotencyRecord(
            event.eventId(),
            "CART_CHECKOUT",
            LocalDateTime.now()
        ));
    }
}
```

---

## 6. API Gateway Configuration

### 6.1 Route Configuration

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: auth-service
          uri: http://auth-service:8081
          predicates:
            - Path=/api/v1/auth/**
        - id: cart-service
          uri: http://cart-service:8082
          predicates:
            - Path=/api/v1/cart/**
        - id: product-service-read
          uri: http://product-service:8083
          predicates:
            - Path=/api/v1/products/**,/api/v1/categories/**
            - Method=GET
        - id: product-service-write
          uri: http://product-service:8083
          predicates:
            - Path=/api/v1/products/**,/api/v1/categories/**
            - Method=POST,PUT,DELETE
        - id: order-api
          uri: http://order-api:8084
          predicates:
            - Path=/api/v1/orders/**,/api/v1/customers/**
        - id: admin-service
          uri: http://admin-service:8085
          predicates:
            - Path=/api/v1/admin/**
```

### 6.2 CORS Configuration

```yaml
app:
  cors:
    allowed-origins: ${CORS_ALLOWED_ORIGINS:http://localhost:3000}
    allowed-methods: GET,POST,PUT,DELETE,PATCH,OPTIONS
    allowed-headers: "*"
    allow-credentials: true
    max-age: 3600
```

### 6.3 Rate Limiting

```yaml
app:
  rate-limit:
    enabled: ${RATE_LIMIT_ENABLED:true}
    default-limit: ${RATE_LIMIT_PER_MINUTE:100}
    window-size: 60
    endpoints:
      /api/v1/auth/login: 10
      /api/v1/auth/register: 5
      /api/v1/products: 200
      /api/v1/cart/**: 50
      /api/v1/orders/**: 30
```

---

## 7. UX/UI Design

### 7.1 Design Tokens

```json
{
  "colors": {
    "primary": { "50": "#eff6ff", "500": "#3b82f6", "600": "#2563eb", "700": "#1d4ed8", "900": "#1e3a8a" },
    "neutral": { "50": "#fafafa", "100": "#f4f4f5", "300": "#d4d4d8", "500": "#71717a", "700": "#3f3f46", "900": "#18181b" },
    "success": "#22c55e",
    "warning": "#f59e0b",
    "error": "#ef4444",
    "info": "#3b82f6"
  },
  "typography": {
    "fontFamily": { "sans": "Inter, system-ui, sans-serif", "mono": "JetBrains Mono, monospace" },
    "fontSize": { "xs": "0.75rem", "sm": "0.875rem", "base": "1rem", "lg": "1.125rem", "xl": "1.25rem", "2xl": "1.5rem", "3xl": "1.875rem", "4xl": "2.25rem" }
  },
  "spacing": { "xs": "0.25rem", "sm": "0.5rem", "md": "1rem", "lg": "1.5rem", "xl": "2rem", "2xl": "3rem", "3xl": "4rem" },
  "borderRadius": { "sm": "0.25rem", "md": "0.375rem", "lg": "0.5rem", "xl": "0.75rem", "2xl": "1rem", "full": "9999px" },
  "breakpoints": { "mobile": "375px", "tablet": "768px", "desktop": "1280px", "wide": "1536px" }
}
```

### 7.2 Wireframes (14 Screens)

1. Home Page — Hero, featured products, categories
2. Product Listing — Grid, sidebar filters, search, pagination
3. Product Detail — Image carousel, description, add to cart
4. Shopping Cart — Items, quantities, order summary
5. Checkout — Address — Shipping form, validation
6. Checkout — Payment — Simulated payment, order summary
7. Checkout — Review — Final review before placing
8. Checkout — Confirmation — Order number, success message
9. Login — Email + password, register link
10. Register — Full name, email, password, confirm
11. Order History — Table with status badges
12. Order Detail — Status timeline, items, totals
13. Admin Dashboard — Stats cards, charts, recent orders
14. Admin Products/Orders — CRUD tables with search/filter

### 7.3 Component Library (shadcn/ui)

| Component | Usage |
|-----------|-------|
| Button | All actions |
| Card | Product cards, stats |
| Dialog | Modals, confirmations |
| Input | Forms |
| Select | Dropdowns, filters |
| Badge | Status indicators |
| Table | Admin data tables |
| Toast | Notifications |
| Tabs | Checkout steps |
| Sheet | Cart slide-over (mobile) |
| Separator | Dividers |
| Skeleton | Loading states |
| Avatar | User profile |
| Dropdown | User menu |
| Pagination | Product listing |
| Breadcrumb | Navigation |
| Carousel | Product images |
| Slider | Price range filter |

### 7.4 Responsive Breakpoints

| Breakpoint | Width | Layout Changes |
|------------|-------|----------------|
| Mobile | 375px | Single column, hamburger nav, stacked cards |
| Tablet | 768px | 2-column grid, collapsible sidebar |
| Desktop | 1280px | 3-4 column grid, full nav, sidebar filters |
| Wide | 1536px | Max-width container, 4-column grid |

### 7.5 Accessibility (WCAG 2.1 AA)

- Color contrast ratio >= 4.5:1 for text
- All interactive elements keyboard-focusable
- Focus visible states on all buttons/links
- Alt text on all images
- ARIA labels on form inputs
- Error messages linked to inputs via `aria-describedby`
- Skip-to-content link
- Semantic HTML (`<nav>`, `<main>`, `<article>`, `<aside>`)

---

## 8. Docker Compose

### 8.1 Profiles

| Profile | Services | RAM | Use Case |
|---------|----------|-----|----------|
| `backend` | App + infra | ~3.5GB | Backend development |
| `sdlc` | Plane + BookStack | ~3GB | SDLC tooling |
| `monitoring` | Prometheus + Grafana + Loki + Promtail + Alertmanager | ~1.5GB | Observability |
| `qa` | SonarQube + ZAP | ~2GB | Quality assurance |
| `design` | Penpot | ~2GB | UX design |
| `full` | Everything | ~12GB | Complete environment |

### 8.2 Complete Service List (23 services)

```yaml
services:
  # ===== CORE APP (profile: backend, full) =====
  api-gateway:
    profiles: ["backend", "full"]
    build: ../api-gateway
    ports: ["8080:8080"]
    depends_on:
      postgres: { condition: service_healthy }
      redis: { condition: service_healthy }
      auth-service: { condition: service_started }

  auth-service:
    profiles: ["backend", "full"]
    build: ../auth-service
    ports: ["8081:8081"]
    depends_on:
      postgres: { condition: service_healthy }
      redis: { condition: service_healthy }
      kafka: { condition: service_started }

  cart-service:
    profiles: ["backend", "full"]
    build: ../cart-service
    ports: ["8082:8082"]
    depends_on:
      postgres: { condition: service_healthy }
      redis: { condition: service_healthy }
      kafka: { condition: service_started }
      product-service: { condition: service_started }

  product-service:
    profiles: ["backend", "full"]
    build: ../product-service
    ports: ["8083:8083"]
    depends_on:
      postgres: { condition: service_healthy }
      redis: { condition: service_healthy }
      kafka: { condition: service_started }

  order-api:
    profiles: ["backend", "full"]
    build: ../order-management-api
    ports: ["8084:8084"]
    depends_on:
      postgres: { condition: service_healthy }
      redis: { condition: service_healthy }
      kafka: { condition: service_started }

  admin-service:
    profiles: ["backend", "full"]
    build: ../admin-service
    ports: ["8085:8085"]
    depends_on:
      postgres: { condition: service_healthy }
      kafka: { condition: service_started }

  frontend:
    profiles: ["backend", "full"]
    build: ../e-commerce-frontend
    ports: ["3000:3000"]
    depends_on:
      api-gateway: { condition: service_started }

  # ===== INFRASTRUCTURE =====
  postgres:
    image: pgvector/pg16
    ports: ["5432:5432"]
    command: >
      postgres
      -c max_connections=200
      -c shared_buffers=256MB
    volumes: [postgres_data:/var/lib/postgresql/data]
    environment:
      POSTGRES_DB: ecommerce
      POSTGRES_USER: ecommerce
      POSTGRES_PASSWORD: ${DB_PASSWORD:-secret}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ecommerce"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
    volumes: [redis_data:/data]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  kafka:
    image: apache/kafka:3.7.0
    ports: ["9092:9092"]
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
      CLUSTER_ID: MkU3OEVBNTcwNTJENDM2Qk
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
      KAFKA_LOG_RETENTION_HOURS: 168

  jaeger:
    image: jaegertracing/all-in-one:1.57
    ports: ["16686:16686", "14268:14268"]

  # ===== SDLC TOOLS (profile: sdlc, full) =====
  plane-frontend:
    profiles: ["sdlc", "full"]
    image: makeplane/plane-frontend:latest
    ports: ["3001:3000"]
    depends_on: [plane-backend]

  plane-backend:
    profiles: ["sdlc", "full"]
    image: makeplane/plane-backend:latest
    ports: ["8000:8000"]
    depends_on: [plane-postgres, plane-redis]

  plane-worker:
    profiles: ["sdlc", "full"]
    image: makeplane/plane-backend:latest
    command: celery -A plane worker -l info
    depends_on: [plane-redis, plane-postgres]

  plane-postgres:
    profiles: ["sdlc", "full"]
    image: postgres:15-alpine
    volumes: [plane_pg_data:/var/lib/postgresql/data]
    environment:
      POSTGRES_DB: plane
      POSTGRES_USER: plane
      POSTGRES_PASSWORD: plane_secret

  plane-redis:
    profiles: ["sdlc", "full"]
    image: redis:7-alpine
    volumes: [plane_redis_data:/data]

  bookstack:
    profiles: ["sdlc", "full"]
    image: lscr.io/linuxserver/bookstack:latest
    ports: ["6000:80"]
    depends_on: [bookstack-db]
    environment:
      DB_HOST: bookstack-db
      DB_DATABASE: bookstack
      DB_USERNAME: bookstack
      DB_PASSWORD: bookstack_secret
      APP_URL: http://localhost:6000

  bookstack-db:
    profiles: ["sdlc", "full"]
    image: mysql:8.0
    volumes: [bookstack_db_data:/var/lib/mysql]
    environment:
      MYSQL_ROOT_PASSWORD: root_secret
      MYSQL_DATABASE: bookstack
      MYSQL_USER: bookstack
      MYSQL_PASSWORD: bookstack_secret

  # ===== MONITORING (profile: monitoring, full) =====
  prometheus:
    profiles: ["monitoring", "full"]
    image: prom/prometheus:latest
    ports: ["9090:9090"]
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus

  grafana:
    profiles: ["monitoring", "full"]
    image: grafana/grafana:latest
    ports: ["3002:3000"]
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin

  loki:
    profiles: ["monitoring", "full"]
    image: grafana/loki:latest
    ports: ["3100:3100"]

  promtail:
    profiles: ["monitoring", "full"]
    image: grafana/promtail:latest
    volumes:
      - /var/log:/var/log
      - ./monitoring/promtail/config.yml:/etc/promtail/config.yml

  alertmanager:
    profiles: ["monitoring", "full"]
    image: prom/alertmanager:latest
    ports: ["9093:9093"]
    volumes:
      - ./monitoring/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml

  # ===== QA TOOLS (profile: qa, full) =====
  sonarqube:
    profiles: ["qa", "full"]
    image: sonarqube:community
    ports: ["9000:9000"]
    volumes: [sonarqube_data:/opt/sonarqube/data]

  zap:
    profiles: ["qa", "full"]
    image: ghcr.io/zaproxy/zaproxy:stable
    ports: ["8090:8090"]

  # ===== DESIGN TOOLS (profile: design, full) =====
  penpot-frontend:
    profiles: ["design", "full"]
    image: penpotapp/frontend:latest
    ports: ["9001:80"]
    depends_on: [penpot-backend]

  penpot-backend:
    profiles: ["design", "full"]
    image: penpotapp/backend:latest
    depends_on: [penpot-exporter, penpot-postgres, penpot-redis]

  penpot-exporter:
    profiles: ["design", "full"]
    image: penpotapp/exporter:latest

  penpot-postgres:
    profiles: ["design", "full"]
    image: postgres:15-alpine
    volumes: [penpot_pg_data:/var/lib/postgresql/data]
    environment:
      POSTGRES_DB: penpot
      POSTGRES_USER: penpot
      POSTGRES_PASSWORD: penpot_secret

  penpot-redis:
    profiles: ["design", "full"]
    image: redis:7-alpine
    volumes: [penpot_redis_data:/data]

volumes:
  postgres_data:
  redis_data:
  plane_pg_data:
  plane_redis_data:
  bookstack_db_data:
  prometheus_data:
  grafana_data:
  sonarqube_data:
  penpot_pg_data:
  penpot_redis_data:
```

---

## 9. Makefile & DX

### 9.1 Makefile

```makefile
.PHONY: setup dev dev-full infra sdlc monitoring qa design build test lint seed clean help

# ===== SETUP =====
setup:
	@echo "Creating service repositories..."
	@mkdir -p ../api-gateway ../auth-service ../cart-service ../product-service ../admin-service ../e-commerce-frontend

# ===== DOCKER =====
dev:
	docker compose --profile backend up --build

dev-full:
	docker compose --profile full up --build

infra:
	docker compose up postgres redis kafka jaeger

sdlc:
	docker compose --profile sdlc up

monitoring:
	docker compose --profile monitoring up

qa:
	docker compose --profile qa up

design:
	docker compose --profile design up

# ===== BUILD =====
build:
	cd ../api-gateway && ./mvnw clean package -DskipTests
	cd ../auth-service && ./mvnw clean package -DskipTests
	cd ../cart-service && ./mvnw clean package -DskipTests
	cd ../product-service && ./mvnw clean package -DskipTests
	cd ../order-management-api && ./mvnw clean package -DskipTests
	cd ../admin-service && ./mvnw clean package -DskipTests
	cd ../e-commerce-frontend && npm run build

# ===== TEST =====
test:
	@bash scripts/run-tests.sh

test-backend:
	cd ../api-gateway && ./mvnw test
	cd ../auth-service && ./mvnw test
	cd ../cart-service && ./mvnw test
	cd ../product-service && ./mvnw test
	cd ../order-management-api && ./mvnw test
	cd ../admin-service && ./mvnw test

test-frontend:
	cd ../e-commerce-frontend && npm run test

test-e2e:
	cd ../e-commerce-frontend && npx playwright test

# ===== LINT =====
lint:
	cd ../e-commerce-frontend && npm run lint
	cd ../api-gateway && ./mvnw checkstyle:check
	cd ../auth-service && ./mvnw checkstyle:check
	cd ../cart-service && ./mvnw checkstyle:check
	cd ../product-service && ./mvnw checkstyle:check
	cd ../admin-service && ./mvnw checkstyle:check

# ===== QA =====
qa-security:
	@bash scripts/security-scan.sh

qa-accessibility:
	cd ../e-commerce-frontend && npm run lighthouse

qa-performance:
	@bash scripts/run-load-tests.sh

# ===== SEED =====
seed:
	@bash scripts/seed-plane.sh
	@bash scripts/seed-bookstack.sh

# ===== CLEAN =====
clean:
	docker compose --profile full down -v --remove-orphans
	@echo "Cleaned all containers and volumes"

# ===== HELP =====
help:
	@echo "Available commands:"
	@echo "  make dev           - Start backend + infrastructure"
	@echo "  make dev-full      - Start everything"
	@echo "  make infra         - Start infrastructure only"
	@echo "  make sdlc          - Start SDLC tools (Plane + BookStack)"
	@echo "  make monitoring    - Start monitoring stack"
	@echo "  make qa            - Start QA tools"
	@echo "  make design        - Start design tools (Penpot)"
	@echo "  make build         - Build all services"
	@echo "  make test          - Run all tests"
	@echo "  make lint          - Run all linters"
	@echo "  make seed          - Populate SDLC tools"
	@echo "  make clean         - Stop and remove all containers"
```

### 9.2 Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
      - id: check-merge-conflict
      - id: no-commit-to-branch
        args: ['--branch', 'main']
```

### 9.3 EditorConfig

```ini
# .editorconfig
root = true

[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.{ts,tsx,js,jsx,json,yml,yaml}]
indent_size = 2

[*.md]
trim_trailing_whitespace = false

[*.{java,xml}]
indent_size = 4
```

---

## 10. QA Strategy

### 10.1 QA Pyramid

```
              ┌─────────┐
              │  E2E    │  Playwright — ~10%
              │  ~10%   │
            ┌─┴─────────┴─┐
            │ Integration  │  Testcontainers — ~30%
            │    ~30%      │
          ┌─┴─────────────┴─┐
          │     Unit         │  JUnit 5 + Mockito — ~60%
          │     ~60%         │
          └──────────────────┘
```

### 10.2 Unit Testing

| Service | Framework | Coverage Target |
|---------|-----------|-----------------|
| Auth Service | JUnit 5 + Mockito | 80%+ |
| Cart Service | JUnit 5 + Mockito | 80%+ |
| Product Service | JUnit 5 + Mockito | 80%+ |
| Admin Service | JUnit 5 + Mockito | 80%+ |
| API Gateway | JUnit 5 + WebTestClient | 80%+ |
| Order API | JUnit 5 + Mockito | 80%+ |
| Frontend | Vitest + React Testing Library | 70%+ |

### 10.3 Integration Testing (Testcontainers)

| Test Type | Tool | Scope |
|-----------|------|-------|
| API Integration | Testcontainers + MockMvc | Full request lifecycle |
| DB Integration | Testcontainers (PostgreSQL) | Schema + queries |
| Kafka Integration | Testcontainers (Kafka) | Event publish/consume |
| Cache Integration | Testcontainers (Redis) | Cache hit/miss |
| Security Integration | Spring Security Test | Auth + authorization |

### 10.4 E2E Testing (Playwright)

| Flow | Priority |
|------|----------|
| Login → Browse → Add to Cart → Checkout → Order Confirmation | Critical |
| Register → Login → Profile | High |
| Browse → Search → Filter → Product Detail | High |
| Admin Login → Dashboard → Manage Orders | Medium |

### 10.5 Performance Testing (k6)

| Scenario | Target | Duration |
|----------|--------|----------|
| Load test | 100 concurrent users | 5 min |
| Stress test | Ramp to 500 users | 10 min |
| API response time | p95 < 200ms | — |
| Lighthouse LCP | < 2.5s | — |

### 10.6 Security Testing

| Tool | Scope | Frequency |
|------|-------|-----------|
| OWASP ZAP | Vulnerability scan | Pre-deploy |
| Snyk | Dependency scanning | CI/CD (every PR) |
| Semgrep | SAST (static analysis) | CI/CD (every PR) |

### 10.7 Code Quality

| Tool | Scope | Enforcement |
|------|-------|-------------|
| Checkstyle | Java code style | CI/CD gate |
| SpotBugs | Bug detection | CI/CD gate |
| JaCoCo | Code coverage | CI/CD gate (80% min) |
| ESLint | TypeScript linting | CI/CD gate |
| Prettier | Code formatting | Pre-commit hook |

---

## 11. CI/CD Pipelines

### 11.1 Per-Service Pipeline

```yaml
# .github/workflows/ci.yml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'
      - run: ./mvnw checkstyle:check

  unit-tests:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'
      - run: ./mvnw test

  integration-tests:
    runs-on: ubuntu-latest
    needs: unit-tests
    services:
      postgres:
        image: pgvector/pg16
        env:
          POSTGRES_DB: test_db
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        ports: ['5432:5432']
      redis:
        image: redis:7-alpine
        ports: ['6379:6379']
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
      - run: ./mvnw verify -P integration

  docker-build:
    runs-on: ubuntu-latest
    needs: integration-tests
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - run: docker build -t ${{ github.repository }}:${{ github.sha }} .
      - run: echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
      - run: docker push ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:${{ github.sha }}
```

### 11.2 Frontend Pipeline

```yaml
name: Frontend CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm run lint

  unit-tests:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm run test -- --coverage

  e2e-tests:
    runs-on: ubuntu-latest
    needs: unit-tests
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npx playwright test
```

### 11.3 Security Pipeline

```yaml
name: Security Scan

on:
  pull_request:
    branches: [main, develop]
  schedule:
    - cron: '0 6 * * 1'  # Weekly Monday 6am

jobs:
  dependency-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'
      - run: ./mvnw dependency-check:check

  snyk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: snyk/actions/maven@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high
```

---

## 12. Git Branching Strategy

### 12.1 Branch Model

```
main (production)
│
└── develop (integration)
     │
     ├── feature/initial-setup
     ├── feature/{service-name}-{feature}
     ├── bugfix/{service-name}-{issue}
     └── release/v{version}
```

### 12.2 Branch Naming

```
feature/{service}-{description}
bugfix/{service}-{description}
hotfix/{description}
release/v{major}.{minor}.{patch}
```

### 12.3 Commit Message Format (Conventional Commits)

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`

**Examples:**
```
feat(auth): add JWT refresh token endpoint
fix(cart): resolve stock validation race condition
docs(api): update OpenAPI spec for product search
test(product): add integration tests for search filter
ci(github): add security scan workflow
```

---

## 13. Code Review Process

### 13.1 PR Template

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Feature
- [ ] Bug fix
- [ ] Refactor
- [ ] Documentation
- [ ] CI/CD
- [ ] Test

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing done

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated (if needed)
- [ ] No secrets or credentials in code
- [ ] No breaking API changes (or documented)
- [ ] Database migrations are backward-compatible
```

### 13.2 Code Owners

```
# CODEOWNERS
/api-gateway/       @sushant
/auth-service/      @sushant
/cart-service/      @sushant
/product-service/   @sushant
/admin-service/     @sushant
/e-commerce-frontend/ @sushant
/sdlc/              @sushant
```

---

## 14. Monitoring & Observability

### 14.1 Monitoring Stack

| Component | Image | Port | Purpose |
|-----------|-------|------|---------|
| Prometheus | `prom/prometheus` | 9090 | Metrics collection |
| Grafana | `grafana/grafana` | 3002 | Dashboards & visualization |
| Loki | `grafana/loki` | 3100 | Log aggregation |
| Promtail | `grafana/promtail` | — | Log shipping to Loki |
| Alertmanager | `prom/alertmanager` | 9093 | Alert routing |
| Jaeger | `jaegertracing/all-in-one` | 16686 | Distributed tracing |

### 14.2 Alert Rules

```yaml
groups:
  - name: ecommerce-alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_server_requests_seconds_count{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High 5xx error rate on {{ $labels.instance }}"

      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m])) > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High p95 latency on {{ $labels.instance }}"

      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"
```

### 14.3 Structured Logging

```json
{
  "timestamp": "2026-09-10T14:30:00Z",
  "level": "INFO",
  "service": "cart-service",
  "traceId": "abc-123",
  "spanId": "def-456",
  "message": "Cart item added",
  "userId": "789",
  "productId": "101",
  "quantity": 2,
  "duration": 45
}
```

---

## 15. Versioning & Release Management

### 15.1 Versioning Strategy

| Component | Strategy | Format |
|-----------|----------|--------|
| Services | Semantic Versioning | `v1.2.3` |
| API | URL versioning | `/api/v1/`, `/api/v2/` |
| Docker images | Git SHA + semver | `auth-service:abc1234` |
| Database | Sequential migrations | `V100__`, `V101__` |
| Kafka topics | Service prefix | `auth.user.registered` |

### 15.2 Release Process

```
1. Create release branch from develop
2. Bump version in all affected services
3. Update CHANGELOG.md
4. Create GitHub Release with tag
5. CI/CD builds and pushes Docker images
6. Deploy to staging
7. Smoke test
8. Deploy to production
9. Monitor
10. Merge release branch back to main + develop
```

---

## 16. Disaster Recovery

### 16.1 Backup Strategy

| Component | Method | Frequency | Retention |
|-----------|--------|-----------|-----------|
| PostgreSQL | `pg_dump` | Daily | 30 days |
| Redis | RDB snapshots | Every 6 hours | 7 days |
| Kafka | Topic retention | 7 days | Auto-delete |

### 16.2 RTO/RPO Targets

| Metric | Target |
|--------|--------|
| RTO (Recovery Time Objective) | 1 hour |
| RPO (Recovery Point Objective) | 24 hours |

---

## 17. Sprint Retrospectives

### 17.1 Template

```markdown
# Sprint {N} Retrospective — {Date}

## What went well? ✅
- ...

## What could be improved? ⚠️
- ...

## Action items
- [ ] ...

## Velocity
| Metric | Value |
|--------|-------|
| Planned points | X |
| Completed points | Y |
| Carry over | Z |
```

### 17.2 Sprint Schedule

| Sprint | Duration | Focus |
|--------|----------|-------|
| Sprint 0 | Week 1 | Foundation: setup, docs, design |
| Sprint 1 | Week 2 | Backend Core: Gateway, Auth, Cart, Product |
| Sprint 2 | Week 3 | Backend Extended: Admin, Order API, DevOps |
| Sprint 3 | Week 4 | Frontend + QA: All pages, testing, verification |

---

## 18. AI Documentation

### 18.1 AI Usage Log

| Date | Task | AI Tool | What AI Did | What I Changed |
|------|------|---------|-------------|----------------|
| 2026-09-10 | SDLC Planning | Claude | Generated full SDLC plan | Reviewed, adjusted scope |
| ... | ... | ... | ... | ... |

### 18.2 Review Policy

- All AI-generated code MUST be reviewed by a human
- AI suggestions are starting points, not final implementations
- Verify AI-generated tests actually test the right things
- Check for security issues in AI-generated code

---

## 19. SDLC Documentation Artifacts

### 19.1 Documentation Structure

```
sdlc/docs/
├── 01-project-charter.md
├── 02-business-requirements.md
├── 03-user-stories.md
├── 04-risk-register.md
├── 05-architecture-decisions.md
├── 06-system-design.md
├── 07-api-specs/
│   ├── auth-service.yaml
│   ├── cart-service.yaml
│   ├── product-service.yaml
│   ├── order-service.yaml
│   └── admin-service.yaml
├── 08-database-schema.sql
├── 09-design-specs.md
├── 10-test-plan.md
├── 11-developer-guide.md
├── 12-deployment-runbook.md
├── 13-service-communication.md
├── 14-cicd-pipeline.md
├── 15-monitoring-runbook.md
└── 16-retrospectives/
    ├── sprint-0.md
    ├── sprint-1.md
    ├── sprint-2.md
    └── sprint-3.md
```

---

## 20. Execution Phases

| Phase | What | Agents | Est. Effort |
|-------|------|--------|-------------|
| **0** | Project Setup | main, devops | 0.5 day |
| **1** | SDLC Documentation + Design | architect, ux-designer, docs | 1 day |
| **2** | API Gateway + Docker Compose | devops, backend | 0.5 day |
| **3** | Auth Service | backend, explore | 1 day |
| **4** | Cart Service | backend, explore | 1 day |
| **5** | Product Service | backend, explore | 1 day |
| **6** | Admin Service | backend, explore | 0.5 day |
| **7** | Order API Extension | backend, explore | 0.5 day |
| **8** | CI/CD Pipelines | devops | 0.5 day |
| **9** | Monitoring Setup | devops | 0.5 day |
| **10** | Seed Scripts | main, docs | 0.5 day |
| **11** | Frontend | frontend, ux-designer | 2 days |
| **12** | QA Hardening | qa, ux-designer | 1 day |
| **13** | Final Verification | main | 0.5 day |
| | **Total** | | **~11 days** |

---

## 21. Resource Summary

### 21.1 Docker Services by Profile

| Category | Services | RAM |
|----------|----------|-----|
| Backend (7) | Gateway + 5 services + Frontend | 3.5GB |
| Infrastructure (4) | PostgreSQL + Redis + Kafka + Jaeger | 1.5GB |
| Monitoring (5) | Prometheus + Grafana + Loki + Promtail + Alertmanager | 1.5GB |
| SDLC Tools (6) | Plane (3) + BookStack (2) + Plane Redis | 3.0GB |
| Design (5) | Penpot (5) | 2.0GB |
| **Total** | **23 services** | **~9.5GB** (full) |

### 21.2 Port Map

| Service | Port |
|---------|------|
| Frontend | 3000 |
| Plane Frontend | 3001 |
| Grafana | 3002 |
| API Gateway | 8080 |
| Auth Service | 8081 |
| Cart Service | 8082 |
| Product Service | 8083 |
| Order API | 8084 |
| Admin Service | 8085 |
| Plane Backend | 8000 |
| BookStack | 6000 |
| PostgreSQL | 5432 |
| Redis | 6379 |
| Kafka | 9092 |
| Jaeger | 16686 |
| Prometheus | 9090 |
| SonarQube | 9000 |
| Penpot | 9001 |
| Loki | 3100 |
| Alertmanager | 9093 |

---

## 22. Final Checklist

### 22.1 SDLC Process

```
□ Project Charter
□ Business Requirements Document
□ User Stories with Acceptance Criteria
□ Risk Register
□ Architecture Decision Records (10+)
□ System Design Document
□ API Specifications (OpenAPI 3.0)
□ Database Schema (Liquibase)
□ Design Tokens
□ Wireframes (14 screens)
□ Responsive Breakpoints
□ Accessibility Specs
□ Test Plan
□ Developer Guide
□ Deployment Runbook
□ Service Communication Docs
□ CI/CD Documentation
□ Monitoring Runbook
□ Sprint Retrospectives (4)
□ AI Usage Documentation
□ README per repo
```

### 22.2 Implementation

```
□ API Gateway (routes, JWT filter, rate limiting, CORS)
□ Auth Service (register, login, refresh, profile)
□ Cart Service (CRUD, stock validation, totals)
□ Product Service (CRUD, search, filter, pagination)
□ Order API (Kafka integration)
□ Admin Service (dashboard, order/user management)
□ Frontend (14 pages, responsive, accessible)
□ Docker Compose (23 services, 6 profiles)
□ Makefile (build, test, lint, seed, clean)
□ Pre-commit hooks
□ EditorConfig
```

### 22.3 Testing

```
□ Unit tests (80%+ coverage per service)
□ Integration tests (Testcontainers)
□ Contract tests (between services)
□ E2E tests (Playwright — critical flows)
□ Performance tests (k6 — load, stress)
□ Security tests (OWASP ZAP, Snyk, Semgrep)
□ Accessibility tests (axe-core, Lighthouse)
□ Code quality (Checkstyle, ESLint, JaCoCo)
```

### 22.4 DevOps

```
□ CI/CD pipelines (per repo)
□ Branch protection rules
□ PR templates
□ Code review checklist
□ Docker health checks
□ Structured logging
□ Correlation IDs
□ Prometheus metrics
□ Grafana dashboards
□ Alert rules
□ Database backups
□ Rollback procedure
```

### 22.5 Quality Gates

```
□ Code coverage >= 80%
□ Lighthouse score >= 90
□ 0 high/critical security vulnerabilities
□ 0 accessibility violations (WCAG 2.1 AA)
□ API response time < 200ms (p95)
□ All CI checks passing
□ Documentation complete
```

---

## 23. Fixes Applied

| # | Fix | Status |
|---|-----|--------|
| 1 | Liquibase for all services (not Flyway) | ✅ Applied |
| 2 | Service-to-service auth (internal API keys) | ✅ Applied |
| 3 | PostgreSQL max_connections=200 | ✅ Applied |
| 4 | Kafka consumer idempotency | ✅ Applied |
| 5 | Frontend API client with token refresh | ✅ Applied |
| 6 | Environment configuration (Spring profiles + .env) | ✅ Applied |
| 7 | CORS configurable per environment | ✅ Applied |
| 8 | Rate limiting with response headers | ✅ Applied |
| 9 | Request/response logging with PII masking | ✅ Applied |
| 10 | Graceful shutdown (all services) | ✅ Applied |
| 11 | Package naming standardized (`com.ecommerce.*`) | ✅ Applied |
| 12 | Health check aggregation script | ✅ Applied |
| 13 | Kafka topic configuration | ✅ Applied |
| 14 | Admin startup sync | ✅ Applied |
| 15 | SSL/TLS documentation | ✅ Applied |
| 16 | DR testing schedule | ✅ Applied |
| 17 | Solo branch protection | ✅ Applied |

---

## 24. Agent Structure

### 24.1 Available Agents (9 Total)

| # | Agent | Type | Purpose |
|---|-------|------|---------|
| 1 | **main** | Orchestrator | Coordinates all agents, final decisions |
| 2 | **explore** | Research | Codebase exploration, pattern discovery |
| 3 | **architect** | Design | System design, ADRs, API contracts |
| 4 | **ux-designer** | Design | Design tokens, wireframes, specs |
| 5 | **backend** | Implementation | Spring Boot services |
| 6 | **frontend** | Implementation | Next.js pages, components |
| 7 | **devops** | Infrastructure | Docker, CI/CD, monitoring |
| 8 | **qa** | Quality | Testing, security, accessibility |
| 9 | **docs** | Documentation | READMEs, guides, runbooks |

### 24.2 Agent Task Routing

| Task Type | Agent |
|-----------|-------|
| Explore existing code | explore |
| Design system architecture | architect |
| Write API contracts | architect |
| Design database schema | architect |
| Write ADRs | architect |
| Create Spring Boot service | backend |
| Write JPA entities | backend |
| Write REST controllers | backend |
| Write unit tests | backend or qa |
| Create Next.js page | frontend |
| Write React components | frontend |
| Write E2E tests | qa |
| Create Dockerfile | devops |
| Write CI/CD pipeline | devops |
| Configure monitoring | devops |
| Write README | docs |
| Write deployment runbook | docs |
| Security scanning | qa |
| Create design tokens | ux-designer |
| Create wireframes | ux-designer |

---

## 25. Skills Structure

### 25.1 Custom Skills (9 Skills)

| Skill | Purpose | When Created |
|-------|---------|--------------|
| `spring-boot-service` | Scaffold a new Spring Boot service | Phase 3 |
| `nextjs-page` | Create a Next.js page with components | Phase 11 |
| `docker-compose-service` | Add a service to Docker Compose | Phase 8 |
| `github-actions-ci` | Create CI/CD workflow for a repo | Phase 8 |
| `liquibase-migration` | Create Liquibase changelog for a schema | Phase 3 |
| `kafka-consumer` | Create a Kafka consumer with idempotency | Phase 7 |
| `api-contract` | Create OpenAPI 3.0 spec for a service | Phase 1 |
| `playwright-e2e` | Create Playwright E2E test | Phase 12 |
| `integration-test` | Create Testcontainers integration test | Phase 3 |

### 25.2 Skill Usage by Phase

| Phase | Skill Used |
|-------|-----------|
| 1 | `api-contract` |
| 3 | `spring-boot-service`, `liquibase-migration` |
| 4 | `spring-boot-service`, `liquibase-migration`, `kafka-consumer` |
| 5 | `spring-boot-service`, `liquibase-migration` |
| 6 | `spring-boot-service`, `liquibase-migration`, `kafka-consumer` |
| 7 | `kafka-consumer` |
| 8 | `docker-compose-service`, `github-actions-ci` |
| 11 | `nextjs-page` |
| 12 | `playwright-e2e`, `integration-test` |

---

## 26. GitHub Strategy

### 26.1 Repository Creation

```bash
# Create all repos via gh CLI
gh repo create sdlc --public --description "E-Commerce SDLC: Docker Compose, docs, scripts" --clone
gh repo create api-gateway --public --description "Spring Cloud Gateway" --clone
gh repo create auth-service --public --description "Authentication & JWT service" --clone
gh repo create cart-service --public --description "Shopping cart service" --clone
gh repo create product-service --public --description "Product catalog & search" --clone
gh repo create admin-service --public --description "Admin dashboard service" --clone
gh repo create e-commerce-frontend --public --description "Next.js 14 frontend" --clone
```

### 26.2 PR Strategy (Feature PRs)

| Phase | PR per Repo | Branch | Title |
|-------|-------------|--------|-------|
| 1 | `sdlc` | `feature/sdlc-docs` | "Add SDLC documentation" |
| 2 | `api-gateway` | `feature/initial-setup` | "Add API Gateway with JWT, rate limiting" |
| 3 | `auth-service` | `feature/initial-setup` | "Add Auth Service: register, login, JWT" |
| 4 | `cart-service` | `feature/initial-setup` | "Add Cart Service: CRUD, stock validation" |
| 5 | `product-service` | `feature/initial-setup` | "Add Product Service: CRUD, search, filter" |
| 6 | `admin-service` | `feature/initial-setup` | "Add Admin Service: dashboard, Kafka" |
| 7 | `order-management-api` | `feature/kafka-integration` | "Add Kafka consumer and producers" |
| 8 | `sdlc` | `feature/docker-compose` | "Add Docker Compose with all services" |
| 11 | `e-commerce-frontend` | `feature/initial-setup` | "Add Next.js frontend with all pages" |

### 26.3 Git Commit Convention

```
<type>(<scope>): <description>
```

| Type | Scope | Example |
|------|-------|---------|
| `feat` | service | `feat(auth): add JWT login endpoint` |
| `fix` | service | `fix(cart): resolve stock validation race condition` |
| `docs` | all | `docs(api): update OpenAPI spec` |
| `test` | service | `test(product): add integration tests` |
| `ci` | repo | `ci(actions): add security scan workflow` |
| `chore` | repo | `chore(deps): update Spring Boot to 3.4.1` |

### 26.4 Branch Protection

```bash
# Apply branch protection via gh CLI
gh api repos/{owner}/{repo}/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["lint","unit-tests","integration-tests"]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"required_approving_review_count":0,"dismiss_stale_reviews":true}' \
  --field restrictions=null
```

---

## Summary

| Metric | Value |
|--------|-------|
| **Total Repos** | 8 |
| **Total PRs** | ~12 |
| **Total Agents** | 9 (2 built-in + 7 custom) |
| **Total Skills** | 9 |
| **Total Services** | 23 Docker containers |
| **Total Sprints** | 4 (1 week each) |
| **Total Pages** | 14 frontend pages |
| **Total Components** | 18 shadcn/ui components |
| **Total Docs** | 15 SDLC documents |
| **Total RAM** | ~9.5GB (full environment) |
| **Total Execution Time** | ~11 days |
| **Total Lines of Code** | ~14,200 |

---

*Document Version: 2.0*
*Last Updated: September 2026*
*Author: Sushant*
