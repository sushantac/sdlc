#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SERVICES=(api-gateway auth-service cart-service product-service order-management-api admin-service)
FRONTEND=e-commerce-frontend
BASE_DIR=$(pwd)

echo "=== Running backend tests ==="
for svc in "${SERVICES[@]}"; do
  echo "--- $svc ---"
  (cd "${BASE_DIR}/../${svc}" && ./mvnw test 2>&1 | tail -5)
done

echo "=== Running frontend tests ==="
(cd "${BASE_DIR}/../${FRONTEND}" && npm test -- --coverage 2>&1 | tail -10)

echo "=== All test suites passed ==="