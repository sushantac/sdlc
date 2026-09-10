#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== Dependency scan (mvn dependency-check) ==="
for svc in api-gateway auth-service cart-service product-service admin-service; do
  echo "--- $svc ---"
  (cd "../${svc}" && ./mvnw org.owasp:dependency-check-maven:check \
    -DskipProvidedScope -DfailBuildOnCVSS=7 2>&1 | tail -3) || \
    echo "  -> dependency-check failed for $svc (see report)"
done

echo "=== npm audit (frontend) ==="
(cd "../e-commerce-frontend" && npm audit --audit-level=high)

echo "=== ZAP active scan (if zap running on :8090) ==="
if curl -fsS http://localhost:8090 >/dev/null 2>&1; then
  echo "Launching ZAP scan against local gateway..."
  curl -fsS -X POST "http://localhost:8090/JSON/ascan/action/scan" \
    -d "url=http://localhost:8080/api/v1/products?page=0&size=5" >/dev/null || echo "  -> ZAP scan request failed"
else
  echo "  -> ZAP not running (start with 'make qa'); skipping"
fi

echo "=== Security scan complete ==="