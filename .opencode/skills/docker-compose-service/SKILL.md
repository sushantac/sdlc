---
name: docker-compose-service
description: Add or update a service definition in the orchestrator docker-compose.yml with profiles, healthchecks, and depends_on. Use when wiring a new service into the platform compose file or changing service config.
---

# Docker Compose Service

Add or modify a service in `/Users/sushant/Projects/Library/sdlc/docker-compose.yml`.

## Rules

- Compose schema `3.8+`; every app/infra service pinned to an explicit version tag (never `latest`)
- All e-commerce app services build from `../{repo}`
- Profiling: app services belong to `backend` and `full`; tooling (plane/bookstack/penpot) to `sdlc`/`design`; monitoring to `monitoring`; QA tools to `qa`
- Healthchecks required on every long-running service + several app services:

```yaml
healthcheck:
  test: ["CMD-SHELL", "curl -fsS http://localhost:{port}/actuator/health || exit 1"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s
```

- `depends_on` uses `condition: service_healthy` for postgres/redis, `service_started` for kafka/app deps
- Inter-service DNS uses the compose service name (`postgres`, `kafka`, `auth-service`, ...). Kafka advertises `kafka:9092` for consumers
- Expose only host-required ports; use internal network otherwise
- Environment variables come from `.env` (see `.env.example`); no secrets inline
- Volumes `-v` named persistent volumes; add any new volume to the top-level `volumes:` block

## Checklist before finishing
- `docker compose config` parses without warnings
- New volume declared; new port documented in README/plan if host-visible
- Startup order sensible (deps before dependents)