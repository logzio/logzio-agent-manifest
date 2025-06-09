#!/usr/bin/env bash
set -e

REQUIRED_METRICS=("calls_total" "latency_sum" "latency_count")
REQUIRED_LABELS=("service_name" "operation" "env_id" "status_code")
LOGZIO_API_URL="https://api.logz.io/v1/metrics/prometheus/api/v1/query"
API_TOKEN="${LOGZIO_METRICS_API_KEY}"
ENV_ID="${ENV_ID}"

fail=0

# Query all metrics for this env_id in a single API call
QUERY="{env_id=\"${ENV_ID}\"}"
RESPONSE=$(curl -s -H "X-API-TOKEN: ${API_TOKEN}" -H "Accept: application/json" "${LOGZIO_API_URL}?query=$(echo "$QUERY" | jq -sRr @uri)")
echo "Response from Logz.io API:"
echo "$RESPONSE" | jq .
# Build a map of metric name to its label sets
mapfile -t METRIC_NAMES < <(echo "$RESPONSE" | jq -r '.data.result[].metric.__name__' | sort -u)

for metric in "${REQUIRED_METRICS[@]}"; do
  found=0
  for i in "${!METRIC_NAMES[@]}"; do
    if [[ "${METRIC_NAMES[$i]}" == "$metric" ]]; then
      found=1
      # For each result with this metric, check labels
      mapfile -t LABELS_ARRAY < <(echo "$RESPONSE" | jq -c --arg name "$metric" '.data.result[] | select(.metric.__name__ == $name) | .metric')
      for labels_json in "${LABELS_ARRAY[@]}"; do
        missing_label=0
        for label in "${REQUIRED_LABELS[@]}"; do
          if ! echo "$labels_json" | jq -e --arg l "$label" 'has($l)' > /dev/null; then
            echo "❌ Metric $metric missing label $label in one of the series"
            fail=1
            missing_label=1
          fi
        done
        if [[ $missing_label -eq 0 ]]; then
          echo "✅ Metric $metric found with all required labels for env_id $ENV_ID"
        fi
      done
    fi
  done
  if [[ $found -eq 0 ]]; then
    echo "❌ Metric $metric not found for env_id $ENV_ID"
    fail=1
  fi
  # If found but no series had all labels, already marked as fail above
  # If found and at least one series had all labels, success message already printed
  # If not found, fail message above
  # Continue to next metric
  done

echo
if [[ "$fail" -eq 1 ]]; then
  echo "❌ App360 prerequisites test failed"
  exit 1
else
  echo "✅ All App360 prerequisite metrics and labels found"
fi
