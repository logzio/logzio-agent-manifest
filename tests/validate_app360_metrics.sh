#!/usr/bin/env bash
set -e

REQUIRED_METRICS=("calls_total" "latency_sum" "latency_count")
REQUIRED_LABELS=("service_name" "operation" "env_id" "status_code")
LOGZIO_API_URL="https://api.logz.io/metrics/prometheus/api/v1/query"
API_TOKEN="${LOGZIO_METRICS_API_KEY}"
ENV_ID="${ENV_ID}"

fail=0

for metric in "${REQUIRED_METRICS[@]}"; do
  query="${metric}{env_id=\"${ENV_ID}\"}"
  response=$(curl -s -H "X-API-TOKEN: ${API_TOKEN}" -H "Accept: application/json" "${LOGZIO_API_URL}?query=$(echo "$query" | jq -sRr @uri)")
  found=$(echo "$response" | jq -r '.data.result | length')
  if [[ "$found" -eq 0 ]]; then
    echo "❌ Metric $metric not found for env_id $ENV_ID"
    fail=1
    continue
  fi
  for label in "${REQUIRED_LABELS[@]}"; do
    has_label=$(echo "$response" | jq -r --arg label "$label" '.data.result[].metric | has($label)')
    if ! echo "$has_label" | grep -q "true"; then
      echo "❌ Metric $metric missing label $label"
      fail=1
    fi
  done
  echo "✅ Metric $metric found with all required labels for env_id $ENV_ID"
done

if [[ "$fail" -eq 1 ]]; then
  echo "❌ App360 prerequisites test failed"
  exit 1
else
  echo "✅ All App360 prerequisite metrics and labels found"
fi
