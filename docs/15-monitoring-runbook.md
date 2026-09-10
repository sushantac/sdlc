# Monitoring Runbook

## 1. Monitoring Stack

| Component | Image | Port | Purpose |
|-----------|-------|------|---------|
| Prometheus | `prom/prometheus` | 9090 | Metrics collection and alerting rules |
| Grafana | `grafana/grafana` | 3002 | Dashboards and visualization |
| Loki | `grafana/loki` | 3100 | Log aggregation (query engine) |
| Promtail | `grafana/promtail` | — | Log shipping from containers to Loki |
| Alertmanager | `prom/alertmanager` | 9093 | Alert routing and notification |
| Jaeger | `jaegertracing/all-in-one` | 16686 | Distributed tracing UI |

**Start monitoring:**

```bash
make monitoring    # Prometheus + Grafana + Loki + Promtail + Alertmanager
make dev           # App services (if not already running)
```

---

## 2. Dashboards

### 2.1 Pre-Built Dashboards

| Dashboard | Source | What It Shows |
|-----------|--------|---------------|
| Spring Boot Metrics | `monitoring/grafana/dashboards/` | JVM metrics, HTTP request rates, response times |
| PostgreSQL | Grafana community | Connections, queries/s, cache hit ratio |
| Redis | Grafana community | Memory, hit rate, connected clients |
| Kafka | Grafana community | Consumer lag, throughput, broker health |
| Node Exporter | Grafana community | Host CPU, memory, disk (if deployed outside Docker) |

### 2.2 Accessing Dashboards

- **Grafana:** http://localhost:3002 (admin / admin)
- **Prometheus:** http://localhost:9090
- **Jaeger:** http://localhost:16686
- **Alertmanager:** http://localhost:9093

---

## 3. Alert Rules

Defined in `monitoring/prometheus/prometheus.yml`:

### 3.1 Active Alerts

| Alert | Severity | Condition | Duration |
|-------|----------|-----------|----------|
| `HighErrorRate` | Critical | `rate(http_server_requests_seconds_count{status=~"5.."}[5m]) > 0.05` | 5 min |
| `HighLatency` | Warning | `histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m])) > 0.5` | 5 min |
| `ServiceDown` | Critical | `up == 0` | 1 min |

### 3.2 Alert Definitions

```yaml
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

---

## 4. Structured Logging

All services emit JSON structured logs:

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

### 4.1 Correlation IDs

Every request is assigned a correlation ID (`traceId`) at the API Gateway. This ID is propagated through all service calls and Kafka messages, enabling end-to-end request tracing.

**How it works:**

1. API Gateway generates or extracts `traceId` from the incoming request header
2. `traceId` is added to MDC (Mapped Diagnostic Context) for all log statements
3. `traceId` is passed via HTTP headers to downstream services
4. `traceId` is included in Kafka event payloads
5. `traceId` links logs to Jaeger traces

### 4.2 Log Levels

| Level | Usage |
|-------|-------|
| ERROR | Unhandled exceptions, failed operations |
| WARN | Recoverable issues, duplicate events, degraded state |
| INFO | Business events (order placed, user registered), startup/shutdown |
| DEBUG | Detailed operational info (SQL queries, cache lookups) — disabled in production |

---

## 5. Querying Logs

### 5.1 Loki Query Examples (via Grafana)

**All logs from a specific service:**

```
{service="cart-service"}
```

**Errors from auth-service in the last hour:**

```
{service="auth-service"} | json | level="ERROR"
```

**Logs containing a specific trace ID:**

```
{service=~".+"} | json | traceId="abc-123"
```

**All 5xx errors across all services:**

```
{service=~".+"} | json | level="ERROR" |~"5.."
```

**Logs from a specific endpoint:**

```
{service="product-service"} | json | message=~"/api/v1/products.*"
```

### 5.2 Querying via CLI

```bash
# Query Loki directly
curl -G "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={service="auth-service"}' \
  --data-urlencode 'start='$(date -v-1H +%s)'000000000' \
  --data-urlencode 'end='$(date +%s)'000000000'
