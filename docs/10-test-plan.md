# Test Plan

## 1. QA Pyramid

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

---

## 2. Unit Testing

| Service | Framework | Coverage Target |
|---------|-----------|-----------------|
| API Gateway | JUnit 5 + WebTestClient | >= 80% |
| Auth Service | JUnit 5 + Mockito | >= 80% |
| Cart Service | JUnit 5 + Mockito | >= 80% |
| Product Service | JUnit 5 + Mockito | >= 80% |
| Order Management API | JUnit 5 + Mockito | >= 80% |
| Admin Service | JUnit 5 + Mockito | >= 80% |
| Frontend (e-commerce-frontend) | Vitest + React Testing Library | >= 70% |

**Coverage enforcement:** JaCoCo (backend) and Vitest `--coverage` (frontend) must pass the thresholds above. CI will fail if coverage drops below these targets.

Run locally:

```bash
make test-backend    # JUnit 5 unit tests for all 6 backend services
make test-frontend   # Vitest + React Testing Library
```

---

## 3. Integration Testing (Testcontainers)

| Test Type | Tool | Container | Scope |
|-----------|------|-----------|-------|
| DB Integration | Testcontainers | PostgreSQL 16 (`pgvector/pg16`) | Schema creation, Liquibase migrations, JPA queries |
| Kafka Integration | Testcontainers | `apache/kafka:3.7.0` | Event publish/consume across all 8 topics |
| Cache Integration | Testcontainers | Redis 7 (`redis:7-alpine`) | Cache hit/miss, TTL expiry, distributed locks |
| API Integration | Testcontainers + MockMvc | Full request lifecycle | Gateway routing, JWT validation, rate limiting |
| Security Integration | Spring Security Test | — | Authentication, authorization, role checks |

**Testcontainers configuration pattern:**

```java
@Testcontainers
@SpringBootTest
class CartServiceIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("pgvector/pg16")
        .withDatabaseName("test_db")
        .withUsername("test")
        .withPassword("test");

    @Container
    static KafkaContainer kafka = new KafkaContainer(DockerImageName.parse("apache/kafka:3.7.0"));

    @Container
    static GenericContainer<?> redis = new GenericContainer<>("redis:7-alpine")
        .withExposedPorts(6379);
}
```

---

## 4. E2E Testing (Playwright)

| Flow | Priority | Scenario |
|------|----------|----------|
| Full purchase | Critical | Login -> Browse -> Add to Cart -> Checkout -> Order Confirmation |
| Registration | High | Register -> Login -> Profile |
| Product discovery | High | Browse -> Search -> Filter -> Product Detail |
| Admin management | Medium | Admin Login -> Dashboard -> Manage Orders |

**Critical flow detail (Login -> Browse -> Cart -> Checkout -> Confirmation):**

1. Navigate to `http://localhost:3000`
2. Click "Login", enter credentials, submit
3. Verify redirect to home page with authenticated nav
4. Search for a product by name
5. Click a product, verify detail page renders
6. Click "Add to Cart"
7. Open cart, verify item present with correct quantity and price
8. Proceed to checkout, fill shipping address
9. Submit order
10. Verify confirmation page displays order number

**Run locally:**

```bash
make test-e2e   # runs: cd ../e-commerce-frontend && npx playwright test
```

---

## 5. Performance Testing (k6)

Run via `make qa-performance` which executes `scripts/load-tests.sh`.

| Scenario | VUs | Duration | Threshold |
|----------|-----|----------|-----------|
| Load test | 100 | 5 min | p95 < 200ms, error rate < 1% |
| Stress test | ramp to 500 | 10 min | error rate < 5% |

**Load test** hits `GET /api/v1/products?page=0&size=20` through the API Gateway at `http://localhost:8080/api/v1`.

**Stress test** ramps from 0 to 100 VUs over 2 min, holds at 500 VUs for 5 min, then ramps down over 3 min.

Results are exported to:
- `/tmp/k6-load.json`
- `/tmp/k6-stress.json`

