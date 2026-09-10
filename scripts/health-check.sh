#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

URL="${HEALTHCHECK_URL:-http://localhost:8080/actuator/health}"
TIMEOUT="${HEALTHCHECK_TIMEOUT:-60}"

echo "=== Health check aggregation ==="
echo "Gateway: ${URL}"
echo ""

# The gateway health endpoint aggregates downstream when configured with
# ReactiveDiscoveryClient or a composite health indicator.
for i in $(seq 1 "$TIMEOUT"); do
  if response=$(curl -fsS -m 2 "$URL" 2>/dev/null); then
    echo "Gateway healthy:"
    echo "${response}" | python3 -m json.tool 2>/dev/null || echo "${response}"
    exit 0
  fi
  sleep 1
done

echo "Gateway never became healthy within ${TIMEOUT}s" >&2
exit 1