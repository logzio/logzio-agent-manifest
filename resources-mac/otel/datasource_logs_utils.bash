#!/bin/bash

#################################################################################################################################
############################################ MAC Datasource Logs Utils Functions ################################################
#################################################################################################################################

# Gets log sources
# Input:
#   ---
# Output:
#   LOG_SOURCES - List of log sources
function get_log_sources {
    local func_name="${FUNCNAME[0]}"

    local message='Getting log sources ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    PARAMS=("${LOGS_PARAMS[@]}")
    get_param_value_list 'logSources'
    if [[ $? -ne 0 ]]; then
        message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local log_sources=("${PARAM_VALUE[@]}")
    
    message="Log sources are '${log_sources[@]}'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    LIST=("${log_sources[@]}")
    local log_sources_str=$(convert_list_to_str)
    write_task_post_run "LOG_SOURCES=$log_sources_str"
}

# Adds logs receivers to OTEL config
# Input:
#   ---
# Output:
#   ---
function add_logs_receivers_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Adding logs receivers to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    for logs_otel_receiver in "${LOGS_OTEL_RECEIVERS[@]}"; do
        get_yaml_file_field_value "$OTEL_RECEIVERS_DIR/$logs_otel_receiver.yaml" '.mac_run'
        if [[ $? -ne 0 ]]; then
            message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi

        local script_block="$YAML_VALUE"

        echo -e "$script_block" >"$OTEL_FUNCTION_FILE"
        source "$OTEL_FUNCTION_FILE" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="logs.bash ($EXIT_CODE): error loading '$logs_otel_receiver' OTEL function script: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi

        LOGS_TYPE='agent-mac'
        create_otel_receiver
        local func_status=$?
        if [[ $func_status -ne 0 && $func_status -ne 1 ]]; then
            message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi
        if [[ $func_status -ne 0 ]]; then
            message="$(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_log "$LOG_LEVEL_DEBUG" "$message"

            continue
        fi

        add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_RECEIVERS_DIR/$logs_otel_receiver.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.receiver' '.receivers'
        if [[ $? -ne 0 ]]; then
            message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi

        local receiver_name="${logs_otel_receiver//_//}"

        add_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.service.pipelines.logs.receivers' "$receiver_name/NAME"
        if [[ $? -ne 0 ]]; then
            message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi
    done

    sed -i '' "s@NAME@${PLATFORM,,}_${SUB_TYPE,,}_${CURRENT_DATA_SOURCE,,}@g" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi
}

# Gets logs OTEL processors
# Input:
#   ---
# Ouput:
#   LOGS_OTEL_PROCESSORS - List of logs OTEL processor names
function get_logs_otel_processors {
    local func_name="${FUNCNAME[0]}"

    local message='Getting logs OTEL processors ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    get_json_str_field_value_list "$LOGS_TELEMETRY" '.otel.processors[]'
    if [[ $? -ne 0 ]]; then
        message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi

    local logs_otel_processors=("${JSON_VALUE[@]}")

    message="Logs OTEL processors are '${logs_otel_processors[@]}'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    LIST=("${logs_otel_processors[@]}")
    local logs_otel_processors_str=$(convert_list_to_str)
    write_task_post_run "LOGS_OTEL_PROCESSORS=$logs_otel_processors_str"
}

# Adds logs processors to OTEL config
# Input:
#   ---
# Output:
#   ---
function add_logs_processors_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Adding logs processors to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local exists_processors
    local is_exists_processors_empty=false

    get_yaml_file_field_value_list "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.processors'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
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
            message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi

        exists_processors=("${YAML_VALUE[@]}")
    fi

    for logs_otel_processor in "${LOGS_OTEL_PROCESSORS[@]}"; do
        local processor_name="${logs_otel_processor//_//}"

        if [[ $processor_name == 'resource_agent' ]] ; then
            AGENT_VERSION=$(cat '/tmp/logzio/version')
            add_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.processors.resource/agent.attributes[0].value' "$AGENT_VERSION"
        fi

        add_yaml_file_field_value "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.service.pipelines.logs.processors' $processor_name
        if [[ $? -ne 0 ]]; then
            message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi

        local is_processor_exists=false

        for exists_processor in "${exists_processors[@]}"; do
            exists_processor="${exists_processor////_}"

            if [[ "$logs_otel_processor" == "- $exists_processor" ]]; then
                is_processor_exists=true
                break
            fi
        done

        if $is_processor_exists; then
            continue
        fi

        add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_PROCESSORS_DIR/$logs_otel_processor.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.processors'
        if [[ $? -ne 0 ]]; then
            message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi
    done
}

# Adds logs exporter to OTEL config
# Input:
#   ---
# Output:
#   ---
function add_logs_exporter_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Adding logs exporter to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local exists_exporters
    local is_exists_exporters_empty=false

    get_yaml_file_field_value_list "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '.exporters'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
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
            message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi

        exists_exporters=("${YAML_VALUE[@]}")
    fi

    for $exists_exporter in $exists_exporers; do
        if [[ "$exists_exporter" == '- logzio/logs' ]]; then
            return
        fi
    done

    set_yaml_file_field_value "$OTEL_EXPORTERS_DIR/logzio_logs.yaml" '.logzio/logs.account_token' "$LOGS_TOKEN"
    if [[ $? -ne 0 ]]; then
        message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi

    set_yaml_file_field_value "$OTEL_EXPORTERS_DIR/logzio_logs.yaml" '.logzio/logs.headers.user-agent' "$USER_AGENT_LOGS"
    if [[ $? -ne 0 ]]; then
        message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi

    local logzio_region=$(get_logzio_region "$LISTENER_URL")
    
    message="Logz.io region is '$logzio_region'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    set_yaml_file_field_value "$OTEL_EXPORTERS_DIR/logzio_logs.yaml" '.logzio/logs.region' "$logzio_region"
    if [[ $? -ne 0 ]]; then
        message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi

    add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_EXPORTERS_DIR/logzio_logs.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.exporters'
    if [[ $? -ne 0 ]]; then
        message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi
}
