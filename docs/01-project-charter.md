# 01 — Project Charter

| Field | Value |
|-------|-------|
| Project | E-Commerce Microservices Platform |
| Document version | 1.0 |
| Status | Ratified |
| Owner | Sushant (Product Owner / main agent) |
| Last updated | 2026-09-10 |
| Authoritative plan | [SDLC-PLAN-v2.0](../planning/SDLC-PLAN-v2.0.md) |
| Estimated duration | 4 sprints / ~11 execution days (plan §20) |

## 1. Vision & Mission

**Vision.** A production-grade, fully observable e-commerce microservices platform — running locally on one developer machine via Docker Compose — that proves the entire SDLC discipline end to end: architecture and service contracts, five schema database design, event-driven integration over Kafka, 14-screen responsive storefront, CI/CD, QA hardening, and disaster recovery.

**Mission.** Deliver a working shopping journey (browse → cart → checkout → order → track) served by six microservices through a single API Gateway, with an admin dashboard, 15 SDLC artifacts, automated quality gates, and documented recovery procedures — in four sprint weeks, so that every decision is auditable and reproducible by any future contributor.

## 2. Business Goals

| ID | Goal | Primary Metric | Source |
|----|------|----------------|--------|
| BG-01 | Ship a complete storefront covering browse, search, cart, checkout, and order tracking | 14 frontend screens functional (plan §7.2) | plan §7 |
| BG-02 | Run the full stack on a single developer machine | ~9.5 GB total RAM; 6 compose profiles (plan §8.1, §21.1) | plan §8, §21 |
| BG-03 | Meet release-readiness quality gates before go-live | Coverage ≥ 80%, Lighthouse ≥ 90, p95 < 200 ms, 0 high/critical CVEs, 0 WCAG 2.1 AA violations (plan §22.5) | plan §10, §22 |
| BG-04 | Institutionalize the SDLC so one developer can be replaced safely | 15 documents + ADRs + runbooks + 4 retrospectives (plan §19.1, §17) | plan §19, §22 |
| BG-05 | Operate observably and recoverably | RTO ≤ 1 h, RPO ≤ 24 h, alerting on error/latency/downtime (plan §16.2, §14.2) | plan §14, §16 |

## 3. Project Scope

### 3.1 In Scope

- **Applications (8 repositories, plan §2):** `sdlc/` orchestrator (Docker Compose + docs), `api-gateway`, `auth-service`, `cart-service`, `product-service`, `order-management-api` (existing — extended), `admin-service`, `e-commerce-frontend`.
- **Infrastructure:** single PostgreSQL 16 instance with 5 schemas (`auth`, `cart`, `product`, `orders`, `admin`), Redis 7 (cache + locks), Kafka 3.7.0 with 8 topics, Jaeger tracing, Liquibase for all schemas (plan §4, §5).
- **API Gateway:** Spring Cloud Gateway with JWT validation, per-endpoint rate limiting, configurable CORS, request logging (plan §6).
- **Frontend UI:** 14 screens, responsive across 4 breakpoints, WCAG 2.1 AA, 18 shadcn/ui components (plan §7).
- **Events:** `auth.user.registered`, `auth.user.updated`, `cart.checkout.initiated`, `product.catalog.{created,updated,deleted}`, `order.placed`, `order.status.changed` (plan §5.1).
- **DevOps & QA:** Docker Compose (23 services, 6 profiles), Makefile, CI/CD per repo, Prometheus/Grafana/Loki/Alertmanager, k6 load testing, Playwright E2E, ZAP/Snyk/Semgrep security scans, Testcontainers integration tests.
- **Docs & process:** 15 SDLC documents, seed scripts, DR backups (pg_dump daily, Redis RDB, Kafka retention), sprint retrospectives.

### 3.2 Out of Scope

