#!/bin/bash

#################################################################################################################################
######################################### mac Datasource Traces Utils Functions ###############################################
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

    add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_RESOURCES_DIR/traces_pipeline.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.service.pipelines'
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
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
    get_yaml_file_field_value_list "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.receivers'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    if [[ $func_status -ne 0 ]]; then
        echo 'receivers:' >> "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME"
    fi

    # Add OTLP receiver if not exists
    get_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.receivers.otlp'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    if [[ $func_status -ne 0 ]]; then
        cat >> "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" << EOT
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
EOT
    fi

    # Convert space-separated string to array
    IFS=' ' read -ra receivers_arr <<< "$receivers"

    # Update service.pipelines.traces.receivers with the receivers list
    local receivers_list="[$(echo "$receivers" | tr ' ' ',')]"
    set_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.service.pipelines.traces.receivers' "$receivers_list"
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    # Update service.pipelines.traces/metrics.receivers with the receivers list
    set_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.service.pipelines."traces/metrics".receivers' "$receivers_list"
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

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
    get_yaml_file_field_value_list "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.processors'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    if [[ $func_status -ne 0 ]]; then
        echo 'processors:' >> "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME"
    fi

    # Add batch processor if not exists
    get_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.processors.batch'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    if [[ $func_status -ne 0 ]]; then
        cat >> "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" << EOT
  batch:
    send_batch_size: 10000
    timeout: 1s
EOT
    fi

    # Add resource processor if not exists
    get_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.processors.resource'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    if [[ $func_status -ne 0 ]]; then
        cat >> "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" << EOT
  resource:
    attributes:
      - key: service.name
        value: ${HOSTNAME}
      - key: service.version
        value: 1.0.0
EOT
    fi

    # Add attributes processor if not exists
    get_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.processors.attributes'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    if [[ $func_status -ne 0 ]]; then
        cat >> "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" << EOT
  attributes:
    actions:
      - key: environment
        value: production
        action: insert
EOT
    fi

    # Convert space-separated string to array
    IFS=' ' read -ra processors_arr <<< "$processors"

    # Update service.pipelines.traces.processors with the processors list
    local processors_list="[$(echo "$processors" | tr ' ' ',')]"
    set_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.service.pipelines.traces.processors' "$processors_list"
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    message='Added traces processors to OTEL config'
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
    get_yaml_file_field_value_list "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.exporters'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    if [[ $func_status -ne 0 ]]; then
        echo 'exporters:' >> "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME"
    fi

    # Add Logz.io traces exporter if not exists
    get_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.exporters.logzio_traces'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    if [[ $func_status -ne 0 ]]; then
        cat >> "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" << EOT
  logzio_traces:
    account_token: ${traces_token}
    region: ${LOGZIO_REGION}
EOT
    fi

    # Update service.pipelines.traces.exporters with logzio_traces
    local traces_exporters="[logzio_traces]"
    set_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.service.pipelines.traces.exporters' "$traces_exporters"
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    message='Added traces exporter to OTEL config'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
}


# Adds spanmetrics pipeline to OTEL config
# Input:
#   ---
# Output:
#   ---
function add_spanmetrics_pipeline_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Adding span metrics pipeline to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    # Add traces/spanmetrics pipeline
    add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_RESOURCES_DIR/spanmetricstraces_pipeline.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.service.pipelines'
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    # Add metrics/spanmetrics pipeline
    add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_RESOURCES_DIR/spanmetrics_pipeline.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.service.pipelines'
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    message='Added span metrics pipeline to OTEL config'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
}

# Adds spanmetrics connector to OTEL config
# Input:
#   ---
# Output:
#   ---
function add_spanmetrics_connector_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Adding span metrics connector to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    # Add connectors section if not exists
    get_yaml_file_field_value_list "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.connectors'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    if [[ $func_status -ne 0 ]]; then
        echo 'connectors:' >> "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME"
    fi

    # Add spanmetrics connector from the connector template file
    add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_RESOURCES_DIR/connectors/spanmetrics.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.connectors'
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    message='Added span metrics connector to OTEL config'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
}

# Adds spanmetrics processors to OTEL config
# Input:
#   ---
# Output:
#   ---
function add_spanmetrics_processors_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Adding span metrics processors to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    # Add processors section if not exists
    get_yaml_file_field_value_list "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.processors'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    if [[ $func_status -ne 0 ]]; then
        echo 'processors:' >> "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME"
    fi

    # Get existing processors
    get_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.processors | keys'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    local existing_processors="$YAML_VALUE"

    # Add batch processor if not exists
    if [[ ! "$existing_processors" =~ "batch" ]]; then
        add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_PROCESSORS_DIR/batch.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.processors'
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi
    fi

    # Add metricstransform/metrics-rename processor if not exists
    if [[ ! "$existing_processors" =~ "metricstransform/metrics-rename" ]]; then
        add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_PROCESSORS_DIR/metricstransform_metrics-rename.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.processors'
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi
    fi

    # Add metricstransform/labels-rename processor if not exists
    if [[ ! "$existing_processors" =~ "metricstransform/labels-rename" ]]; then
        add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_PROCESSORS_DIR/metricstransform_labels-rename.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.processors'
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi
    fi

    message='Added span metrics processors to OTEL config'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
}

# Adds spanmetrics exporter to OTEL config
# Input:
#   ---
# Output:
#   ---
function add_spanmetrics_exporter_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local metrics_token="${METRICS_TOKEN}"
    local listener_url="${LISTENER_URL}"

    local message="Adding span metrics exporter to OTEL config ..."
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    # Add exporters section if not exists
    get_yaml_file_field_value_list "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.exporters'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    if [[ $func_status -ne 0 ]]; then
        echo 'exporters:' >> "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME"
    fi

    # Get existing exporters
    get_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.exporters | keys'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    local existing_exporters="$YAML_VALUE"

    # Check if prometheusremotewrite exporter exists
    if [[ ! "$existing_exporters" =~ "prometheusremotewrite" ]]; then
        # Extract listener host from URL
        local listener_host=$(echo "$listener_url" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
        local endpoint="https://$listener_host:8053"

        # Configure Prometheusremotewrite exporter
        set_yaml_file_field_value "$OTEL_EXPORTERS_DIR/prometheusremotewrite.yaml" '.prometheusremotewrite.endpoint' "$endpoint"
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi

        local auth_header="Bearer $metrics_token"
        set_yaml_file_field_value "$OTEL_EXPORTERS_DIR/prometheusremotewrite.yaml" '.prometheusremotewrite.headers.Authorization' "$auth_header"
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi

        add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_EXPORTERS_DIR/prometheusremotewrite.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.exporters'
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi
    fi

    message='Added span metrics exporter to OTEL config'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
}