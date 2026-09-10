# System Design

> Authoritative source: [SDLC-PLAN-v2.0.md](../planning/SDLC-PLAN-v2.0.md)
> Architecture decisions: [05-architecture-decisions.md](./05-architecture-decisions.md)
> Service contracts: [13-service-communication.md](./13-service-communication.md)

---

## 1. System Context Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          USERS                                         │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│   │ Customer │  │  Admin   │  │  Guest   │  │  Bot/    │              │
│   │ (Logged) │  │ (Admin)  │  │ (Browse) │  │  Crawler │              │
│   └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘              │
│        │              │              │              │                    │
└────────┼──────────────┼──────────────┼──────────────┼────────────────────┘
         │              │              │              │
         ▼              ▼              ▼              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     Next.js Frontend (:3000)                            │
│  lib/api.ts — JWT token management + automatic refresh                  │
│  shadcn/ui components — 18 component library                            │
│  Responsive: 375px mobile → 1536px wide                                 │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ HTTPS (port 3000→8080)
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                   API Gateway (:8080)                                    │
│                   Spring Cloud Gateway                                  │
│  ┌─────────────┐ ┌──────────────┐ ┌──────────┐ ┌───────────────────┐  │
│  │ JWT Filter  │ │ Rate Limiter │ │ CORS     │ │ Request Logger    │  │
│  │ (validate)  │ │ (per-route)  │ │ (config) │ │ (PII-masked)     │  │
│  └─────────────┘ └──────────────┘ └──────────┘ └───────────────────┘  │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ Internal Docker network
         ┌───────────┬───────────┼───────────┬───────────┐
         ▼           ▼           ▼           ▼           ▼
    ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
    │  Auth   │ │  Cart   │ │ Product │ │ Order   │ │ Admin   │
    │ Service │ │ Service │ │ Service │ │ API     │ │ Service │
    │ :8081   │ │ :8082   │ │ :8083   │ │ :8084   │ │ :8085   │
    └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘
         │           │           │           │           │
         └───────────┴─────┬─────┴───────────┴───────────┘
                           │
         ┌─────────────────┼─────────────────────┐
         ▼                 ▼                     ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐
