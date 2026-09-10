# 04 — Risk Register

| Field | Value |
|-------|-------|
| Document version | 1.0 |
| Status | Living document — reviewed each sprint retrospective |
| Predecessor | [01-project-charter.md](01-project-charter.md) |
| Authoritative plan | [SDLC-PLAN-v2.0](../planning/SDLC-PLAN-v2.0.md) |
| Related requirements | [02-business-requirements.md](02-business-requirements.md) |
| Related stories | [03-user-stories.md](03-user-stories.md) |

## 1. Scoring Model

- **Likelihood (L):** 1 = Rare, 2 = Unlikely, 3 = Possible, 4 = Likely, 5 = Almost certain.
- **Impact (I):** 1 = Negligible, 2 = Minor, 3 = Moderate, 4 = Major, 5 = Severe.
- **Score = L × I.** Banding: **8–25 = High (red)**, **4–7 = Medium (amber)**, **1–3 = Low (green)**.

Every risk that carries a consequence (Score ≥ 4) lists both a mitigation and a **monitoring trigger** that fires the mitigation or escalates to the owner. Owners are the agents defined in plan §24 (backend, devops, architect, qa, main, docs).

## 2. Risk Register

| ID | Risk | L | I | Score | Mitigation | Monitoring / Trigger | Owner | Status |
|----|------|---|---|-------|------------|----------------------|-------|--------|
| R-01 | DB schema migration conflicts across the 5 schemas (`auth`, `cart`, `product`, `orders`, `admin`) on one Postgres; one broken changelog stalls all services | 4 | 4 | 16 | Liquibase for every schema with the standardized changelog layout (plan §4.2); migrations must be backward-compatible (PR template §13.1); CI runs each service's migrations on a clean Testcontainers/`pgvector/pg16` DB in the `integration-tests` job (§11.1); sequential versioning, one changelog-master per schema | Alert on `DATABASECHANGELOGLOCK` held > 5 min; failed migration in CI blocks merge; sdlc healthcheck script flags a service stuck in `waiting` (plan §23 fix 12) | architect + backend | Mitigated (fix #1 applied) — monitor each Sprint |
| R-02 | Kafka duplicate delivery or cross-partition ordering problems causing duplicate/bad orders | 3 | 4 | 12 | Every consumer dedupes on `eventId` against an idempotency repository (plan §5.3, FR-ORDER-09); `eventId` idempotency plus outbox retention in `orders` schema; keyed producers on stable keys (user/order id) to preserve per-entity ordering; 3 partitions + 7-day retention allow replay; Testcontainers Kafka integration tests cover publish/consume (plan §10.3) | `kafka_consumergroup_lag` > threshold on any of the 8 topics; duplicate-warning log count (`Duplicate event ignored`) rising; replay drill results in sprint review | backend | Mitigated (fix #4 applied) — monitor consumer lag |
| R-03 | Service-to-service authentication exposure — a compromised or unauthorized caller minting internal calls that bypass the gateway | 2 | 5 | 10 | Internal API key (`INTERNAL_API_KEY`) + `app.internal.allowed-services` allow-list = only cart-service, admin-service, order-api (plan §4.4); services on a private Docker network with the gateway as sole public ingress (§1.1); per-environment keys via `.env` (never default secrets in prod, §9.2 `detect-secrets`); TLS documented for prod (plan §23 fix 15) | Non-allow-listed or missing-key internal calls logged; 401/403 rate on internal endpoints spikes (alert via `HighErrorRate` on auth filter); Jaeger spans flagged for cross-service without key context | devops + backend | Mitigated (fix #2 applied) — monitor |
| R-04 | Single-PostgreSQL bottleneck — connection exhaustion, lock contention, or slow catalog queries degrade all 5 services sharing one instance | 3 | 4 | 12 | `max_connections = 200` budgeted across service pools (HikariCP with headroom), `shared_buffers = 256MB`, `work_mem = 4MB`, cache tuning per plan §4.3; Redis caching/locks offload hot catalog reads (NFR-SCALE-02); server-side pagination bounds result sets; index + `pg_stat_statements` review before perf sign-off | `max_connections` utilization > 80% prometheus alert; `HighLatency` (p95 > 0.5 s, plan §14.2) or slow-query growth; k6 stress ramp to 500 users (plan §10.5) failing NFR-PERF-01 | devops | Open — monitoring starts Sprint 2 |
| R-05 | JWT security — forged, stolen, or long-lived tokens granting access to user data or admin functions | 2 | 5 | 10 | Signed, short-lived access tokens validated at the gateway on every route; refresh tokens stored/rotated in `auth.refresh_tokens` and revoked at logout (FR-AUTH-06); ADMIN role claim enforced for `/api/v1/admin/**` (plan §3.6); tokens never logged (PII masking §14.3); HTTPS/TLS for production (fix #15); Spring Security as OAuth2 Resource Server (§1.2) | `401` spike on auth-service / gateway filter; refresh-token reuse detection (a replayed used token rotates the whole family) alert; `HighErrorRate` on login/refresh endpoints | backend | Mitigated — monitor from Sprint 1 |
| R-06 | Account & endpoint abuse — credential stuffing on register/login and spidering of public catalog endpoints past the designed limits | 4 | 3 | 12 | Per-endpoint rate limits at gateway (login 10/min, register 5/min, products 200/min, cart 50/min, orders 30/min, default 100/min) enabled by default with response headers (plan §6.3); input validation on all bodies/params; OWASP ZAP pre-deploy scan; no email/marketing surface in scope per charter §3.2 | 429 rejection metric sustained spike alert; failed-login aggregate rising; ZAP rule failures block release (plan §10.6) | devops + qa | Open — monitoring from Sprint 1 |
| R-07 | Dependency CVEs in Spring Boot/Java/Node images going unpatched, undermining the security quality gate | 4 | 4 | 16 | Snyk on every PR + weekly scheduled scan (`0 6 * * 1`, plan §11.3); OWASP dependency-check; **0 high/critical merge gate** (§22.5); Dependabot for maven/npm manifests; stay on actively patched lines (Spring Boot 3.4.x, Java 21 LTS, Next.js 14) | Snyk/Dependabot alert on new high/critical; scheduled scan findings triaged each week; merge blocked if gate fails | qa + devops | Monitoring |
| R-08 | Single-developer bus factor — knowledge loss or onboarding stall if the sole engineer is unavailable | 3 | 4 | 12 | Playbook-as-code: 15 SDLC docs + ADRs + runbooks (plan §19.1), deploy/DR/monitoring runbooks, seed scripts; 9-agent structure with routed tasks (plan §24); mandatory PR review checklist incl. "documentation updated" (§13.1); conventional commits and CODEOWNERS (§13); retrospective action-item tracking (§17); AI usage log for continuity (§18) | Doc currency KPI (refreshed, no placeholders) at each sprint review; PR review-completion rate; retrospective action-item closure < 100% opens the risk | main + docs | Mitigated by process — ongoing |
| R-09 | Container memory exhaustion — full ~9.5 GB stack (23 services, plan §21.1) OOM-killing core app containers on a developer machine | 4 | 3 | 12 | Compose profiles let devs run slices (`backend` ~3.5 GB, etc., plan §8.1); per-service memory limits + healthchecks (plan §8.2); `make clean` to drop stale volumes (`down -v`); `make dev` documented for minimal daily stack | Prometheus `container_memory_*` > 80% of limit for 5 min alert; `OOMKilled` events; `docker compose ps` health aggregation script flags unhealthy services (fix #12) | devops | Open — monitoring |
| R-10 | Backup / DR failure — silent `pg_dump`/Redis RDB backup failure invalidates committed RTO ≤ 1 h / RPO ≤ 24 h | 2 | 5 | 10 | pg_dump daily (30-day retention), Redis RDB every 6 h (7-day), Kafka retention 7 days (plan §16.1); documented restore runbook; quarterly DR restore drill with recorded sign-off (fix #16) | Backup job exit-code alert + missed-run alert; drill sign-off overdue by one sprint → escalate to main; restore drill time exceeding RTO triggers runbook review | devops + main | Monitoring |
| R-11 | Integration risk with the EXISTING order-management-api — its contracts, DB schema, or dependency versions break when adding the Kafka producer/consumer | 3 | 3 | 9 | Extend, don't rewrite: only additive producer/consumer changes (plan §3.4); additive, backward-compatible Liquibase migrations on the existing `orders` schema; contract tests + Testcontainers Kafka integration for `cart.checkout.initiated` → order (plan §10.3); status event parity checked against existing PATCH endpoint | `integration-tests` job on order-api red blocks merge; diff-review of existing endpoints in every order PR; `HighErrorRate`/`ServiceDown` alert on order-api (plan §14.2) | backend | Open |
| R-12 | Single Kafka broker (replication factor 1) data loss on broker restart or disk failure | 3 | 3 | 9 | Broker recovery ordered via compose `depends_on` + healthchecks (plan §8.2); 7-day retention and auto-create topics absorb short outages (plan §5.2); idempotent consumers tolerate re-delivery after replay (plan §5.3); production path documented to raise replication factor and add brokers | `ServiceDown` alert for kafka (plan §14.2); consumer-lag alerts (see R-02); replay drill restoring events from retention window each sprint | devops | Open — accepted for dev, documented prod path |

## 3. Top Risks by Score (Focus for Release)

| Rank | ID | Risk | Score |
|------|----|------|-------|
| 1 | R-01 | DB schema migration conflicts across 5 schemas | 16 |
| 2 | R-07 | Dependency CVEs unpatched | 16 |
| 3 | R-02 | Kafka duplicate / ordering | 12 |
| 4 | R-04 | Single-Postgres bottleneck | 12 |
| 5 | R-06 | Account & endpoint abuse (rate-limit consent/abuse) | 12 |
| 6 | R-08 | Single-developer bus factor | 12 |
| 7 | R-09 | Container memory exhaustion (~9.5 GB full stack) | 12 |

**Release gate (plan §22.5):** R-01, R-02, R-05, R-07 must be green for merge; R-04 and R-09 must have dashboards + alerts wired by Sprint 2; R-10 must have one successful restore drill before go-live.

## 4. Risk Review Cadence

Risks and their triggers are re-scored at every sprint retrospective (plan §17) and after any incident. Approved mitigations that touch code or config surface here as requirements (FR/NFR) or user stories in [02-business-requirements.md](02-business-requirements.md) and [03-user-stories.md](03-user-stories.md), keeping the register traceable to the rest of the SDLC.