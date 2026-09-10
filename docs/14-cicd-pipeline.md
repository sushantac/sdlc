# CI/CD Pipeline

## 1. Overview

Each of the 7 application repositories (`api-gateway`, `auth-service`, `cart-service`, `product-service`, `order-management-api`, `admin-service`, `e-commerce-frontend`) has its own GitHub Actions workflow. The `sdlc` orchestrator repo has its own workflow for infrastructure/monitoring validation.

---

## 2. Backend Pipeline (per-service)

Every Spring Boot service has `.github/workflows/ci.yml` with these jobs:

### 2.1 Job Structure

```
lint --> unit-tests --> integration-tests --> docker-build (main only)
```

### 2.2 Job Details

#### `lint`

```yaml
runs-on: ubuntu-latest
steps:
  - uses: actions/checkout@v4
  - uses: actions/setup-java@v4
    with:
      java-version: '21'
      distribution: 'temurin'
  - run: ./mvnw checkstyle:check
```

#### `unit-tests`

```yaml
runs-on: ubuntu-latest
needs: lint
steps:
  - uses: actions/checkout@v4
  - uses: actions/setup-java@v4
    with:
      java-version: '21'
      distribution: 'temurin'
  - run: ./mvnw test
```

#### `integration-tests`

```yaml
runs-on: ubuntu-latest
needs: unit-tests
services:
  postgres:
    image: pgvector/pg16
    env:
      POSTGRES_DB: test_db
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
    ports: ['5432:5432']
  redis:
    image: redis:7-alpine
    ports: ['6379:6379']
steps:
  - uses: actions/checkout@v4
  - uses: actions/setup-java@v4
    with:
      java-version: '21'
      distribution: 'temurin'
  - run: ./mvnw verify -P integration
```

#### `docker-build`

```yaml
runs-on: ubuntu-latest
needs: integration-tests
if: github.ref == 'refs/heads/main'
steps:
  - uses: actions/checkout@v4
  - run: docker build -t ${{ github.repository }}:${{ github.sha }} .
  - run: echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
  - run: docker push ${{ secrets.DOCKER_REGISTRY }}/${{ github.repository }}:${{ github.sha }}
```

### 2.3 Triggers

```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
```

---

## 3. Frontend Pipeline (e-commerce-frontend)

### 3.1 Job Structure

```
lint --> unit-tests --> e2e-tests
```

### 3.2 Job Details

#### `lint`

```yaml
runs-on: ubuntu-latest
steps:
  - uses: actions/checkout@v4
  - uses: actions/setup-node@v4
    with:
      node-version: '20'
  - run: npm ci
  - run: npm run lint
```

#### `unit-tests`

```yaml
runs-on: ubuntu-latest
needs: lint
steps:
  - uses: actions/checkout@v4
  - uses: actions/setup-node@v4
  - run: npm ci
  - run: npm run test -- --coverage
```

#### `e2e-tests`

```yaml
runs-on: ubuntu-latest
needs: unit-tests
steps:
  - uses: actions/checkout@v4
  - uses: actions/setup-node@v4
  - run: npm ci
  - run: npx playwright install --with-deps
  - run: npx playwright test
```

---

## 4. Security Pipeline

Runs on every PR and weekly (Monday 6 AM UTC).

### 4.1 Job Details

#### `dependency-check`

```yaml
runs-on: ubuntu-latest
steps:
  - uses: actions/checkout@v4
  - uses: actions/setup-java@v4
    with:
      java-version: '21'
      distribution: 'temurin'
  - run: ./mvnw dependency-check:check
```

#### `snyk`

```yaml
runs-on: ubuntu-latest
steps:
  - uses: actions/checkout@v4
  - uses: snyk/actions/maven@master
    env:
      SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
    with:
      args: --severity-threshold=high
```

### 4.2 Triggers

```yaml
on:
  pull_request:
    branches: [main, develop]
  schedule:
    - cron: '0 6 * * 1'   # Weekly Monday 6am
```

---

## 5. Branch Protection

Required status checks that must pass before merging to `main`:

| Job | Pipeline |
|-----|----------|
| `lint` | Backend or Frontend CI |
| `unit-tests` | Backend or Frontend CI |
| `integration-tests` | Backend CI |
| `e2e-tests` | Frontend CI |

**Branch protection command (per repo):**

```bash
gh api repos/{owner}/{repo}/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["lint","unit-tests","integration-tests"]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"required_approving_review_count":0,"dismiss_stale_reviews":true}' \
  --field restrictions=null
```

---

## 6. Required Secrets

Configure these in each repo's Settings > Secrets and variables > Actions:

| Secret | Used By | Purpose |
|--------|---------|---------|
| `SNYK_TOKEN` | Security pipeline | Snyk dependency scanning |
| `DOCKER_USERNAME` | Backend docker-build | Docker Hub login |
| `DOCKER_PASSWORD` | Backend docker-build | Docker Hub login |
| `DOCKER_REGISTRY` | Backend docker-build | Registry URL (e.g., `docker.io/username`) |

---

## 7. Adding a Pipeline for a New Repo

To add CI/CD for a new service:

1. Create `.github/workflows/ci.yml` in the new repo
2. Copy the backend pipeline template from section 2 above (adjust if the service uses a different build tool)
3. If the service is a Spring Boot app, use the `./mvnw` commands as-is
4. Add the required secrets to the repo
5. Apply branch protection via the `gh api` command in section 5
6. The pipeline will trigger on push/PR to `main` and `develop`

**Checklist for new repos:**

- [ ] `.github/workflows/ci.yml` created
- [ ] `lint` job configured
- [ ] `unit-tests` job configured
- [ ] `integration-tests` job configured (with service containers if needed)
- [ ] `docker-build` job configured (main branch only)
- [ ] Secrets added (`SNYK_TOKEN`, Docker creds)
- [ ] Branch protection applied with `lint`, `unit-tests`, `integration-tests`