│ PostgreSQL 16│  │    Redis 7   │  │    Kafka 3.7.0       │
│ :5432        │  │    :6379     │  │    (KRaft) :9092     │
│ 5 schemas    │  │  cache+locks │  │    8 topics          │
└──────────────┘  └──────────────┘  └──────────────────────┘
```

---

## 2. Container Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                        Docker Host                                    │
│                                                                       │
│  ┌─── CORE APP (profile: backend) ─────────────────────────────────┐  │
│  │                                                                  │  │
│  │  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐        │  │
│  │  │ api-gateway  │   │ auth-service │   │ cart-service │        │  │
│  │  │ Spring Cloud │   │ Spring Boot  │   │ Spring Boot  │        │  │
│  │  │ Gateway      │   │ 3.4 + JPA    │   │ 3.4 + JPA    │        │  │
│  │  │ :8080        │   │ :8081        │   │ :8082        │        │  │
│  │  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘        │  │
│  │         │                  │                   │                 │  │
│  │  ┌──────┴───────┐   ┌─────┴────────┐   ┌──────┴───────┐        │  │
│  │  │product-svc   │   │ order-api    │   │ admin-svc   │        │  │
│  │  │ Spring Boot  │   │ Spring Boot  │   │ Spring Boot │        │  │
│  │  │ 3.4 + JPA    │   │ 3.4 + JPA    │   │ 3.4 + JPA   │        │  │
│  │  │ :8083        │   │ :8084        │   │ :8085       │        │  │
│  │  └──────────────┘   └──────────────┘   └─────────────┘        │  │
│  │                                                                  │  │
│  │  ┌──────────────────────────┐                                    │  │
│  │  │ e-commerce-frontend      │                                    │  │
│  │  │ Next.js 14 + TypeScript  │                                    │  │
│  │  │ :3000                    │                                    │  │
│  │  └──────────────────────────┘                                    │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌─── INFRASTRUCTURE ─────────────────────────────────────────────┐   │
│  │  PostgreSQL 16 (pgvector)  │  Redis 7  │  Kafka 3.7  │ Jaeger │   │
│  │  :5432                      │  :6379    │  :9092      │ :16686 │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌─── MONITORING (profile: monitoring) ───────────────────────────┐   │
│  │  Prometheus :9090 │ Grafana :3002 │ Loki :3100 │ Alertmanager  │   │
│  │                    │               │ Promtail   │ :9093         │   │
│  └────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 3. Component Boundaries

### 3.1 Service Responsibilities

| Service | Owns Data | Publishes Events | Consumes Events | Sync Dependencies |
|---------|-----------|------------------|-----------------|-------------------|
| auth-service | `auth` schema | `auth.user.registered`, `auth.user.updated` | — | — |
| cart-service | `cart` schema | `cart.checkout.initiated` | `product.catalog.*`, `order.placed` | Product Service (REST) |
| product-service | `product` schema | `product.catalog.created/updated/deleted` | — | — |
| order-management-api | `orders` schema | `order.placed`, `order.status.changed` | `cart.checkout.initiated` | — |
| admin-service | `admin` schema | — | `auth.user.*`, `order.placed`, `order.status.changed` | — |

### 3.2 Data Ownership Rules

1. No service reads another service's schema directly.
2. All cross-service data access goes through REST APIs or Kafka events.
3. Cart Service is the only service that makes synchronous REST calls (to Product Service).
4. Order Management API is the only service that consumes `cart.checkout.initiated`.

---

## 4. Deployment Topology

```
┌─────────────────────────────────────────────────────┐
│                   Production Host                     │
│                                                       │
│  ┌───────────────────────────────────────────────┐   │
│  │  Docker Compose (23 containers, 6 profiles)   │   │
│  │                                                 │   │
│  │  RAM Budget:                                    │   │
│  │  ├── Backend apps:    ~3.5 GB                   │   │
│  │  ├── Infrastructure:  ~1.5 GB                   │   │
│  │  ├── Monitoring:      ~1.5 GB                   │   │
│  │  ├── SDLC Tools:      ~3.0 GB                   │   │
│  │  └── Design Tools:    ~2.0 GB                   │   │
│  │  ─────────────────────────────                  │   │
│  │  Total:               ~9.5 GB (full profile)    │   │
│  └───────────────────────────────────────────────┘   │
│                                                       │
│  Port Map:                                            │
│  ┌────────────┬──────┐  ┌────────────┬──────┐        │
│  │ Frontend   │ 3000 │  │ API Gateway│ 8080 │        │
│  │ Auth       │ 8081 │  │ Cart       │ 8082 │        │
│  │ Product    │ 8083 │  │ Order API  │ 8084 │        │
│  │ Admin      │ 8085 │  │ PostgreSQL │ 5432 │        │
│  │ Redis      │ 6379 │  │ Kafka      │ 9092 │        │
│  │ Jaeger     │16686 │  │ Prometheus │ 9090 │        │
│  │ Grafana    │ 3002 │  │ Loki       │ 3100 │        │
│  └────────────┴──────┘  └────────────┴──────┘        │
└─────────────────────────────────────────────────────┘
```

### Profile Activation

| Command | Profile | Containers |
|---------|---------|------------|
| `make dev` | `backend` | App (7) + Infra (4) = 11 |
| `make monitoring` | `monitoring` | Prometheus, Grafana, Loki, Promtail, Alertmanager = 5 |
| `make dev-full` | `full` | All 23 containers |

---

## 5. Request Lifecycle — Buy Flow

**Flow:** Browse → Add to Cart → Checkout → Order Confirmation

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│ Browser │     │ Gateway │     │  Cart   │     │ Product │
│ (Next.js)│    │ :8080   │     │ :8082   │     │ :8083   │
└────┬────┘     └────┬────┘     └────┬────┘     └────┬────┘
     │               │               │               │
     │ 1. GET /api/v1/products      │               │
     │──────────────>│               │               │
     │               │──────────────────────────────>│
     │               │               │   2. Return   │
     │               │<──────────────────────────────│
     │  3. Products  │               │               │
     │<──────────────│               │               │
     │               │               │               │
     │ 4. POST /api/v1/cart/items   │               │
     │ {productId:1,qty:2}          │               │
     │──────────────>│               │               │
     │               │──────────────────────────────>│
     │               │               │  5. Validate  │
     │               │               │  stock+price  │
     │               │<──────────────────────────────│
     │               │               │  6. Stock OK  │
     │               │──────────────>│               │
     │               │  7. Cart      │               │
     │<──────────────│  {items,totals}               │
     │               │               │               │
     │ 8. POST /api/v1/cart (checkout)               │
     │ {shippingAddress}             │               │
     │──────────────>│               │               │
     │               │──────────────>│               │
     │               │  9. Create    │               │
     │               │  checkout     │               │
     │               │  event        │               │
     │               │<──────────────│               │
     │  10. 202 Accepted             │               │
     │<──────────────│               │               │
     │               │               │               │

     ┌─────────┐     ┌─────────┐
     │  Cart   │     │  Kafka  │
     │ :8082   │     │ :9092   │
     └────┬────┘     └────┬────┘
          │               │
          │ 11. Publish   │
          │ cart.checkout │
          │ .initiated    │
          │──────────────>│
          │               │
          ┌─────────┐     │
          │ Order   │     │
          │ API     │     │
          │ :8084   │     │
          └────┬────┘     │
               │          │
               │ 12. Consume │
               │ cart.checkout│
               │ .initiated   │
               │<─────────────│
               │               │
               │ 13. Create   │
               │ order in DB  │
               │ (idempotent) │
               │               │
               │ 14. Publish  │
               │ order.placed │
               │──────────────>│
               │               │
               ┌─────────┐     │
               │ Admin   │     │
               │ :8085   │     │
               └────┬────┘     │
                    │          │
                    │ 15. Consume │
                    │ order.placed│
                    │<─────────────│
                    │               │
                    │ 16. Update   │
                    │ dashboard    │
                    │ snapshot     │
```

