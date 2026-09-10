# Deployment Runbook

## 1. Build & Release Process

### 1.1 Versioning

| Component | Strategy | Format |
|-----------|----------|--------|
| Services | Semantic Versioning | `v1.2.3` |
| API | URL versioning | `/api/v1/`, `/api/v2/` |
| Docker images | Git SHA + semver | `auth-service:abc1234` |
| Database | Sequential Liquibase migrations | `V100__`, `V101__` |
| Kafka topics | Service prefix | `auth.user.registered` |

### 1.2 Branch Flow

```
feature/* --> develop --> release/v* --> main
                   \                   /
                    \----- merge ----/
```

1. Feature branches merge to `develop`
2. Create `release/v{version}` from `develop`
3. Bump version in all affected services
4. Update `CHANGELOG.md`
5. Create GitHub Release with tag
6. CI builds and pushes Docker images tagged with git SHA + semver
7. Deploy to staging, smoke test
8. Deploy to production
9. Merge release branch back to `main` + `develop`

### 1.3 Docker Image Tags

Images are tagged with both the git SHA and the semantic version:

```
auth-service:abc1234
auth-service:v1.2.3
auth-service:latest     # only on main branch
```

---

## 2. Deploy Steps

### 2.1 Build All Services

```bash
cd sdlc
make build
```

This runs:
- Backend: `./mvnw clean package -DskipTests` for each of the 6 services
- Frontend: `npm run build`

### 2.2 Start Services

```bash
# Backend only (infrastructure + 6 backend services + frontend)
make dev

# Full stack (all 23 containers)
make dev-full

# Infrastructure only (for deploying built images manually)
make infra
```

To deploy specific Docker Compose profiles:

```bash
docker compose --profile backend up --build
docker compose --profile monitoring up
docker compose --profile sdlc up
docker compose --profile qa up
docker compose --profile design up
docker compose --profile full up
```

### 2.3 Health Verification

After deployment, verify all services are healthy:

```bash
bash scripts/health-check.sh
```

This polls the API Gateway's actuator health endpoint at `http://localhost:8080/actuator/health` for up to 60 seconds (configurable via `HEALTHCHECK_TIMEOUT`). The gateway aggregates downstream service health.

### 2.4 Manual Service Health Checks

If the aggregated check fails, probe individual services:

```bash
curl -fsS http://localhost:8080/actuator/health   # API Gateway
curl -fsS http://localhost:8081/actuator/health   # Auth Service
curl -fsS http://localhost:8082/actuator/health   # Cart Service
curl -fsS http://localhost:8083/actuator/health   # Product Service
curl -fsS http://localhost:8084/actuator/health   # Order API
curl -fsS http://localhost:8085/actuator/health   # Admin Service
```

---

## 3. Smoke Test Checklist

After deploying to any environment, verify:

| # | Check | Command / Action |
|---|-------|-----------------|
| 1 | All services report healthy | `bash scripts/health-check.sh` |
| 2 | Frontend loads in browser | Open `http://localhost:3000` |
| 3 | Login works | POST `http://localhost:8080/api/v1/auth/login` with test credentials |
| 4 | Product listing returns data | `curl http://localhost:8080/api/v1/products?page=0&size=5` |
| 5 | Kafka topics exist | `docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list` |
| 6 | Database schemas created | `docker exec postgres psql -U ecommerce -d ecommerce -c "\dn"` |
| 7 | Prometheus targets up | Open `http://localhost:9090/targets` |
| 8 | Grafana dashboards load | Open `http://localhost:3002` |
| 9 | Jaeger traces present | Open `http://localhost:16686`, search for any service |
| 10 | No 5xx errors in logs | Check Grafana Loki or `docker compose logs --tail=50` |

---

## 4. Rollback Procedure

### 4.1 Application Rollback

Roll back to a previous Docker image version:

```bash
# Find the previous image tag
docker images auth-service --format "{{.Tag}}"

# Update docker-compose.yml to use the previous tag for the affected services:
#   image: auth-service:<previous-git-sha>

# Restart
docker compose --profile backend up -d
```

### 4.2 Database Rollback (Liquibase)

Liquibase manages all schema migrations. To roll back a migration:

```bash
# Connect to the database
docker exec -it postgres psql -U ecommerce -d ecommerce

# Rollback the last N changesets
# Option 1: Use Liquibase rollback command from the service
cd ../auth-service
./mvnw liquibase:rollback -Dliquibase.rollbackCount=1

# Option 2: Manually undo (if rollback SQL was not pre-written)
# Liquibase tracks executed changesets in DATABASECHANGELOG table
# Delete the last entry and manually reverse the schema change
```

**Important:** Only roll back migrations that are backward-compatible. If a rollback would lose data, restore from backup first (see section 5).

### 4.3 Full Stack Rollback

If the entire deployment is broken:

```bash
cd sdlc

# Stop everything
make clean

# Checkout the previous release tag
git checkout v{previous-version}

# Rebuild and restart
make dev
```

---

## 5. Database Backup & Restore

### 5.1 Backup

Daily PostgreSQL backups are managed via `pg_dump`:

```bash
# Manual backup
docker exec postgres pg_dump -U ecommerce ecommerce > backup-$(date +%Y%m%d).sql

# List existing backups
docker exec postgres pg_dump -U ecommerce ecommerce | wc -l
```

### 5.2 Restore

```bash
# Restore from backup file
cat backup-20260910.sql | docker exec -i postgres psql -U ecommerce -d ecommerce
```

### 5.3 Backup Schedule

| Component | Method | Frequency | Retention |
|-----------|--------|-----------|-----------|
| PostgreSQL | `pg_dump` | Daily | 30 days |
| Redis | RDB snapshots | Every 6 hours | 7 days |
| Kafka | Topic retention | 7 days | Auto-delete |

### 5.4 Recovery Targets

| Metric | Target |
|--------|--------|
| RTO (Recovery Time Objective) | 1 hour |
| RPO (Recovery Point Objective) | 24 hours |
