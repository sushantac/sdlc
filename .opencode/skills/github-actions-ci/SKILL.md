---
name: github-actions-ci
description: Create or update a GitHub Actions workflow for an e-commerce repo (Maven or Node). Use when adding CI to a new repo, adding jobs, or fixing pipeline issues.
---

# GitHub Actions CI

Create the CI pipeline for a repo in the e-commerce platform. One file: `.github/workflows/ci.yml`.

## Backend (Maven) workflow

```yaml
name: CI
on:
  push: { branches: [main, develop] }
  pull_request: { branches: [main, develop] }

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21', distribution: 'temurin', cache: maven }
      - run: ./mvnw checkstyle:check spotbugs:check

  unit-tests:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21', distribution: 'temurin', cache: maven }
      - run: ./mvnw test

  integration-tests:
    runs-on: ubuntu-latest
    needs: unit-tests
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21', distribution: 'temurin', cache: maven }
      - run: ./mvnw verify
```

Cache Maven with `cache: maven`; Node with `cache: npm` + `npm ci`.

## Frontend (Node) workflow

```yaml
jobs:
  lint:
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: npm }
      - run: npm ci
      - run: npm run lint
  unit-tests:
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: npm }
      - run: npm ci
      - run: npm test -- --coverage
  e2e-tests:
    needs: unit-tests
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: npm }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npx playwright test
```

## Rules
- One workflow file per repo; jobs gated with `needs:` and correct naming keys used in branch protection
- Branch protection contexts must match job names (`lint`, `unit-tests`, `integration-tests`)
- Never inline secrets; `${{ secrets.X }}` only
- Verify YAML parses (CI will fail on bad YAML, so validate before pushing)