**Step-by-step:**

| Step | Service | Action | Mechanism |
|------|---------|--------|-----------|
| 1 | Gateway | Route `GET /products` to Product Service | REST proxy |
| 2 | Product Service | Query products from `product` schema | SQL |
| 3 | Gateway | Return products to browser | REST response |
| 4 | Gateway | Route `POST /cart/items` to Cart Service | REST proxy |
| 5-6 | Cart Service | Call Product Service for stock/price validation | REST (internal API key) |
| 7 | Cart Service | Save cart item, recalculate totals | SQL (transactional) |
| 8 | Gateway | Route checkout to Cart Service | REST proxy |
| 9-10 | Cart Service | Create `cart.checkout.initiated` event | Kafka producer |
| 11 | Cart Service | Publish event to Kafka | Kafka producer |
| 12 | Order API | Poll and consume checkout event | Kafka consumer |
| 13 | Order API | Create order in `orders` schema (idempotent) | SQL + idempotency_keys |
| 14 | Order API | Publish `order.placed` event | Kafka producer |
| 15-16 | Admin Service | Consume and update dashboard snapshot | Kafka consumer + SQL |

---

## 6. Request Lifecycle — Login Flow

**Flow:** User enters credentials → JWT issued → Authenticated requests

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│ Browser │     │ Gateway │     │  Auth   │     │  Kafka  │
│         │     │ :8080   │     │ :8081   │     │ :9092   │
└────┬────┘     └────┬────┘     └────┬────┘     └────┬────┘
     │               │               │               │
     │ 1. POST /api/v1/auth/login   │               │
     │ {email, password}            │               │
     │──────────────>│               │               │
     │               │──────────────>│               │
     │               │  2. Route     │               │
     │               │  (no JWT      │               │
     │               │   required)   │               │
     │               │               │               │
     │               │               │ 3. Query      │
     │               │               │ auth.users    │
     │               │               │ by email      │
     │               │               │               │
     │               │               │ 4. BCrypt     │
     │               │               │ verify        │
     │               │               │               │
     │               │               │ 5. Generate   │
     │               │               │ access JWT    │
     │               │               │ (15min)       │
     │               │               │               │
     │               │               │ 6. Generate   │
     │               │               │ refresh token │
     │               │               │ (7 days, UUID)│
     │               │               │               │
     │               │               │ 7. Store in   │
     │               │               │ refresh_tokens│
     │               │               │               │
     │               │               │ 8. Publish    │
     │               │               │ auth.user.    │
     │               │               │ registered    │
     │               │               │──────────────>│
     │               │               │               │
     │  9. {accessToken, refreshToken, user}        │
     │<──────────────│<──────────────│               │
     │               │               │               │
     │ 10. Store tokens in localStorage             │
     │               │               │               │
     │ ──── Authenticated Request ────              │
     │               │               │               │
     │ 11. GET /api/v1/cart        │               │
     │ Authorization: Bearer <JWT> │               │
     │──────────────>│               │               │
     │               │               │               │
     │               │ 12. JWT Filter:               │
     │               │ validate     │               │
     │               │ signature +  │               │
     │               │ expiry       │               │
     │               │               │               │
     │               │──────────────>│               │
     │               │  13. Route   │               │
     │               │  (JWT valid) │               │
     │               │               │               │
     │  14. Cart data               │               │
     │<──────────────│<──────────────│               │
     │               │               │               │
