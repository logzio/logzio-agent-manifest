#!/bin/bash

#################################################################################################################################
############################################# MAC Datasource Traces Utils Functions ############################################
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
}

# Gets traces OTEL receivers
# Input:
#   ---
# Ouput:
#   TRACES_OTEL_RECEIVERS - List of traces OTEL receiver names
function get_traces_otel_receivers {
    local func_name="${FUNCNAME[0]}"

    local message='Getting traces OTEL receivers ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    get_json_str_field_value_list "$TRACES_TELEMETRY" '.otel.receivers[]'
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
        return $EXIT_CODE
    fi

    local traces_otel_receivers=("${JSON_VALUE[@]}")

    message="Traces OTEL receivers are '${traces_otel_receivers[@]}'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    LIST=("${traces_otel_receivers[@]}")
    local traces_otel_receivers_str=$(convert_list_to_str)
    write_task_post_run "TRACES_OTEL_RECEIVERS=$traces_otel_receivers_str"
}

# Adds traces receivers to OTEL config
# Input:
#   ---
# Output:
#   ---
function add_traces_receivers_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Adding traces receivers to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    for traces_otel_receiver in "${TRACES_OTEL_RECEIVERS[@]}"; do
        get_yaml_file_field_value "$OTEL_RECEIVERS_DIR/$traces_otel_receiver.yaml" '.mac_run'
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
            return $EXIT_CODE
        fi

        local script_block="$YAML_VALUE"

        echo -e "$script_block" >"$OTEL_FUNCTION_FILE"
        source "$OTEL_FUNCTION_FILE" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): error loading '$traces_otel_receiver' OTEL function script: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
            return $EXIT_CODE
        fi

        create_otel_receiver
        local func_status=$?
        if [[ $func_status -ne 0 && $func_status -ne 1 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
            return $EXIT_CODE
        fi
        if [[ $func_status -ne 0 ]]; then
            message="$(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_log "$LOG_LEVEL_DEBUG" "$message"
            continue
        fi

        add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_RECEIVERS_DIR/$traces_otel_receiver.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.receiver' '.receivers'
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
            return $EXIT_CODE
        fi

        local receiver_name="${traces_otel_receiver//_//}"
        if [[ "$receiver_name" == "otlp" ]]; then
          add_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.service.pipelines.traces.receivers' "$receiver_name"
          if [[ $? -ne 0 ]]; then
              message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
              send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
              write_task_post_run "write_error \"$message\""
              return $EXIT_CODE
          fi
          continue
        fi

        add_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.service.pipelines.traces.receivers' "$receiver_name/NAME"
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
            return $EXIT_CODE
        fi
    done

    sed -i '' "s@NAME@${PLATFORM,,}_${SUB_TYPE,,}_${CURRENT_DATA_SOURCE,,}@g" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
        return $EXIT_CODE
    fi
}

# Gets traces OTEL processors
# Input:
#   ---
# Ouput:
#   TRACES_OTEL_PROCESSORS - List of traces OTEL processor names
function get_traces_otel_processors {
    local func_name="${FUNCNAME[0]}"

    local message='Getting traces OTEL processors ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    get_json_str_field_value_list "$TRACES_TELEMETRY" '.otel.processors[]'
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
        return $EXIT_CODE
    fi

    local traces_otel_processors=("${JSON_VALUE[@]}")

    message="Traces OTEL processors are '${traces_otel_processors[@]}'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    LIST=("${traces_otel_processors[@]}")
    local traces_otel_processors_str=$(convert_list_to_str)
    write_task_post_run "TRACES_OTEL_PROCESSORS=$traces_otel_processors_str"
}

# Adds traces processors to OTEL config
# Input:
#   ---
# Output:
#   ---
function add_traces_processors_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Adding traces processors to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local exists_processors
    local is_exists_processors_empty=false

    get_yaml_file_field_value_list "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.processors'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
        return $EXIT_CODE
    fi
    if [[ $func_status -ne 0 ]]; then
        exists_processors=()
        is_exists_processors_empty=true
    fi

    if ! $is_exists_processors_empty; then
        get_yaml_file_field_value_list "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.processors | keys'
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
            return $EXIT_CODE
        fi
        exists_processors=("${YAML_VALUE[@]}")
    fi
    local existing_processors="$YAML_VALUE"
    # Add tail_sampling proccessor if not exists
    if [[ ! "$existing_processors" =~ "tail_sampling" ]]; then
        add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_PROCESSORS_DIR/tail_sampling.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.processors'
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
            return $EXIT_CODE
        fi
    fi
    add_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.service.pipelines.traces.processors' 'tail_sampling'
    if [[ $? -ne 0 ]]; then
          message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
          send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
          write_task_post_run "write_error \"$message\""
          return $EXIT_CODE
      fi

    for traces_otel_processor in "${TRACES_OTEL_PROCESSORS[@]}"; do
        local processor_name="${traces_otel_processor//_//}"

        add_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.service.pipelines.traces.processors' $processor_name
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
            return $EXIT_CODE
        fi

        local is_processor_exists=false
        for exists_processor in "${exists_processors[@]}"; do
            exists_processor="${exists_processor////_}"
            if [[ "$traces_otel_processor" == "- $exists_processor" ]]; then
                is_processor_exists=true
                break
            fi
        done
        if $is_processor_exists; then
            continue
        fi

        add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_PROCESSORS_DIR/$traces_otel_processor.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.processors'
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
            return $EXIT_CODE
        fi

        if [[ $processor_name == 'resource/agent' ]]; then
            AGENT_VERSION=$(cat '/tmp/logzio/version')
            add_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.processors.resource/agent.attributes[0].value' "$AGENT_VERSION"
        fi
    done
}

