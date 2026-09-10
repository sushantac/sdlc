# Architecture Decision Records

> Authoritative source: [SDLC-PLAN-v2.0.md](../planning/SDLC-PLAN-v2.0.md)

All ADRs follow [MADR](https://adr.github.io/madr/) format.

---

## ADR-001: Microservices over Monolith

**Status:** Accepted

**Context:** The platform serves e-commerce with distinct bounded contexts: authentication, cart management, product catalog, order processing, and admin analytics. The existing `order-management-api` is already a standalone Spring Boot service. A solo developer will build this over ~11 days across 4 sprints.

**Decision:** Decompose into 5 backend services + 1 API gateway + 1 frontend, each in its own repository:

| Service | Port | Bounded Context |
|---------|------|-----------------|
| api-gateway | 8080 | Routing, JWT validation, rate limiting |
| auth-service | 8081 | User registration, login, token management |
| cart-service | 8082 | Shopping cart CRUD, stock validation |
| product-service | 8083 | Product catalog, categories, search |
| order-management-api | 8084 | Orders, customers, payments (existing) |
| admin-service | 8085 | Dashboard metrics, audit, admin operations |

**Consequences:**
- (+) Each service can be developed, tested, and deployed independently via separate GitHub repos.
- (+) Clear ownership boundaries align with the 9-agent architecture (plan §24).
- (+) Existing `order-management-api` integrates without rewrite.
- (-) Increased operational complexity: 6 deployable artifacts instead of 1.
- (-) Inter-service communication overhead (addressed by ADR-005 hybrid REST+Kafka).
- (-) Solo developer must context-switch between repos (mitigated by per-service CI/CD).

---

## ADR-002: Single PostgreSQL with Schema-Per-Service

**Status:** Accepted

**Context:** Each service needs its own data store to maintain loose coupling. Running 5 separate PostgreSQL instances on a solo dev machine (~9.5GB total RAM budget, plan §8) is prohibitive. The existing order-management-api already uses Liquibase against a `postgres` database.

**Decision:** Use a single PostgreSQL 16 (pgvector) instance with logical schema isolation — one schema per service:

```
PostgreSQL 16 (pgvector) — :5432
├── auth schema       (users, refresh_tokens)
├── cart schema       (carts, cart_items)
├── product schema    (products, categories, product_categories)
├── orders schema     (customers, orders, order_items, payments, idempotency_keys, ...)
└── admin schema      (dashboard_snapshots, audit_entries)
```

Configuration: `max_connections=200`, `shared_buffers=256MB`, `effective_cache_size=768MB` (plan §4.3).

**Consequences:**
- (+) Single database process to manage, backup, and monitor.
- (+) Transactions across schemas are possible (though discouraged for cross-service data).
- (+) Reduces Docker resource consumption from ~2.5GB (5 instances) to ~512MB (1 instance).
- (-) Schema-level access control must be enforced at the application layer — no cross-schema queries.
- (-) A misbehaving service could exhaust shared `max_connections`.
- (-) Future migration to per-service databases requires schema export, not instance clone.

---

## ADR-003: Liquibase for All Schema Management

**Status:** Accepted

**Context:** The existing `order-management-api` already uses Liquibase for migrations. Teams historically debate between Flyway, JPA `ddl-auto`, and Liquibase. Schema changes must be deterministic, repeatable, and version-controlled.

**Decision:** Every service uses Liquibase as the sole schema migration tool. JPA `ddl-auto` is explicitly forbidden in production profiles. Flyway is not used.

Migration convention (plan §4.2):
```
db/{service}/changelog/
├── db.changelog-master.xml
└── v1.0/
    ├── 01_create_users_table.xml
    ├── 02_create_refresh_tokens_table.xml
    └── ...
```

**Consequences:**
- (+) Consistent migration tooling across all 6 services (including existing order-api).
- (+) XML/YAML changelogs are database-platform-agnostic.
- (+) Liquibase tracks applied changesets in `databasechangelog` table — no duplicate runs.
- (-) XML verbosity compared to Flyway's SQL-based approach.
- (-) Team must learn Liquibase's changeSet syntax and rollback procedures.
- (-) `ddl-auto=validate` still requires entities to match schema exactly.

---

## ADR-004: Kafka (KRaft) for Asynchronous Event-Driven Communication

**Status:** Accepted

**Context:** Services must communicate asynchronously for domain events (order placed, user registered, catalog changes). A synchronous-only architecture creates temporal coupling — if Cart Service is down, Order API cannot process checkouts.

**Decision:** Apache Kafka 3.7.0 in KRaft mode (no Zookeeper) with 8 topics (plan §5.1):

| Topic | Producer | Consumers |
|-------|----------|-----------|
| `auth.user.registered` | Auth Service | Admin Service |
| `auth.user.updated` | Auth Service | Admin Service |
| `cart.checkout.initiated` | Cart Service | Order API |
| `product.catalog.created` | Product Service | Cart Service |
| `product.catalog.updated` | Product Service | Cart Service |
| `product.catalog.deleted` | Product Service | Cart Service |
| `order.placed` | Order API | Admin Service, Cart Service |
| `order.status.changed` | Order API | Admin Service |

Topic config: 3 partitions, replication factor 1, 7-day retention (plan §5.2).

**Consequences:**
- (+) Temporal decoupling: producer and consumer don't need to be online simultaneously.
- (+) Event replay capability via Kafka's log-based storage.
- (+) KRaft mode eliminates Zookeeper dependency — simpler Docker Compose.
- (-) At-least-once delivery requires consumer idempotency (addressed by ADR-014).
- (-) Eventual consistency: cart won't reflect order placement immediately.
- (-) Single Kafka broker (replication factor 1) is a single point of failure in production.

---

## ADR-005: Hybrid REST + Kafka Inter-Service Communication

**Status:** Accepted

**Context:** Not all inter-service communication is equal. A cart adding an item needs synchronous stock validation from Product Service. An order being placed can asynchronously notify Admin Service.

**Decision:** Use a hybrid model:

- **Synchronous (REST):** Used when the caller needs an immediate response.
  - Cart Service → Product Service: price/stock validation on add-to-cart
  - All services → Auth Service: JWT validation (via gateway)
- **Asynchronous (Kafka):** Used for fire-and-forget events and eventual consistency.
  - All domain events (user registered, catalog changed, order placed, etc.)

**Consequences:**
- (+) Right tool for each communication pattern.
- (+) Synchronous calls are limited to 1 known dependency per service (Cart→Product only).
- (-) Synchronous calls introduce temporal coupling for that specific path.
- (-) Must handle Product Service downtime in Cart Service (circuit breaker via Resilience4j).

---

## ADR-006: Internal API Keys for Service-to-Service Authentication

**Status:** Accepted

**Context:** Services communicate over a Docker network. A service discovery registry (Eureka, Consul) adds operational overhead disproportionate to a 6-service architecture with fixed ports. Inter-service calls must be authenticated to prevent unauthorized access.

**Decision:** Use a shared secret (`X-Internal-API-Key` header) for service-to-service REST calls. No service discovery registry.

Configuration (plan §4.4):
```yaml
app:
  internal:
    api-key: ${INTERNAL_API_KEY:internal-service-key-12345}
    allowed-services:
      - cart-service
      - admin-service
      - order-api
```

Header specification:
- Header name: `X-Internal-API-Key`
- Value: shared secret from `INTERNAL_API_KEY` env var
- Comparison: constant-time (`MessageDigest.isEqual`) to prevent timing attacks

**Consequences:**
- (+) Zero infrastructure overhead — no Eureka/Consul to run and maintain.
- (+) Fixed Docker hostnames (`cart-service`, `product-service`) replace service discovery.
- (+) Simple to implement and audit.
- (-) Shared secret across all services — rotation requires rolling restart.
- (-) No mutual TLS — relies on Docker network isolation.
- (-) Doesn't scale beyond ~10 services without a vault solution.

---

## ADR-007: JWT Access + Refresh Token Design

**Status:** Accepted

**Context:** The frontend (Next.js) needs stateless authentication with short-lived access tokens and long-lived refresh tokens for session persistence. The API gateway validates JWTs on every request.

**Decision:**
- **Access Token:** JWT, short-lived (15 min), signed with HS256, contains `userId`, `email`, `role`.
- **Refresh Token:** Opaque UUID stored in `auth.refresh_tokens` table, 7-day expiry, single-use (rotation on refresh).
- **Gateway validation:** Spring Cloud Gateway validates JWT signature and expiry before proxying.
- **Login response:** `{accessToken, refreshToken, user}` (plan §3.1).

Token refresh flow:
1. Frontend sends expired access token + valid refresh token to `/api/v1/auth/refresh`.
2. Auth Service validates refresh token against DB, issues new access token.
3. Old refresh token is invalidated (rotation).

**Consequences:**
- (+) Stateless access token validation at the gateway — no DB lookup per request.
- (+) Refresh token rotation limits replay attacks.
- (+) Short access token lifetime limits exposure window.
- (-) Refresh token DB lookup adds latency to token refresh endpoint.
- (-) No revocation of access tokens before expiry (mitigated by 15-min lifetime).
- (-) HS256 symmetric key must be shared between Auth Service and Gateway.

---

## ADR-008: API Versioning via URL Path

**Status:** Accepted

**Context:** APIs evolve. Breaking changes must be backward-compatible during transition periods. URL-based versioning is the simplest approach for a team of one.

**Decision:** All endpoints use URL path versioning: `/api/v1/{resource}`. No header-based or query-parameter versioning.

Examples from plan §3:
- `/api/v1/auth/login`
- `/api/v1/products`
- `/api/v1/cart/items`
- `/api/v1/admin/dashboard`

**Consequences:**
- (+) Explicit, visible in browser/Postman — easy to debug.
- (+) Gateway routes are path-based predicates — natural fit for Spring Cloud Gateway.
- (+) `v2` endpoints can coexist with `v1` without client changes.
- (-) URL proliferation if many versions are maintained simultaneously.
- (-) Clients must update URLs when upgrading versions (no transparent header versioning).
- (-) Gateway route config grows with each version.

---

## ADR-009: Spring Cloud Gateway (No Eureka)

**Status:** Accepted

**Context:** The platform needs a single entry point for all API requests, handling JWT validation, rate limiting, CORS, and request routing. Service discovery (Eureka) was considered but rejected per ADR-006.

**Decision:** Spring Cloud Gateway with static route configuration pointing to fixed Docker hostnames.

Route table (plan §6.1):

| Route ID | Target URI | Predicate |
|----------|------------|-----------|
| auth-service | `http://auth-service:8081` | `Path=/api/v1/auth/**` |
| cart-service | `http://cart-service:8082` | `Path=/api/v1/cart/**` |
| product-service-read | `http://product-service:8083` | `Path=/api/v1/products/**,/api/v1/categories/**` + `Method=GET` |
| product-service-write | `http://product-service:8083` | `Path=/api/v1/products/**,/api/v1/categories/**` + `Method=POST,PUT,DELETE` |
| order-api | `http://order-api:8084` | `Path=/api/v1/orders/**,/api/v1/customers/**` |
| admin-service | `http://admin-service:8085` | `Path=/api/v1/admin/**` |

**Consequences:**
- (+) No Eureka server to run — reduces Docker Compose by 1 service.
- (+) Static routes are predictable and easy to reason about.
- (+) WebFlux reactive model handles high concurrency without thread-per-request.
- (-) No automatic load balancing — Docker DNS handles single instances.
- (-) Adding a new service requires gateway config update + restart.
- (-) No circuit breaker at gateway level (Resilience4j is per-service).

---

## ADR-010: Testcontainers for Integration Testing

**Status:** Accepted

**Context:** Integration tests need real PostgreSQL, Kafka, and Redis instances. Docker Compose stacks are heavy and slow for CI. Testcontainers provides ephemeral, disposable containers.

**Decision:** All integration tests use Testcontainers (plan §10.3):

| Test Type | Container | Scope |
|-----------|-----------|-------|
| API Integration | PostgreSQL + MockMvc | Full request lifecycle |
| DB Integration | PostgreSQL | Schema + queries |
| Kafka Integration | Kafka (KRaft) | Event publish/consume |
| Cache Integration | Redis | Cache hit/miss |
| Security Integration | Spring Security Test | Auth + authorization |

JUnit 5 as the test framework across all services. Coverage target: 80%+ (plan §10.2).

**Consequences:**
- (+) Tests run against real infrastructure, not mocks — higher confidence.
- (+) Containers are disposable — no state leakage between test runs.
- (+) CI pipelines don't need pre-provisioned Docker services.
- (-) Test startup time increases (~5-10s per container).
- (-) Docker-in-Docker or Docker socket mounting required in CI.
- (-) Kafka containers are memory-hungry (~1GB each).

---

## ADR-011: Solo-Developer Git Flow (main + develop)

**Status:** Accepted

**Context:** A single developer builds the entire platform. Complex branching strategies (gitflow with release/hotfix branches, trunk-based development) add overhead that doesn't justify the coordination benefit for one person.

**Decision:** Simplified git flow (plan §12.1):

```
main (production)
│
└── develop (integration)
     │
     ├── feature/{service}-{description}
     ├── bugfix/{service}-{description}
     └── hotfix/{description}
```

Branch naming (plan §12.2): `feature/{service}-{description}`, `bugfix/{service}-{description}`.

Commit convention: Conventional Commits — `feat(auth): add JWT login endpoint`.

Branch protection on `main`: CI checks required (lint, unit-tests, integration-tests), 0 approving reviews required, stale reviews dismissed (plan §26.4).

**Consequences:**
- (+) Simple enough for one developer — minimal ceremony.
- (+) `develop` serves as integration branch — CI runs against all PRs.
- (+) Feature branches keep `develop` always deployable.
- (-) No formal release branch process — releases are tagged commits on `develop` merged to `main`.
- (-) Solo dev means 0-review PRs — self-review only (mitigated by PR template checklist).
- (-) Hotfix flow is informal — no dedicated `hotfix/*` → `main` + `develop` merge path enforced.

---

## ADR-012: Structured Logging with Correlation IDs

**Status:** Accepted

**Context:** Debugging across 6 services requires tracing a request through the entire system. Unstructured `System.out.println` logs are unsearchable and lack context.

**Decision:** All services emit structured JSON logs with correlation IDs (plan §14.3):

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

Correlation ID propagation:
- Gateway generates `traceId` via OpenTelemetry and passes it as `X-Request-Id` header.
- All services include `traceId` and `spanId` in log output.
- Kafka events include `traceId` in headers for cross-service tracing.

**Consequences:**
- (+) Loki can query logs by `traceId` across all services (plan §14.1).
- (+) Grafana dashboards can correlate logs with metrics and traces.
- (+) PII masking in request/response logs (plan fix #9).
- (-) Structured logging adds ~5% CPU overhead per log statement.
- (-) Log volume increases — Loki storage must be monitored.
- (-) All developers must use the structured logger, not stdout.

---

## ADR-013: Prometheus + Grafana + Loki + Jaeger Observability Stack

**Status:** Accepted

**Context:** The platform needs metrics, logs, dashboards, and distributed tracing. Multiple observability tools exist (Datadog, New Relic, ELK). Cost and self-hosting requirements constrain the choice.

**Decision:** Open-source observability stack (plan §14.1):

| Component | Image | Port | Purpose |
|-----------|-------|------|---------|
| Prometheus | `prom/prometheus` | 9090 | Metrics collection (pull model) |
| Grafana | `grafana/grafana` | 3002 | Dashboards & visualization |
| Loki | `grafana/loki` | 3100 | Log aggregation (label-based) |
| Promtail | `grafana/promtail` | — | Log shipping to Loki |
| Alertmanager | `prom/alertmanager` | 9093 | Alert routing |
| Jaeger | `jaegertracing/all-in-one:1.57` | 16686 | Distributed tracing (OpenTelemetry) |

Alert rules (plan §14.2): HighErrorRate (>5% 5xx over 5m), HighLatency (p95 > 500ms), ServiceDown (up == 0).

**Consequences:**
- (+) Full observability stack at zero licensing cost.
- (+) Grafana unifies metrics (Prometheus), logs (Loki), and traces (Jaeger) in one UI.
- (+) Prometheus pull model is simple — services expose `/actuator/prometheus`.
- (-) ~1.5GB additional RAM for monitoring profile.
- (-) Loki label-based indexing is less powerful than Elasticsearch full-text search.
- (-) Jaeger all-in-one is single-instance — no production trace aggregation scaling.

---

## ADR-014: Idempotency Keys for Kafka Consumers

**Status:** Accepted

**Context:** Kafka provides at-least-once delivery semantics. A consumer might process the same event twice (rebalance, consumer restart). Non-idempotent operations (creating an order) would create duplicates.

**Decision:** Every Kafka event carries an `eventId` (UUID) as its idempotency key. Consumers check the `idempotency_keys` table before processing (plan §5.3):

```java
@KafkaListener(topics = "cart.checkout.initiated")
public void handleCheckout(CartCheckoutEvent event) {
    if (idempotencyRepo.existsById(event.eventId())) {
        log.warn("Duplicate event ignored: {}", event.eventId());
        return;
    }
    orderService.placeOrder(event);
    idempotencyRepo.save(new IdempotencyRecord(
        event.eventId(), "CART_CHECKOUT", LocalDateTime.now()
    ));
}
```

Ordering: Events within a topic partition are processed sequentially. The `eventId` dedup is sufficient because Kafka ordering guarantees apply per-partition.

**Consequences:**
- (+) Guaranteed exactly-once processing effect despite at-least-once delivery.
- (+) Idempotency keys are stored in the same database as business data — atomic transaction.
- (+) Cleanup policy: keys older than 7 days can be purged (matches Kafka retention).
- (-) Extra DB write per event — adds ~1-2ms latency.
- (-) `idempotency_keys` table grows unboundedly without cleanup job.
- (-) Cross-partition ordering is not guaranteed — events must be designed to be partition-safe.

---

## ADR-015: Graceful Shutdown for All Services

**Status:** Accepted

**Context:** When Docker stops a container (SIGTERM), in-flight requests and Kafka consumer poll cycles are interrupted. Without graceful shutdown, partial writes and rebalancing storms occur.

**Decision:** All Spring Boot services implement graceful shutdown:

```yaml
server:
  shutdown: graceful

spring:
  lifecycle:
    timeout-per-shutdown-phase: 30s
```

Shutdown sequence:
1. Docker sends SIGTERM.
2. Gateway stops accepting new connections.
3. In-flight requests complete (up to 30s).
4. Kafka consumers commit offsets and leave consumer group.
5. Database connections drain.
6. Application exits.

**Consequences:**
- (+) In-flight requests complete without 502 errors during deployments.
- (+) Kafka consumer groups rebalance cleanly — no duplicate processing from uncommitted offsets.
- (+) Zero-downtime rolling updates in Docker Compose.
- (-) Shutdown takes up to 30s — container stop timeout must be configured accordingly.
- (-) Long-running requests may still be killed if they exceed the timeout.
- (-) Health checks must distinguish between "shutting down" and "unhealthy".

---

## ADR-016: Resilience4j for Service Resilience

**Status:** Accepted

**Context:** Synchronous REST calls between services can fail. The existing `order-management-api` already uses Resilience4j (plan §1.2). Cart Service calls Product Service synchronously for stock validation — if Product Service is down, cart operations must degrade gracefully.

**Decision:** Resilience4j 2.2.0 for circuit breaker and retry patterns. Applied at the client level (e.g., `RestTemplate` or `WebClient` wrapped with Resilience4j decorators).

Key pattern: Circuit Breaker for Cart→Product Service calls.
- **Closed state:** Requests pass through. Failures counted.
- **Open state:** After 5 failures in 60s window, all calls fail fast with fallback.
- **Half-Open state:** After 30s, allow 1 probe request. If successful, close circuit.

**Consequences:**
- (+) Cart Service remains functional when Product Service is down (returns cached/stale data).
- (+) Already in use in existing order-management-api — consistent pattern.
- (+) Prometheus metrics for circuit breaker state exposed via Actuator.
- (-) Fallback logic must be carefully designed — returning stale prices is risky for e-commerce.
- (-) Configuration tuning required per service (failure thresholds, wait durations).
- (-) Adds complexity to error handling paths.

---

## Cross-Reference

| ADR | Related Plan Sections | Related Docs |
|-----|----------------------|--------------|
| ADR-001 | §1.1, §2, §8 | [System Design](./06-system-design.md) |
| ADR-002 | §4.1, §4.3 | [Service Communication](./13-service-communication.md) |
| ADR-003 | §4.2, §23 fix #1 | — |
| ADR-004 | §5.1, §5.2, §5.3 | [Service Communication](./13-service-communication.md) |
| ADR-005 | §3, §5.1 | [Service Communication](./13-service-communication.md) |
| ADR-006 | §4.4, §23 fix #2 | [Service Communication](./13-service-communication.md) |
| ADR-007 | §3.1 | — |
| ADR-008 | §3, §15.1 | — |
| ADR-009 | §6.1, §23 fix #3 | [System Design](./06-system-design.md) |
| ADR-010 | §10.3, §10.4 | — |
| ADR-011 | §12.1, §12.2, §26 | — |
| ADR-012 | §14.3, §23 fix #9 | — |
| ADR-013 | §14.1, §14.2, §8 | — |
| ADR-014 | §5.3, §23 fix #4 | [Service Communication](./13-service-communication.md) |
| ADR-015 | §23 fix #10 | — |
| ADR-016 | §1.2 (Resilience4j) | — |
