#!/bin/bash

#################################################################################################################################
########################################## MAC Datasource Traces Utils Functions ################################################
#################################################################################################################################

# Adds traces pipeline to OTEL config
# Input:
#   ---
# Output:
#   ---
function add_traces_pipeline_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Adding traces pipeline to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    # Add service section if not exists
    if ! grep -q "^service:" "$OTEL_CONFIG_FILE"; then
        echo "service:" >> "$OTEL_CONFIG_FILE"
    fi

    # Add pipelines section if not exists
    if ! grep -q "^  pipelines:" "$OTEL_CONFIG_FILE"; then
        echo "  pipelines:" >> "$OTEL_CONFIG_FILE"
    fi

    # Add traces pipeline if not exists
    if ! grep -q "^    traces:" "$OTEL_CONFIG_FILE"; then
        cat >> "$OTEL_CONFIG_FILE" << EOT
    traces:
      receivers:
      processors: [batch]
      exporters: [logzio_traces]
EOT
    fi

    # Add traces/metrics pipeline for span metrics connector if not exists
    if ! grep -q "^    traces/metrics:" "$OTEL_CONFIG_FILE"; then
        cat >> "$OTEL_CONFIG_FILE" << EOT
    traces/metrics:
      receivers: [otlp]
      processors: [batch, spanmetrics]
      exporters: [prometheusremotewrite]
EOT
    fi

    message='Added traces pipeline to OTEL config'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
}

# Gets traces OTEL receivers
# Input:
#   ---
# Output:
#   RECEIVERS - Space-separated list of receivers
function get_traces_otel_receivers {
    local func_name="${FUNCNAME[0]}"

    local message='Getting traces OTEL receivers ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    # OTLP receiver is always used for traces
    local receivers="otlp"

    message="Traces OTEL receivers are '$receivers'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "RECEIVERS='$receivers'"
}

# Adds traces receivers to OTEL config
# Input:
#   RECEIVERS - Space-separated list of receivers
#   TRACES_TYPE - Type of traces
# Output:
#   ---
function add_traces_receivers_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local receivers="$RECEIVERS"
    local traces_type="$TRACES_TYPE"

    local message="Adding traces receivers to OTEL config (receivers='$receivers', traces_type='$traces_type') ..."
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    # Add receivers section if not exists
    if ! grep -q "^receivers:" "$OTEL_CONFIG_FILE"; then
        echo "receivers:" >> "$OTEL_CONFIG_FILE"
    fi

    # Add OTLP receiver if not exists
    if ! grep -q "^  otlp:" "$OTEL_CONFIG_FILE"; then
        cat >> "$OTEL_CONFIG_FILE" << EOT
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
EOT
    fi

    # Update service.pipelines.traces.receivers with the receivers list
    local receivers_list="[$(echo "$receivers" | tr ' ' ',')]"
    sed -i '' "/^    traces:/,/^    / s/receivers:.*/receivers: $receivers_list/" "$OTEL_CONFIG_FILE"

    message='Added traces receivers to OTEL config'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
}

# Gets traces OTEL processors
# Input:
#   ---
# Output:
#   PROCESSORS - Space-separated list of processors
function get_traces_otel_processors {
    local func_name="${FUNCNAME[0]}"

    local message='Getting traces OTEL processors ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    # Standard processors for traces
    local processors="batch resource attributes"

    message="Traces OTEL processors are '$processors'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "PROCESSORS='$processors'"
}