**Lighthouse targets:** LCP < 2.5s.

---

## 6. Security Testing

| Tool | Scope | Frequency | Gate |
|------|-------|-----------|------|
| OWASP ZAP | Vulnerability scan of running app | Pre-deploy (manual), via `scripts/security-scan.sh` | 0 high/critical |
| Snyk | Dependency scanning | CI/CD (every PR) | 0 high/critical vulns |
| Semgrep | SAST (static analysis) | CI/CD (every PR) | 0 high/critical findings |
| OWASP dependency-check | Java dependency CVEs | CI/CD + `make qa-security` | CVSS >= 7 fails build |
| npm audit | JS dependency CVEs | CI/CD + `make qa-security` | 0 high |

**ZAP scan** requires the QA profile running (`make qa`). The scanner targets the API Gateway at `http://localhost:8080`.

**Run locally:**

```bash
make qa-security   # runs: scripts/security-scan.sh
```

---

## 7. Accessibility Testing

| Tool | Scope | Target |
|------|-------|--------|
| axe-core | WCAG 2.1 AA violations | Zero violations |
| Lighthouse accessibility | Score per page | >= 90 |
| Keyboard navigation | All interactive elements | Tab-focusable, visible focus states |

**WCAG 2.1 AA requirements (from plan section 7.5):**

- Color contrast ratio >= 4.5:1 for text
- All interactive elements keyboard-focusable
- Focus visible states on all buttons/links
- Alt text on all images
- ARIA labels on form inputs
- Error messages linked to inputs via `aria-describedby`
- Skip-to-content link
- Semantic HTML (`<nav>`, `<main>`, `<article>`, `<aside>`)

**Run locally:**

```bash
make qa-accessibility   # runs: cd ../e-commerce-frontend && npm run lighthouse
```

---

## 8. Code Quality Gates

| Tool | Scope | Enforcement |
|------|-------|-------------|
| Checkstyle | Java code style | `make lint` -> `./mvnw checkstyle:check` |
| SpotBugs | Bug detection | CI/CD gate |
| JaCoCo | Code coverage | CI gate (80% backend / 70% frontend min) |
| ESLint | TypeScript linting | `make lint` -> `npm run lint` |
| Prettier | Code formatting | Pre-commit hook |

---

## 9. QA Environment

### 9.1 Environment Layout

| Resource | Host | Port | Purpose |
|----------|------|------|---------|
| PostgreSQL 16 | `localhost` | 5432 | 5 schemas: auth, cart, product, orders, admin |
| Redis 7 | `localhost` | 6379 | Cache + distributed locks |
| Kafka (KRaft) | `localhost` | 9092 | 8 topics, 3 partitions each |
| API Gateway | `localhost` | 8080 | JWT validation, routing, rate limiting |
| Jaeger | `localhost` | 16686 | Distributed tracing UI |

### 9.2 Test Data Seeding

- **Schema migrations:** Liquibase runs automatically on service startup. Each service manages its own schema.
- **Seed data:** `scripts/seed-plane.sh` and `scripts/seed-bookstack.sh` populate SDLC tools, not application data.
- **Application test data:** Created by E2E tests and integration tests inline. No separate seed script for the QA database.

---

## 10. Quality Gates Summary

All of the following must pass before any release can proceed to production:

| Gate | Threshold | Tool |
|------|-----------|------|
| Backend unit test coverage | >= 80% | JaCoCo |
| Frontend unit test coverage | >= 70% | Vitest `--coverage` |
| High/critical security vulnerabilities | 0 | Snyk, Semgrep, OWASP ZAP |
| Lighthouse accessibility score | >= 90 | Lighthouse CI |
| API response time (p95) | < 200 ms | k6 |
| WCAG 2.1 AA violations | 0 | axe-core |
| All CI checks passing | lint, unit-tests, integration-tests | GitHub Actions |
| Documentation complete | All 15 SDLC docs | Manual review |