```

---

## 6. Distributed Tracing (Jaeger)

### 6.1 Accessing Traces

1. Open http://localhost:16686
2. Select a service from the "Service" dropdown
3. Click "Find Traces"
4. Click on a trace to see the full request lifecycle across services

### 6.2 Trace Inspection

Each trace shows:

- **Timeline:** How long each service call took
- **Spans:** Individual operations within each service
- **Tags:** HTTP method, status code, DB queries, Kafka operations
- **Logs:** Structured logs emitted during the trace

### 6.3 Useful Trace Searches

| What | How |
|------|-----|
| Slow requests | Service > "Compare" > sort by duration |
| Failed requests | Tag filter: `error=true` |
| Specific trace | Paste `traceId` from logs into Jaeger search |
| Cross-service flow | Search by trace ID to see Gateway -> Service -> DB path |

---

## 7. On-Call Runbook

### 7.1 HighErrorRate (Critical)

**Alert:** `rate(http_server_requests_seconds_count{status=~"5.."}[5m]) > 0.05` for 5 min

**Impact:** Users experiencing 5xx errors.

**Steps:**

1. Open Grafana at http://localhost:3002, check which service has the errors
2. Query Loki for errors: `{service="<affected-service>"} | json | level="ERROR"`
3. Check Jaeger for failed traces at http://localhost:16686
4. If database-related, check PostgreSQL connections: `docker exec postgres psql -U ecommerce -c "SELECT count(*) FROM pg_stat_activity;"`
5. If Kafka-related, check consumer lag in Grafana Kafka dashboard
6. If the service is crashing, restart: `docker compose restart <service>`
7. If it's a code issue, roll back to the previous image tag (see deployment runbook section 4.2)

### 7.2 HighLatency (Warning)

**Alert:** `histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m])) > 0.5` for 5 min

**Impact:** Slow response times, users experiencing degraded performance.

**Steps:**

1. Open Grafana, check which service has high latency
2. Check Jaeger for slow traces — identify the slowest span
3. Common causes:
   - **Slow DB query:** Check `pg_stat_statements` or Jaeger DB spans
   - **Redis cache miss spike:** Check Redis hit rate in Grafana
   - **Kafka consumer lag:** Check consumer group offsets
   - **High JVM GC:** Check Grafana JVM dashboard
4. If it's a specific slow query, consider adding an index
5. If it's resource contention, scale the service: increase replicas or memory

### 7.3 ServiceDown (Critical)

**Alert:** `up == 0` for 1 min

**Impact:** Service is unreachable.

**Steps:**

1. Check which service is down from the alert labels
2. Check container status: `docker compose ps`
3. Check container logs: `docker compose logs <service> --tail=100`
4. Common causes:
   - **OOM killed:** Container exceeded memory limit. Increase memory in `docker-compose.yml`
   - **Health check failing:** Service starts but fails readiness probe
   - **Dependency down:** PostgreSQL, Redis, or Kafka is unreachable
5. Restart the service: `docker compose restart <service>`
6. If dependency is down, restart infrastructure: `make infra`
7. If the container keeps crashing, check application logs for the root cause

### 7.4 KafkaConsumerLag

**Alert:** Consumer group lag exceeds threshold (configure in Prometheus).

**Impact:** Events are not being processed in time (orders not placed, admin dashboard stale).

**Steps:**

1. Check consumer group lag: `docker exec kafka kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group <group-id>`
2. Common causes:
   - **Consumer crashed:** Restart the consuming service
   - **Slow processing:** Check consumer code for blocking operations
   - **Partition imbalance:** Redistribute partitions across consumers
   - **Kafka broker issues:** Check Kafka logs: `docker compose logs kafka --tail=50`
3. If lag is growing, restart the consuming service: `docker compose restart <service>`
4. If Kafka is the issue, restart Kafka: `docker compose restart kafka`
5. Monitor lag recovery in Grafana Kafka dashboard

---

## 8. Disaster Recovery

### 8.1 Backup Schedule

| Component | Method | Frequency | Retention |
|-----------|--------|-----------|-----------|
| PostgreSQL | `pg_dump` | Daily | 30 days |
| Redis | RDB snapshots | Every 6 hours | 7 days |
| Kafka | Topic retention | 7 days | Auto-delete |

### 8.2 Recovery Targets

| Metric | Target |
|--------|--------|
| RTO (Recovery Time Objective) | 1 hour |
| RPO (Recovery Point Objective) | 24 hours |

### 8.3 DR Test Schedule

- **Monthly:** Verify backups can be restored to a test environment
- **Quarterly:** Full DR drill — restore from backup, verify data integrity, measure RTO

### 8.4 Restore Procedure

```bash
# PostgreSQL restore
cat backup-YYYYMMDD.sql | docker exec -i postgres psql -U ecommerce -d ecommerce

# Redis restore (copy RDB file)
docker cp snapshot.rdb redis:/data/dump.rdb
docker compose restart redis

# Full environment restore
make clean
git checkout v{last-known-good}
make dev
# Then restore database from backup
```
