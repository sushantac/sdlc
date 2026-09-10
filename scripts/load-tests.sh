#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v k6 >/dev/null 2>&1; then
  echo "k6 not installed. Install from https://k6.io/docs/getting-started/installation/"
  exit 1
fi

BASE_URL="${K6_BASE_URL:-http://localhost:8080/api/v1}"

echo "=== Load test: products endpoint (100 VU / 5m) ==="
k6 run -e BASE_URL="$BASE_URL" --vus 100 --duration 5m --summary-export=/tmp/k6-load.json \
  <(cat <<'K6'
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  thresholds: {
    http_req_duration: ['p(95)<200'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const res = http.get(`${__ENV.BASE_URL}/products?page=0&size=20`);
  check(res, { 'status 200': (r) => r.status === 200 });
}
K6
)

echo "=== Stress test: ramp to 500 VU / 10m ==="
k6 run -e BASE_URL="$BASE_URL" --summary-export=/tmp/k6-stress.json \
  <(cat <<'K6'
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 500 },
    { duration: '3m', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'],
  },
};

export default function () {
  const res = http.get(`${__ENV.BASE_URL}/products?page=0&size=20`);
  check(res, { 'status 200': (r) => r.status === 200 });
}
K6
)

echo "Results exported to /tmp/k6-load.json and /tmp/k6-stress.json"