```

**Token Refresh Flow:**

| Step | Service | Action |
|------|---------|--------|
| 1 | Browser | Detect 401 or approaching token expiry |
| 2 | Browser | `POST /api/v1/auth/refresh` with `{refreshToken}` |
| 3 | Auth Service | Validate refresh token against `auth.refresh_tokens` |
| 4 | Auth Service | Invalidate old refresh token, issue new pair |
| 5 | Browser | Store new access token, retry original request |

---

## 7. Event Flow Diagram

```
                    ┌─────────────────────────────────────────────┐
                    │            KAFKA TOPICS (8)                  │
                    └─────────────────────────────────────────────┘

┌──────────────┐
│ auth-service │
│   :8081      │
└──┬───────┬───┘
   │       │
   │  auth.user.registered
   │  auth.user.updated
   │       │
   │       ▼
   │  ┌──────────────┐
   │  │ admin-service│
   │  │   :8085      │
   │  └──────────────┘
   │
   │  (no Kafka consumer)
   │
   │
┌──────────────┐    ┌─────────────────────────────────────────────┐
│ product-svc  │    │                                             │
│   :8083      │    │  product.catalog.created                     │
│              │    │  product.catalog.updated                     │
│              │────┤  product.catalog.deleted                     │
│              │    │                                             │
└──────────────┘    └──────────────────┬──────────────────────────┘
                                       │
                                       ▼
                              ┌──────────────┐
                              │ cart-service │
                              │   :8082      │
                              └──────┬───────┘
                                     │
                                     │  cart.checkout.initiated
                                     │
                                     ▼
                              ┌──────────────────┐
                              │ order-management │
                              │ api :8084        │
                              └──────┬───────────┘
                                     │
                         ┌───────────┴───────────┐
                         │                       │
                         │  order.placed         │
                         │  order.status.changed │
                         │                       │
                         ▼                       ▼
                ┌──────────────┐        ┌──────────────┐
                │ admin-service│        │ cart-service │
                │   :8085      │        │   :8082      │
                └──────────────┘        └──────────────┘