- Real payment processing (payment is **simulated** at checkout — plan §7.2 screen 6).
- Physical fulfillment, shipping carriers, or live shipment tracking.
- Production hosting beyond local Docker Compose (staging/prod deployment is documented but out of build scope).
- Multi-region HA, DB clustering/replication, Kafka multi-broker (single broker, replication factor 1 accepted — §5.2).
- Marketing automation, email campaigns, or customer-consent program infrastructure.
- Mobile native apps and i18n/multi-currency support.
- User-generated reviews/ratings.
- Deep B2B bulk-order workflows (the `/orders/bulk` endpoint exists; no dedicated UI).

## 4. Stakeholders

| Role | Actor | Responsibilities |
|------|-------|------------------|
| Product Owner / Orchestrator | Sushant (`main`) | Final scope decisions, priorities, sprint planning, sign-off |
| Solution Architect | `architect` agent | System design, ADRs, API contracts, database schema, Kafka event design |
| Backend Engineer | `backend` agent | Spring Boot services, JPA entities, REST controllers, unit tests |
| Frontend Engineer | `frontend` agent | Next.js pages, shadcn/ui components, API client |
| DevOps Engineer | `devops` agent | Docker Compose, CI/CD, monitoring, DR scripts |
| QA Engineer | `qa` agent | Unit/integration/E2E tests, security and accessibility scanning |
| UX Designer | `ux-designer` agent | Design tokens, wireframes, responsive & accessibility specs |
| Technical Writer / Docs | `docs` agent | 15 SDLC documents, runbooks, READMEs |
| End Users | Customer & Administrator personas (see [02-business-requirements.md](02-business-requirements.md)) | Target users whose workflows drive requirements |

## 5. Objectives & Success Metrics (KRIs)

Success is measured against the quality gates in plan §22.5. Each KRI has an owner-led verification method.

| ID | KRI | Target | How It Is Measured | Source |
|----|-----|--------|--------------------|--------|
| KRI-01 | API latency | p95 < 200 ms | k6 load test, 100 concurrent users, 5 min | plan §10.5, §22.5 |
| KRI-02 | Frontend performance | LCP < 2.5 s; Lighthouse score ≥ 90 | Lighthouse CI (`qa-accessibility` target) | plan §10.5, §22.5 |
| KRI-03 | Code coverage | ≥ 80% per backend service; ≥ 70% frontend | JaCoCo (Java), Vitest coverage | plan §10.2, §22.3 |
| KRI-04 | Security posture | 0 high/critical vulnerabilities | Snyk + OWASP dependency-check + Semgrep + ZAP per PR | plan §10.6, §11.3, §22.5 |
| KRI-05 | Accessibility | 0 WCAG 2.1 AA violations | axe-core + Lighthouse accessibility audits | plan §7.5, §22.5 |
| KRI-06 | Resilience | RTO ≤ 1 h, RPO ≤ 24 h | Restore drill from backups (quarterly) | plan §16, §23 fix 16 |
| KRI-07 | Platform operability | All 6 services + gateway healthy; alerts firing on error/latency/downtime | `up` metrics, `HighErrorRate`/`HighLatency`/`ServiceDown` alerts | plan §14.2, §23 fix 12 |
| KRI-08 | Delivery scope | All 14 screens + 8 Kafka topics + 5 schemas shipped | Sprint review against plan §7.2, §5.1, §4.1 | plan §7, §5, §4 |
| KRI-09 | Documentation completeness | 15 SDLC docs, no TODO/placeholder content | Docs review gate | plan §19.1, §22.1 |
| KRI-10 | Integration integrity | All critical E2E flows green (login→browse→cart→checkout→confirmation) | Playwright CI | plan §10.4 |

## 6. Constraints