# Adds traces processors to OTEL config
# Input:
#   PROCESSORS - Space-separated list of processors
# Output:
#   ---
function add_traces_processors_to_otel_config {
    local func_name="${FUNCNAME[0]}"
    
    local processors="$PROCESSORS"

    local message="Adding traces processors to OTEL config (processors='$processors') ..."
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    # Add processors section if not exists
    if ! grep -q "^processors:" "$OTEL_CONFIG_FILE"; then
        echo "processors:" >> "$OTEL_CONFIG_FILE"
    fi

    # Add batch processor if not exists
    if ! grep -q "^  batch:" "$OTEL_CONFIG_FILE"; then
        cat >> "$OTEL_CONFIG_FILE" << EOT
  batch:
    send_batch_size: 10000
    timeout: 1s
EOT
    fi

    # Add resource processor if not exists
    if ! grep -q "^  resource:" "$OTEL_CONFIG_FILE"; then
        cat >> "$OTEL_CONFIG_FILE" << EOT
  resource:
    attributes:
      - key: service.name
        value: ${HOSTNAME}
      - key: service.version
        value: 1.0.0
EOT
    fi

    # Add attributes processor if not exists
    if ! grep -q "^  attributes:" "$OTEL_CONFIG_FILE"; then
        cat >> "$OTEL_CONFIG_FILE" << EOT
  attributes:
    actions:
      - key: environment
        value: production
        action: insert
EOT
    fi

    # Update service.pipelines.traces.processors with the processors list
    local processors_list="[$(echo "$processors" | tr ' ' ',')]"
    # Use Mac-compatible sed syntax
    sed -i '' "/^    traces:/,/^    / s/processors:.*/processors: $processors_list/" "$OTEL_CONFIG_FILE"

    message='Added traces processors to OTEL config'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
}

# Configures the span metrics connector
# Input:
#   ---
# Output:
#   ---
function configure_span_metrics_connector {
    local func_name="${FUNCNAME[0]}"

    local message='Configuring span metrics connector ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    # Add spanmetrics processor if not exists
    if ! grep -q "^  spanmetrics:" "$OTEL_CONFIG_FILE"; then
        cat >> "$OTEL_CONFIG_FILE" << EOT
  spanmetrics:
    metrics_exporter: prometheusremotewrite
    dimensions:
      - name: service.name
      - name: operation
        default: unknown-operation
    dimensions_cache_size: 1000
    aggregation_temporality: AGGREGATION_TEMPORALITY_CUMULATIVE
EOT
    fi

    message='Configured span metrics connector'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
}

# Adds traces exporter to OTEL config
# Input:
#   TRACES_TOKEN - Logz.io traces token
# Output:
#   ---
function add_traces_exporter_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local traces_token="${TRACES_TOKEN}"

    local message="Adding traces exporter to OTEL config (token='$traces_token') ..."
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    # Add exporters section if not exists
    if ! grep -q "^exporters:" "$OTEL_CONFIG_FILE"; then
        echo "exporters:" >> "$OTEL_CONFIG_FILE"
    fi

    # Add Logz.io traces exporter if not exists
    if ! grep -q "^  logzio_traces:" "$OTEL_CONFIG_FILE"; then
        cat >> "$OTEL_CONFIG_FILE" << EOT
  logzio_traces:
    account_token: ${traces_token}
    region: ${LOGZIO_REGION}
EOT
    fi

    # Update service.pipelines.traces.exporters with logzio_traces
    # Use Mac-compatible sed syntax
    sed -i '' "/^    traces:/,/^    / s/exporters:.*/exporters: [logzio_traces]/" "$OTEL_CONFIG_FILE"
    
    message='Added traces exporter to OTEL config'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
}

# Adds span metrics exporter to OTEL config
# Input:
#   ---
# Output:
#   ---
function add_span_metrics_exporter {
    local func_name="${FUNCNAME[0]}"

    local metrics_token="${METRICS_TOKEN}"

    local message="Adding span metrics exporter to OTEL config (token='$metrics_token') ..."
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    # Add Prometheus Remote Write exporter if not exists
    if ! grep -q "^  prometheusremotewrite:" "$OTEL_CONFIG_FILE"; then
        cat >> "$OTEL_CONFIG_FILE" << EOT
  prometheusremotewrite:
    endpoint: https://listener.logz.io:8053
    headers:
      Authorization: Bearer ${metrics_token}
    resource_to_telemetry_conversion:
      enabled: true
EOT
    fi

    # Update service.pipelines.traces/metrics.exporters with prometheusremotewrite
    # Use Mac-compatible sed syntax
    sed -i '' "/^    traces\/metrics:/,/^    / s/exporters:.*/exporters: [prometheusremotewrite]/" "$OTEL_CONFIG_FILE"
    
    message='Added span metrics exporter to OTEL config'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
}