```

### Event Publishing Summary

| Topic | Publisher | Subscribers | Trigger |
|-------|-----------|-------------|---------|
| `auth.user.registered` | auth-service | admin-service | Successful registration |
| `auth.user.updated` | auth-service | admin-service | Profile update |
| `cart.checkout.initiated` | cart-service | order-api | Cart checkout confirmed |
| `product.catalog.created` | product-service | cart-service | New product added |
| `product.catalog.updated` | product-service | cart-service | Product edited |
| `product.catalog.deleted` | product-service | cart-service | Product removed |
| `order.placed` | order-api | admin-service, cart-service | Order created from checkout |
| `order.status.changed` | order-api | admin-service | Order status transition |

---

## 8. Error Handling + Idempotency Design

### 8.1 Error Response Envelope (RFC 7807-style)

All services return errors in a consistent envelope format (plan §3):

```json
{
  "type": "https://api.ecommerce.com/errors/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "Email format is invalid",
  "instance": "/api/v1/auth/register",
  "traceId": "abc-123",
  "timestamp": "2026-09-10T14:30:00Z",
  "errors": [
    {
      "field": "email",
      "message": "Must be a valid email address",
      "rejectedValue": "not-an-email"
    }
  ]
}
```

### 8.2 Retry + Backoff Strategy

| Scenario | Retry Policy | Max Retries | Backoff |
|----------|-------------|-------------|---------|
| REST call: Cart→Product | Exponential + jitter | 3 | 1s, 2s, 4s |
| Kafka consumer failure | Kafka built-in | Unlimited | `retry.backoff.ms` = 1000 |
| Token refresh | Linear | 1 | 0s (immediate retry) |
| Gateway → downstream | No retry | 0 | Circuit breaker fallback |

### 8.3 Idempotency Design

**Kafka Consumers:**
- Every event carries `eventId` (UUID).
- Consumer checks `idempotency_keys` table before processing.
- Dedup check + business logic + key insert in a single DB transaction.

**REST Endpoints:**
- Idempotency keys for non-GET requests are optional (client can send `X-Idempotency-Key` header).
- POST `/api/v1/orders` uses `cart.checkout.initiated` `eventId` as natural idempotency key.

---

## 9. Rate Limiting Design

Gateway-level rate limiting (plan §6.3):

| Endpoint | Limit (per minute) | Rationale |
|----------|-------------------|-----------|
| `/api/v1/auth/login` | 10 | Prevent brute-force |
| `/api/v1/auth/register` | 5 | Prevent spam accounts |
| `/api/v1/products` (GET) | 200 | Public browsing |
| `/api/v1/cart/**` | 50 | Authenticated users |
| `/api/v1/orders/**` | 30 | Order operations |
| Default | 100 | Catch-all |

Rate limit response:
```json
{
  "type": "https://api.ecommerce.com/errors/rate-limited",
  "title": "Too Many Requests",
  "status": 429,
  "detail": "Rate limit exceeded. Retry after 30s.",
  "retryAfter": 30
}
```

Response headers: `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

---

## 10. CORS Design

Configurable per environment (plan §6.2):

```yaml
app:
  cors:
    allowed-origins: ${CORS_ALLOWED_ORIGINS:http://localhost:3000}
    allowed-methods: GET,POST,PUT,DELETE,PATCH,OPTIONS
    allowed-headers: "*"
    allow-credentials: true
    max-age: 3600
```

- **Development:** `http://localhost:3000`
- **Production:** Configured via environment variable (never `*` with credentials).

---

## 11. Security Design

### 11.1 JWT Validation at Gateway

```
Request → Gateway JWT Filter
  ├── No Authorization header → 401 (for protected routes)
  ├── Malformed JWT → 401
  ├── Expired JWT → 401
  ├── Invalid signature → 401
  └── Valid JWT → Extract claims, forward to downstream service
       ├── X-User-Id header
       ├── X-User-Email header
       └── X-User-Role header
```

### 11.2 Internal API Key Checks

Inter-service REST calls include:
```
X-Internal-API-Key: ${INTERNAL_API_KEY}
```

Validation:
1. Gateway strips `X-Internal-API-Key` from external requests (prevents spoofing).
2. Receiving service validates key against `INTERNAL_API_KEY` env var.
3. Comparison uses `MessageDigest.isEqual()` for constant-time check (prevents timing attacks).

### 11.3 Password Hashing

- Algorithm: **BCrypt** (Spring Security `BCryptPasswordEncoder`)
- Strength factor: 12 (default)
- Stored in `auth.users.password_hash` — never logged, never returned in API responses.

### 11.4 PII Masking

Request/response logging masks sensitive fields (plan fix #9):
```
Before: {"email": "user@example.com", "password": "secret123"}
After:  {"email": "u***@***.com", "password": "[MASKED]"}
```

Fields masked: `password`, `password_hash`, `token`, `creditCard`, `ssn`.

---

## 12. Resilience — Resilience4j Patterns

### 12.1 Circuit Breaker: Cart → Product Service

| Config | Value |
|--------|-------|
| Failure rate threshold | 50% |
| Slow call rate threshold | 80% |
| Slow call duration threshold | 2s |
| Sliding window size | 10 calls |
| Minimum calls | 5 |
| Wait duration in open state | 30s |
| Permitted calls in half-open | 3 |

**Fallback behavior:** When circuit is open, Cart Service returns cached product data from Redis (if available) or returns a generic error to the user.

### 12.2 Retry: Product Service Lookups

| Config | Value |
|--------|-------|
| Max attempts | 3 |
| Wait duration | 1s, 2s, 4s (exponential) |
| Retry exceptions | `IOException`, `5xx` responses |
| Ignore exceptions | `4xx` client errors |

### 12.3 Bulkhead: Kafka Consumers

| Config | Value |
|--------|-------|
| Max concurrent calls | 5 (per consumer instance) |
| Max wait duration | 0s (fail immediately) |

---

## Cross-Reference

| Topic | Related Plan Sections | Related Docs |
|-------|----------------------|--------------|
| Architecture | §1.1, §1.2, §2 | [ADR-001](./05-architecture-decisions.md#adr-001-microservices-over-monolith) |
| Database | §4.1, §4.3 | [ADR-002](./05-architecture-decisions.md#adr-002-single-postgres-with-schema-per-service) |
| Kafka Events | §5.1, §5.2, §5.3 | [Service Communication](./13-service-communication.md) |
| Gateway | §6.1, §6.2, §6.3 | [ADR-009](./05-architecture-decisions.md#adr-009-spring-cloud-gateway-no-eureka) |
| Monitoring | §14.1, §14.2, §14.3 | [ADR-013](./05-architecture-decisions.md#adr-013-prometheus--grafana--loki--jaeger-observability-stack) |
| Docker | §8.1, §8.2 | — |