| ID | Constraint | Detail | Source |
|----|-----------|--------|--------|
| C-01 | Timeline | 4 one-week sprints, ~11 execution days; parallel work limited by phases | plan §17.2, §20 |
| C-02 | Team size | Single human developer (bus factor 1); agents compensate via docs/process | plan §21, §24 |
| C-03 | Memory budget | Full stack ~9.5 GB; profile-based slices for dev (§8.1) | plan §8.1, §21.1 |
| C-04 | Database topology | One Postgres host, `max_connections = 200`, 5 schemas — a shared bottleneck to be managed | plan §4.1, §4.3 |
| C-05 | Existing system | `order-management-api` must be **extended, not rewritten** (add Kafka producer/consumer only) | plan §3.4 |
| C-06 | Locked stack | PostgreSQL 16, Spring Boot 3.4.x, Java 21 LTS, Next.js 14, React 18, Tailwind 3, Liquibase (not Flyway) | plan §1.2, §23 fix 1 |
| C-07 | Security baseline | JWT + short-lived access tokens, internal API keys for service-to-service calls, rate limiting on gateway | plan §3.6, §4.4, §6.3 |

## 7. Assumptions

- The developer machine has Docker (with Compose v2) and 16 GB+ RAM and can pull public images.
- Docker Compose healthchecks (`pg_isready`, `redis-cli ping`) succeed before dependent services start (plan §8.2).
- The existing `order-management-api` repository is available, contains Liquibase-managed `orders` schema, and is contract-compatible with plan §3.4.
- Credentials (e.g., `DB_PASSWORD`, `INTERNAL_API_KEY`, JWT secret) are supplied via `.env`, never committed; `.env.example` documents placeholders (plan §2.1).
- A single Kafka broker (replication factor 1) is acceptable for development; producers carry idempotency keys so duplicates are absorbed on re-delivery (plan §5.3).
- Seed data scripts (`scripts/`) populate realistic categories, products, users, and orders for dev/demo (plan §20 phase 10).
- No third-party vendors or external SaaS are required beyond public container registries.

## 8. Deliverables

| ID | Deliverable | Reference |
|----|-------------|-----------|
| D-01 | 8 repositories with source code for all services and frontend | plan §2.2 |
| D-02 | Docker Compose with 23 services across 6 profiles + Makefile | plan §8, §9 |
| D-03 | API Gateway with JWT, rate limiting, CORS, request logging | plan §3.6, §6 |
| D-04 | 6 backend services with OpenAPI specs and Liquibase migrations | plan §3, §4 |
| D-05 | 8 Kafka topics with configured partitioning/retention and idempotent consumers | plan §5 |
| D-06 | 14-screen responsive, WCAG 2.1 AA frontend (Next.js 14 + shadcn/ui) | plan §7 |
| D-07 | CI/CD pipelines per repository + security scanning | plan §11 |
| D-08 | Monitoring stack (Prometheus, Grafana, Loki, Alertmanager, Jaeger) with alert rules | plan §14 |
| D-09 | DR procedures: pg_dump daily (30-day retention), Redis RDB (6 h / 7 d), Kafka retention (7 d) | plan §16 |
| D-10 | 15 SDLC documents incl. this charter, requirements, stories, risk register, ADRs, runbooks | plan §19.1, §22.1 |
| D-11 | QA evidence: unit ≥ 80%, integration (Testcontainers), E2E (Playwright), performance (k6), security (ZAP/Snyk/Semgrep) | plan §10, §22.3 |
| D-12 | Sprint retrospectives for all 4 sprints + AI usage log | plan §17, §18 |

## 9. Approvals

| Role | Name | Date | Decision |
|------|------|------|----------|
| Product Owner | Sushant | 2026-09-10 | Approve charter and scope |
| Solution Architect | architect agent | 2026-09-10 | Approve architecture constraints |
| QA | qa agent | 2026-09-10 | Approve quality gates (KRI targets) |

## 10. Next Artifacts

- [02-business-requirements.md](02-business-requirements.md) — personas, functional & non-functional requirements.
- [03-user-stories.md](03-user-stories.md) — backlog with acceptance criteria and estimates.
- [04-risk-register.md](04-risk-register.md) — risk register with mitigations and monitoring triggers.
- [05-architecture-decisions.md](05-architecture-decisions.md) — ADRs (per plan §22.1).