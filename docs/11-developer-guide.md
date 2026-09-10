# Developer Guide

## 1. Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Java | 21 LTS (Temurin) | Backend services (Spring Boot 3.4) |
| Node.js | 20 LTS | Frontend (Next.js 14) |
| Docker + Docker Compose | Latest | All services run in containers |
| GitHub CLI (`gh`) | Latest | Repo creation, PR management |
| k6 | Latest (optional) | Performance testing |

---

## 2. One-Time Setup

### 2.1 Authenticate with GitHub

```bash
gh auth login
```

### 2.2 Clone All Repos

The platform consists of 8 repositories:

| # | Repo | Type | Port |
|---|------|------|------|
| 1 | `sdlc` | Orchestrator (Docker Compose, docs, scripts) | — |
| 2 | `api-gateway` | Spring Cloud Gateway | 8080 |
| 3 | `auth-service` | Authentication & JWT | 8081 |
| 4 | `cart-service` | Shopping cart | 8082 |
| 5 | `product-service` | Product catalog & search | 8083 |
| 6 | `order-management-api` | Orders, customers, payments | 8084 |
| 7 | `admin-service` | Admin dashboard | 8085 |
| 8 | `e-commerce-frontend` | Next.js 14 | 3000 |

```bash
# Create repos via gh CLI
gh repo create sdlc --public --description "E-Commerce SDLC: Docker Compose, docs, scripts" --clone
gh repo create api-gateway --public --description "Spring Cloud Gateway" --clone
gh repo create auth-service --public --description "Authentication & JWT service" --clone
gh repo create cart-service --public --description "Shopping cart service" --clone
gh repo create product-service --public --description "Product catalog & search" --clone
gh repo create admin-service --public --description "Admin dashboard service" --clone
gh repo create e-commerce-frontend --public --description "Next.js 14 frontend" --clone
```

All repos should be siblings:

```
/Projects/Library/
├── sdlc/
├── api-gateway/
├── auth-service/
├── cart-service/
├── product-service/
├── order-management-api/
├── admin-service/
└── e-commerce-frontend/
```

### 2.3 Configure Environment

```bash
cd sdlc
cp .env.example .env
# Edit .env as needed — defaults work for local dev
```

---

## 3. Starting Everything

All commands are run from the `sdlc/` directory.

### 3.1 Quick Start

```bash
make dev          # Backend + infrastructure (~3.5GB RAM)
make dev-full     # Everything — 23 containers (~9.5GB RAM)
```

### 3.2 Profiles

| Profile | Command | Services | RAM |
|---------|---------|----------|-----|
| `backend` | `make dev` | App services + PostgreSQL, Redis, Kafka, Jaeger | ~3.5GB |
| `full` | `make dev-full` | All 23 services | ~9.5GB |
| `sdlc` | `make sdlc` | Plane + BookStack | ~3GB |
| `monitoring` | `make monitoring` | Prometheus + Grafana + Loki + Promtail + Alertmanager | ~1.5GB |
| `qa` | `make qa` | SonarQube + ZAP | ~2GB |
| `design` | `make design` | Penpot | ~2GB |

### 3.3 Infrastructure Only

```bash
make infra    # PostgreSQL, Redis, Kafka, Jaeger (no app services)
```

### 3.4 Service Ports

| Service | URL |
|---------|-----|
| Frontend | http://localhost:3000 |
| API Gateway | http://localhost:8080 |
| Auth Service | http://localhost:8081 |
| Cart Service | http://localhost:8082 |
| Product Service | http://localhost:8083 |
| Order API | http://localhost:8084 |
| Admin Service | http://localhost:8085 |
| Grafana | http://localhost:3002 |
| Prometheus | http://localhost:9090 |
| Jaeger | http://localhost:16686 |
| Loki | http://localhost:3100 |
| Alertmanager | http://localhost:9093 |
| SonarQube | http://localhost:9000 |
| ZAP | http://localhost:8090 |

### 3.5 Health Check

```bash
bash scripts/health-check.sh   # Aggregated health via Gateway actuator endpoint
```

---

## 4. Common Workflow

### 4.1 Branch Naming

```
feature/{service}-{description}
bugfix/{service}-{description}
hotfix/{description}
release/v{major}.{minor}.{patch}
```

Examples:

```
feature/auth-jwt-refresh
fix/cart-stock-race-condition
hotfix/order-kafka-consumer
release/v1.2.3
```

### 4.2 Conventional Commits

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

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`

### 4.3 PR Flow

1. Create branch from `develop`
2. Make changes, commit with conventional commits
3. Push and open PR against `develop`
4. Fill out the PR template (description, type, testing checklist)
5. Wait for CI: `lint`, `unit-tests`, `integration-tests`
6. Request review / self-merge (solo project)
7. Merge to `develop`

---

## 5. Running Tests

### 5.1 All Tests

```bash
make test          # runs scripts/run-tests.sh — backend + frontend unit tests
```

### 5.2 Backend Tests Only

```bash
make test-backend  # ./mvnw test for all 6 backend services
```

### 5.3 Frontend Tests Only

```bash
make test-frontend # npm run test for e-commerce-frontend
```

### 5.4 E2E Tests

```bash
make test-e2e      # npx playwright test (requires app running on :3000 and :8080)
```

### 5.5 Performance Tests

```bash
make qa-performance   # runs scripts/load-tests.sh (requires k6 installed)
```

### 5.6 Security Scans

```bash
make qa-security   # runs scripts/security-scan.sh (OWASP dependency-check + npm audit + ZAP)
```

---

## 6. Linting

```bash
make lint   # ESLint (frontend) + Checkstyle (all backend services)
```

Per-service:

```bash
# Frontend
cd ../e-commerce-frontend && npm run lint

# Backend (example: auth-service)
cd ../auth-service && ./mvnw checkstyle:check
```

---

## 7. Troubleshooting

| Problem | Symptom | Fix |
|---------|---------|-----|
| **Port conflict** | `BindException: Address already in use` | Stop the process using the port: `lsof -ti:8080 \| xargs kill -9` |
| **Kafka not ready** | Services fail to start, `org.apache.kafka.common.errors.TimeoutException` | Wait for Kafka to pass its healthcheck, or restart: `docker compose restart kafka` |
| **PostgreSQL max_connections** | `FATAL: too many connections` | Default is 200. Stop unused containers or increase in `docker-compose.yml` under `postgres.command` |
| **Container OOM** | Container exits with code 137 | Increase Docker memory limit (Docker Desktop -> Settings -> Resources). Full profile needs ~9.5GB |
| **Frontend can't reach API** | CORS errors or network failure in browser | Ensure API Gateway is running on :8080. Check `CORS_ALLOWED_ORIGINS` in `.env` |
| **Liquibase migration fails** | `MigrationException` on startup | Check schema name matches service config. Ensure Postgres is healthy before service starts |
| **k6 not installed** | `k6: command not found` | Install from https://k6.io/docs/getting-started/installation/ |
| **Playwright browsers missing** | `browserType.launch: Executable not found` | Run `npx playwright install --with-deps` in `e-commerce-frontend/` |
| **Jaeger shows no traces** | Jaeger UI empty at localhost:16686 | Verify services are configured with OpenTelemetry agent. Check `OTEL_EXPORTER_OTLP_ENDPOINT` env var |
| **Grafana dashboards empty** | No data in Grafana at localhost:3002 | Start full monitoring profile: `make monitoring`. Ensure Prometheus is scraping targets at localhost:9090 |
