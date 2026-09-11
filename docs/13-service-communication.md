# Service Communication

> Authoritative source: [SDLC-PLAN-v2.0.md](../planning/SDLC-PLAN-v2.0.md)
> Architecture decisions: [05-architecture-decisions.md](./05-architecture-decisions.md)
> System design: [06-system-design.md](./06-system-design.md)

---

## 1. REST Contracts — Synchronous Inter-Service Calls

All inter-service REST calls use `X-Internal-API-Key` header for authentication (see [§4](#4-internal-api-key-header-spec)).

| # | From Service | To Service | Endpoint | Method | Purpose | Timeout | Fallback |
|---|-------------|-----------|----------|--------|---------|---------|----------|
| 1 | cart-service | product-service | `/api/v1/products/{id}` | GET | Validate product exists + get current price + check stock | 3s | Return cached price from Redis; if cache miss, return 409 with message "Product Service unavailable" |
| 2 | cart-service | product-service | `/api/v1/products?ids={id1},{id2}` | GET | Bulk price/stock validation for cart items | 5s | Return cached prices; if cache miss, return 409 |
| 3 | cart-service | product-service | `/api/v1/products/{id}/stock` | GET | Check stock availability for specific quantity | 3s | Return `{available: false, reason: "Unable to verify stock"}` |

### Notes

- **Cart → Product is the only synchronous inter-service REST dependency** (plan §5.1 — all other cross-service communication is Kafka-based).
- All three endpoints are protected with `X-Internal-API-Key` header.
- Resilience4j circuit breaker wraps all outbound calls (see [05-architecture-decisions.md#adr-016](./05-architecture-decisions.md#adr-016-resilience4j-for-service-resilience)).
- Gateway-to-service calls are transparent HTTP proxies, not counted as inter-service contracts.

---

## 2. REST Contracts — External (Client-Facing via Gateway)

These are the public API contracts as seen by the frontend. All routed through API Gateway (`:8080`).

### 2.1 Auth Service (via Gateway)

| Method | Endpoint | Request Body | Response | Auth Required |
|--------|----------|-------------|----------|---------------|
| POST | `/api/v1/auth/register` | `{email, password, fullName, phoneNumber}` | `{id, email, fullName}` | No |
| POST | `/api/v1/auth/login` | `{email, password}` | `{accessToken, refreshToken, user}` | No |
| POST | `/api/v1/auth/refresh` | `{refreshToken}` | `{accessToken}` | No |
| GET | `/api/v1/auth/profile` | — | `{id, email, fullName, phoneNumber}` | JWT |
| PUT | `/api/v1/auth/profile` | `{fullName, phoneNumber}` | `{id, email, fullName}` | JWT |
| POST | `/api/v1/auth/logout` | — | 204 No Content | JWT |

### 2.2 Cart Service (via Gateway)

| Method | Endpoint | Request Body | Response | Auth Required |
|--------|----------|-------------|----------|---------------|
| GET | `/api/v1/cart` | — | `{id, items[], subtotal, tax, total}` | JWT |
| POST | `/api/v1/cart/items` | `{productId, quantity}` | `{id, items[], subtotal, total}` | JWT |
| PUT | `/api/v1/cart/items/{itemId}` | `{quantity}` | `{id, items[], subtotal, total}` | JWT |
| DELETE | `/api/v1/cart/items/{itemId}` | — | `{id, items[], subtotal, total}` | JWT |
| DELETE | `/api/v1/cart` | — | 204 No Content | JWT |

### 2.3 Product Service (via Gateway)

| Method | Endpoint | Query Params | Response | Auth Required |
|--------|----------|-------------|----------|---------------|
| GET | `/api/v1/products` | `search, category, minPrice, maxPrice, sort, page, size` | `{content[], totalElements, totalPages}` | No |
| GET | `/api/v1/products/{id}` | — | `{id, name, description, price, stockQuantity, categories[]}` | No |
| POST | `/api/v1/products` | — | `{id, name, ...}` | JWT |
| PUT | `/api/v1/products/{id}` | — | `{id, name, ...}` | JWT |
| DELETE | `/api/v1/products/{id}` | — | 204 No Content | JWT |
| GET | `/api/v1/categories` | — | `[{id, name, description}]` | No |
| POST | `/api/v1/categories` | — | `{id, name, description}` | JWT |

### 2.4 Order Management API (via Gateway)

| Method | Endpoint | Notes | Auth Required |
|--------|----------|-------|---------------|
| POST | `/api/v1/orders` | Existing | JWT |
| POST | `/api/v1/orders/bulk` | Existing | JWT |
| GET | `/api/v1/orders` | Existing | JWT |
| GET | `/api/v1/orders/{id}` | Existing | JWT |
| PATCH | `/api/v1/orders/{id}` | Existing | JWT |
| DELETE | `/api/v1/orders/{id}` | Existing | JWT |
| GET | `/api/v1/customers` | Existing | JWT |
| GET | `/api/v1/customers/{id}` | Existing | JWT |
| POST | `/api/v1/customers` | Existing | JWT |
| PUT | `/api/v1/customers/{id}` | Existing | JWT |
| DELETE | `/api/v1/customers/{id}` | Existing | JWT |

### 2.5 Admin Service (via Gateway)

| Method | Endpoint | Query Params | Response | Auth Required |
|--------|----------|-------------|----------|---------------|
| GET | `/api/v1/admin/dashboard` | — | `{totalOrders, totalRevenue, totalUsers, totalProducts, recentOrders[]}` | JWT + ADMIN |
| GET | `/api/v1/admin/orders` | `status, page, size` | `{content[], totalElements}` | JWT + ADMIN |
| GET | `/api/v1/admin/orders/{id}` | — | `{order details}` | JWT + ADMIN |
| PUT | `/api/v1/admin/orders/{id}/status` | — | `{status}` | JWT + ADMIN |
| GET | `/api/v1/admin/users` | `search, page, size` | `{content[], totalElements}` | JWT + ADMIN |
| GET | `/api/v1/admin/users/{id}` | — | `{user details, orderCount}` | JWT + ADMIN |

### 2.6 Review Service (via Gateway)

| Method | Endpoint | Query Params | Response | Auth Required |
|--------|----------|-------------|----------|---------------|
| GET | `/api/v1/products/{productId}/reviews` | `page, size` | `{content[], totalElements, totalPages}` | No |
| GET | `/api/v1/products/{productId}/reviews/summary` | — | `{productId, averageRating, totalReviews, ratingDistribution}` | No |
| GET | `/api/v1/reviews/my` | `productId, page, size` | `{content[], totalElements, totalPages}` | JWT |
| POST | `/api/v1/reviews` | — | `{id, productId, userId, rating, title, body, verifiedPurchase, approved}` | JWT |
| GET | `/api/v1/reviews/{id}` | — | `{id, productId, userId, rating, title, body, verifiedPurchase, approved}` | No |
| PUT | `/api/v1/reviews/{id}` | — | `{id, productId, userId, rating, title, body, verifiedPurchase, approved}` | JWT (owner) |
| DELETE | `/api/v1/reviews/{id}` | — | 204 No Content | JWT (owner) |
| GET | `/api/v1/admin/reviews` | `status, page, size` | `{content[], totalElements, totalPages}` | JWT + ADMIN |
| POST | `/api/v1/admin/reviews/{id}/approve` | — | `{id, productId, userId, rating, title, body, verifiedPurchase, approved}` | JWT + ADMIN |
| POST | `/api/v1/admin/reviews/{id}/reject` | — | `{id, productId, userId, rating, title, body, verifiedPurchase, approved}` | JWT + ADMIN |

---

## 3. Kafka Topics — Full Specification

### 3.1 Topic Definitions

| Topic | Producer | Consumer(s) | Partitions | Replication | Retention |
|-------|----------|-------------|------------|-------------|-----------|
| `auth.user.registered` | auth-service | admin-service | 3 | 1 | 7 days (604800000ms) |
| `auth.user.updated` | auth-service | admin-service | 3 | 1 | 7 days |
| `cart.checkout.initiated` | cart-service | order-management-api | 3 | 1 | 7 days |
| `product.catalog.created` | product-service | cart-service | 3 | 1 | 7 days |
| `product.catalog.updated` | product-service | cart-service | 3 | 1 | 7 days |
| `product.catalog.deleted` | product-service | cart-service | 3 | 1 | 7 days |
| `order.placed` | order-management-api | admin-service, cart-service, review-service | 3 | 1 | 7 days |
| `order.status.changed` | order-management-api | admin-service | 3 | 1 | 7 days |
| `review.created` | review-service | (none yet) | 3 | 1 | 7 days |

### 3.2 Event Payloads

#### `auth.user.registered`

```json
{
  "userId": "uuid",
  "email": "string",
  "fullName": "string",
  "registeredAt": "2026-09-10T14:30:00Z"
}
```

#### `auth.user.updated`

```json
{
  "userId": "uuid",
  "email": "string",
  "fullName": "string",
  "updatedAt": "2026-09-10T14:30:00Z"
}
```

#### `cart.checkout.initiated`

```json
{
  "eventId": "uuid",
  "cartId": "long",
  "userId": "long",
  "items": [
    {
      "productId": "long",
      "quantity": "int",
      "unitPrice": "decimal"
    }
  ],
  "shippingAddress": {
    "street": "string",
    "city": "string",
    "state": "string",
    "postalCode": "string",
    "country": "string"
  },
  "occurredAt": "2026-09-10T14:30:00Z"
}
```

#### `product.catalog.created`

```json
{
  "productId": "long",
  "name": "string",
  "price": "decimal",
  "stockQuantity": "int"
}
```

#### `product.catalog.updated`

```json
{
  "productId": "long",
  "name": "string",
  "price": "decimal",
  "stockQuantity": "int"
}
```

#### `product.catalog.deleted`

```json
{
  "productId": "long"
}
```

#### `order.placed`

```json
{
  "orderId": "long",
  "orderNumber": "string",
  "userId": "long",
  "totalAmount": "decimal",
  "items": [
    {
      "productId": "long",
      "quantity": "int",
      "unitPrice": "decimal"
    }
  ]
}
```

#### `order.status.changed`

```json
{
  "orderId": "long",
  "orderNumber": "string",
  "oldStatus": "string",
  "newStatus": "string",
  "changedAt": "2026-09-10T14:30:00Z"
}
```

#### `review.created`

Published by review-service when a review is approved by an admin.

```json
{
  "eventId": "uuid",
  "reviewId": "long",
  "productId": "long",
  "userId": "long",
  "rating": "int (1-5)",
  "title": "string | null",
  "body": "string | null",
  "verifiedPurchase": "boolean",
  "occurredAt": "2026-09-10T14:30:00Z"
}
```

---

## 4. Idempotency Strategy

### 4.1 Kafka Consumer Idempotency

Every Kafka event includes an `eventId` (UUID) as the idempotency key. The consuming service checks a local `idempotency_keys` table before processing.

**Database table** (exists in each consuming service's schema):

```sql
CREATE TABLE idempotency_keys (
    event_id    VARCHAR(36) PRIMARY KEY,
    event_type  VARCHAR(100) NOT NULL,
    processed_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

**Processing flow:**

```
1. Consume event from Kafka
2. BEGIN TRANSACTION
3.   SELECT FROM idempotency_keys WHERE event_id = ?
4.   IF EXISTS → ROLLBACK, log "Duplicate event ignored", return
5.   Execute business logic (insert order, update dashboard, etc.)
6.   INSERT INTO idempotency_keys (event_id, event_type, processed_at)
7. COMMIT
```

**Cleanup:** Events older than 7 days can be purged (matches Kafka retention period).

### 4.2 REST Endpoint Idempotency

Client-facing POST endpoints can optionally accept `X-Idempotency-Key` header. If provided, the service checks before creating the resource. If not provided, a UUID is generated server-side.

### 4.3 Ordering Considerations

| Guarantee | Scope | Implementation |
|-----------|-------|----------------|
| Intra-partition ordering | Within a single partition of a topic | Guaranteed by Kafka — events processed in publish order |
| Cross-partition ordering | Across partitions of the same topic | NOT guaranteed — events must be partition-safe |
| Cross-topic ordering | Across different topics | NOT guaranteed — eventual consistency |

**Partitioning strategy:** Events are keyed by `userId` (or `entityId`). This ensures all events for a given user/entity go to the same partition, maintaining per-entity ordering.

**Consumer concurrency:** Multiple consumer instances in a group process different partitions. The `max-concurrency` for Kafka listeners is set to the partition count (3).

---

## 5. Internal API Key Header Specification

### 5.1 Header Format

| Property | Value |
|----------|-------|
| Header name | `X-Internal-API-Key` |
| Value source | `INTERNAL_API_KEY` environment variable |
| Default value | `internal-service-key-12345` (dev only) |
| Comparison method | Constant-time (`MessageDigest.isEqual()`) |
| Transport | HTTP (within Docker network, no TLS) |

### 5.2 Configuration Per Service

```yaml
# application.yml
app:
  internal:
    api-key: ${INTERNAL_API_KEY:internal-service-key-12345}
```

### 5.3 Validation Logic

```java
@Component
public class InternalApiKeyFilter implements OncePerRequestFilter {

    @Value("${app.internal.api-key}")
    private String expectedApiKey;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                     HttpServletResponse response,
                                     FilterChain chain) throws IOException, ServletException {
        String providedKey = request.getHeader("X-Internal-API-Key");

        if (providedKey == null || !MessageDigest.isEqual(
                expectedApiKey.getBytes(StandardCharsets.UTF_8),
                providedKey.getBytes(StandardCharsets.UTF_8))) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.getWriter().write("{\"error\":\"Invalid internal API key\"}");
            return;
        }

        chain.doFilter(request, response);
    }
}
```

### 5.4 Protected Endpoints

| Service | Protected Endpoints | Purpose |
|---------|-------------------|---------|
| product-service | `GET /api/v1/products/{id}`, `GET /api/v1/products`, `GET /api/v1/products/{id}/stock` | Cart Service stock/price validation |
| cart-service | `POST /api/v1/cart/items` (internal) | Order API checkout (future) |
| auth-service | `GET /api/v1/auth/validate` (internal) | Token validation (future, if needed) |

### 5.5 Security Notes

- Gateway strips `X-Internal-API-Key` from external requests before proxying (prevents spoofing by browser clients).
- Key rotation: Change `INTERNAL_API_KEY` env var → rolling restart all services.
- Production: Use a strong random value (32+ chars), not the dev default.

---

## 6. Error Contract Between Services

### 6.1 RFC 7807-style Error Envelope

All services return errors in a consistent format (plan §3):

```json
{
  "type": "https://api.ecommerce.com/errors/{error-code}",
  "title": "Human-readable error title",
  "status": 422,
  "detail": "Specific description of what went wrong",
  "instance": "/api/v1/auth/register",
  "traceId": "abc-123-def-456",
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

### 6.2 Error Code Registry

| HTTP Status | Error Type URI Suffix | Title | When |
|-------------|----------------------|-------|------|
| 400 | `validation-error` | Bad Request | Invalid request body, missing required fields |
| 401 | `unauthorized` | Unauthorized | Missing or invalid JWT |
| 403 | `forbidden` | Forbidden | Insufficient permissions (e.g., non-admin accessing admin endpoints) |
| 404 | `not-found` | Not Found | Resource does not exist |
| 409 | `conflict` | Conflict | Duplicate resource, stock validation failure |
| 422 | `unprocessable-entity` | Validation Error | Business rule violation |
| 429 | `rate-limited` | Too Many Requests | Rate limit exceeded |
| 500 | `internal-error` | Internal Server Error | Unexpected server failure |
| 503 | `service-unavailable` | Service Unavailable | Downstream service unavailable (circuit breaker open) |

### 6.3 Inter-Service Error Propagation

| Scenario | Propagator | Consumer | Error Handling |
|----------|-----------|----------|---------------|
| Product Service down | cart-service | Gateway | 503 + circuit breaker fallback to cached data |
| Auth Service down | Gateway | Frontend | 503 + "Service temporarily unavailable" |
| Kafka event processing fails | order-management-api | Kafka | Event retried by Kafka (backoff) |
| Duplicate Kafka event | order-management-api | Kafka | Idempotency check → event skipped, no error |

---

## 7. Gateway Route Configuration

Static route configuration (no Eureka/service discovery) — [ADR-009](./05-architecture-decisions.md#adr-009-spring-cloud-gateway-no-eureka):

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

        - id: review-service
          uri: http://review-service:8086
          predicates:
            - Path=/api/v1/reviews/**,/api/v1/products/*/reviews/**,/api/v1/admin/reviews/**
          # NOTE: declared BEFORE product-service and admin-service routes so the
          # more specific review paths win over /api/v1/products/** and /api/v1/admin/**

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

---

## Cross-Reference

| Topic | Related Docs |
|-------|-------------|
| ADRs | [05-architecture-decisions.md](./05-architecture-decisions.md) — ADR-004 (Kafka), ADR-005 (Hybrid REST+Kafka), ADR-006 (Internal API Keys), ADR-014 (Idempotency) |
| System Design | [06-system-design.md](./06-system-design.md) — §5 (Buy Flow), §6 (Login Flow), §7 (Event Flow) |
| Plan Sections | [SDLC-PLAN-v2.0.md](../planning/SDLC-PLAN-v2.0.md) — §3 (Service Contracts), §5 (Kafka Events), §6 (API Gateway) |
