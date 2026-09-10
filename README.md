# E-Commerce Platform — SDLC Orchestrator

A full-stack e-commerce platform built with a microservices architecture, following a complete System Development Life Cycle (SDLC) process with AI-assist.

## Architecture

| Repo | Type | Port |
|------|------|------|
| `api-gateway` | Spring Cloud Gateway | 8080 |
| `auth-service` | Spring Boot (Auth/JWT) | 8081 |
| `cart-service` | Spring Boot (Cart) | 8082 |
| `product-service` | Spring Boot (Products) | 8083 |
| `order-management-api` | Spring Boot (Orders, existing) | 8084 |
| `admin-service` | Spring Boot (Admin) | 8085 |
| `e-commerce-frontend` | Next.js 14 | 3000 |

Infrastructure: PostgreSQL 16 (pgvector, schema-per-service) · Redis 7 · Kafka 3.7 · Jaeger
SDLC tools: Plane (JIRA alt) · BookStack (Confluence alt) · Penpot (Figma alt)
Monitoring: Prometheus · Grafana · Loki · Promtail · Alertmanager

## Quick Start

```bash
cp .env.example .env

# Development (backend + infra + frontend)
make dev

# Everything incl. SDLC/monitoring/QA/design tools
make dev-full

# Individual stacks
make infra        # PostgreSQL, Redis, Kafka, Jaeger
make sdlc         # Plane, BookStack
make monitoring   # Prometheus, Grafana, Loki
make qa           # SonarQube, ZAP
make design       # Penpot
```

## Common Tasks

```bash
make build      # Build all 7 services
make test       # Run all test suites
make lint       # Run all linters
make seed       # Populate SDLC tools
make clean      # Teardown everything
```

## Documentation

- [SDLC Plan](planning/SDLC-PLAN-v2.0.md) — Full plan: architecture, contracts, sprints, QA, CI/CD
- [SDLC Docs](docs/) — Requirements, design, API specs, runbooks
- [GitHub Strategy](planning/SDLC-PLAN-v2.0.md#26-github-strategy) — Repos, branches, PR process

## Patterns

- Liquibase for all schema management (schema-per-service)
- Hybrid inter-service comms: REST (sync) + Kafka (async)
- Service-to-service auth via `X-Internal-API-Key`
- Kafka consumers deduplicated by idempotency keys
- Structured logs with correlation IDs (traceId/spanId)
- All PRs squash-merged, CI required before merge