# Adds traces exporter to OTEL config
# Input:
#   ---
# Output:
#   ---
function add_traces_exporter_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Adding traces exporter to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local exists_exporters
    local is_exists_exporters_empty=false

    get_yaml_file_field_value_list "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.exporters'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
        return $EXIT_CODE
    fi
    if [[ $func_status -ne 0 ]]; then
        exists_exporters=()
        is_exists_exporters_empty=true
    fi

    if ! $is_exists_exporters_empty; then
        get_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.exporters | keys'
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
            return $EXIT_CODE
        fi
        exists_exporters=("${YAML_VALUE[@]}")
    fi

    for exists_exporter in "${exists_exporters[@]}"; do
        if [[ "$exists_exporter" == '- logzio_traces' ]]; then
            return
        fi
    done

    set_yaml_file_field_value "$OTEL_EXPORTERS_DIR/logzio_traces.yaml" '.logzio/traces.account_token' "$TRACES_TOKEN"
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
        return $EXIT_CODE
    fi
    set_yaml_file_field_value "$OTEL_EXPORTERS_DIR/logzio_logs.yaml" '.logzio/logs.headers.user-agent' "$USER_AGENT_LOGS"

    set_yaml_file_field_value "$OTEL_EXPORTERS_DIR/logzio_traces.yaml" '.logzio/traces.headers.user-agent' "$USER_AGENT_TRACES"
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
        return $EXIT_CODE
    fi

    local logzio_region=$(get_logzio_region "$LISTENER_URL")
    message="Logz.io region is '$logzio_region'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    set_yaml_file_field_value "$OTEL_EXPORTERS_DIR/logzio_traces.yaml" '.logzio/traces.region' "$logzio_region"
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
        return $EXIT_CODE
    fi

    add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_EXPORTERS_DIR/logzio_traces.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.exporters'
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
        return $EXIT_CODE
    fi
}

#################################################################################################################################
########################################### SPAN METRICS (TRACES) UTILS ########################################################
#################################################################################################################################

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

    # Add spanmetrics connector from the template file
    add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_RESOURCES_DIR/connectors/spanmetrics.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.connectors'
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
        return $EXIT_CODE
    fi
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

    if [[ ! "$existing_processors" =~ "metricstransform/labels-rename" ]]; then
        add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_PROCESSORS_DIR/metricstransform_labels-rename.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.processors'
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
            return $EXIT_CODE
        fi
    fi
        if [[ ! "$existing_processors" =~ "batch" ]]; then
        add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_PROCESSORS_DIR/batch.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.processors'
        if [[ $? -ne 0 ]]; then
            message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
            return $EXIT_CODE
        fi
    fi
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

    get_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.exporters | keys'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
        return $EXIT_CODE
    fi
    local existing_exporters="$YAML_VALUE"
    echo "Existing exporters: $existing_exporters"

    if [[ ! "$existing_exporters" =~ "prometheusremotewrite" ]]; then
        local listener_host=$(echo "https://$listener_url" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
        local endpoint="$listener_host:8053"

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
}