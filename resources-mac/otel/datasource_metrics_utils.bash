#!/bin/bash

#################################################################################################################################
########################################## MAC Datasource Metrics Utils Functions ###############################################
#################################################################################################################################

# Adds metrics pipeline to OTEL confing
# Input:
#   ---
# Output:
#   ---
function add_metrics_pipline_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Adding metrics pipeline to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_RESOURCES_DIR/metrics_pipeline.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.service.pipelines'
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
}

# Gets metrics OTEL receivers
# Input:
#   ---
# Ouput:
#   METRICS_OTEL_RECEIVERS - List of Metrics OTEL receiver names
function get_metrics_otel_receivers {
    local func_name="${FUNCNAME[0]}"

    local message='Adding metrics pipeline to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    get_json_str_field_value_list "$METRICS_TELEMETRY" '.otel.receivers[]'
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local metrics_otel_receivers=("${JSON_VALUE[@]}")

    message="Metrics OTEL receivers are '${metrics_otel_receivers[@]}'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    LIST=("${metrics_otel_receivers[@]}")
    local metrics_otel_receivers_str=$(convert_list_to_str)
    write_task_post_run "METRICS_OTEL_RECEIVERS=$metrics_otel_receivers_str"
}

# Adds metrics receivers to OTEL config
# Input:
#   ---
# Output:
#   ---
function add_metrics_receivers_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Adding metrics receivers to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    for metrics_otel_receiver in "${METRICS_OTEL_RECEIVERS[@]}"; do
        get_yaml_file_field_value "$OTEL_RECEIVERS_DIR/$metrics_otel_receiver.yaml" '.mac_run'
        if [[ $? -ne 0 ]]; then
            message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi

        local script_block="$YAML_VALUE"

        echo -e "$script_block" >"$OTEL_FUNCTION_FILE"
        source "$OTEL_FUNCTION_FILE" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="metrics.bash ($EXIT_CODE): error loading '$metrics_otel_receiver' OTEL function script: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi

        create_otel_receiver
        local func_status=$?
        if [[ $func_status -ne 0 && $func_status -ne 1 ]]; then
            message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi
        if [[ $func_status -ne 0 ]]; then
            message="$(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_log "$LOG_LEVEL_DEBUG" "$message"

            continue
        fi

        add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_RECEIVERS_DIR/$metrics_otel_receiver.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.receiver' '.receivers'
        if [[ $? -ne 0 ]]; then
            message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi

        local receiver_name="${metrics_otel_receiver//_//}"

        add_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.service.pipelines.metrics.receivers' "$receiver_name/NAME"
        if [[ $? -ne 0 ]]; then 
            message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi
    done

    sed -i '' "s@NAME@${PLATFORM,,}_${SUB_TYPE,,}_${CURRENT_DATA_SOURCE,,}@g" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi
}

# Gets metrics OTEL processors
# Input:
#   ---
# Ouput:
#   METRICS_OTEL_PROCESSORS - List of metrics OTEL processor names
function get_metrics_otel_processors {
    local func_name="${FUNCNAME[0]}"

    local message='Getting metrics OTEL processors ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    get_json_str_field_value_list "$METRICS_TELEMETRY" '.otel.processors[]'
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi

    local metrics_otel_processors=("${JSON_VALUE[@]}")

    message="Metrics OTEL processors are '${metrics_otel_processors[@]}'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    LIST=("${metrics_otel_processors[@]}")
    local metrics_otel_processors_str=$(convert_list_to_str)
    write_task_post_run "METRICS_OTEL_PROCESSORS=$metrics_otel_processors_str"
}

# Adds metrics processors to OTEL config
# Input:
#   ---
# Output:
#   ---
function add_metrics_processors_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Adding metrics processors to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local exists_processors
    local is_exists_processors_empty=false

    get_yaml_file_field_value_list "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.processors'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
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
            message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi

        exists_processors=("${YAML_VALUE[@]}")
    fi
    
    for metrics_otel_processor in "${METRICS_OTEL_PROCESSORS[@]}"; do
        local processor_name="${metrics_otel_processor//_//}"

        add_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.service.pipelines.metrics.processors' "$processor_name"
        if [[ $? -ne 0 ]]; then
            message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi

        local is_processor_exists=false

        for exists_processor in "${exists_processors[@]}"; do
            exists_processor="${exists_processor////_}"

            if [[ "$metrics_otel_processor" == "- $exists_processor" ]]; then
                is_processor_exists=true
                break
            fi
        done

        if $is_processor_exists; then
            continue
        fi

        add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_PROCESSORS_DIR/$metrics_otel_processor.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.processors'
        if [[ $? -ne 0 ]]; then
            message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi
    done
}

# Adds metrics exporter to OTEL config
# Input:
#   ---
# Output:
#   ---
function add_metrics_exporter_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Adding metrics exporter to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local exists_exporters
    local is_exists_exporters_empty=false

    get_yaml_file_field_value_list "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.exporters'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
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
            message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi

        exists_exporters=("${YAML_VALUE[@]}")
    fi

    for $exists_exporter in $exists_exporers; do
        if [[ "$exists_exporter" == '- prometheusremotewrite' ]]; then
            return
        fi
    done

    set_yaml_file_field_value "$OTEL_EXPORTERS_DIR/prometheusremotewrite.yaml" '.prometheusremotewrite.endpoint' "https://$LISTENER_URL:8053"
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi

    set_yaml_file_field_value "$OTEL_EXPORTERS_DIR/prometheusremotewrite.yaml" '.prometheusremotewrite.headers.Authorization' "Bearer $METRICS_TOKEN"
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi

    set_yaml_file_field_value "$OTEL_EXPORTERS_DIR/prometheusremotewrite.yaml" '.prometheusremotewrite.headers.user-agent' "Bearer $USER_AGENT_METRICS"
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi

    add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_EXPORTERS_DIR/prometheusremotewrite.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.exporters'
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi
}

# Sets metrics address to OTEL config
# Input:
#   ---
# Output:
#   ---
function set_metrics_address_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Setting metrics address to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local port=8888
    local result=$(lsof -i -n -P | grep "TCP" | grep "LISTEN" | grep "127.0.0.1:$port")

    if [[ ! -z "$result" ]]; then
        while true; do
            ((port++))
            result=$(lsof -i -n -P | grep "TCP" | grep "LISTEN" | grep "127.0.0.1:$port")
            if [[ -z "$result" ]]; then
                break
            fi
        done
    fi

    local address="localhost:$port"

    set_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.service.telemetry.metrics.address' "$address"
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi
}
