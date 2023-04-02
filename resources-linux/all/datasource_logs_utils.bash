#!/bin/bash

#################################################################################################################################
########################################### LINUX Datasource Logs Utils Functions ###############################################
#################################################################################################################################

# Gets Logz.io logs token
# Input:
#   ---
# Output:
#   LOGS_TOKEN - Logz.io logs token
function get_logzio_logs_token {
    local func_name="${FUNCNAME[0]}"

    local message='Getting Logz.io logs token ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    get_json_file_field_value "$AGENT_JSON" '.shippingTokens.LOG_ANALYTICS'
    if [[ $? -ne 0 ]]; then
        message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    
    shipping_token="$JSON_VALUE"

    message="Logz.io logs token is '$shipping_token'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOGS_TOKEN='$shipping_token'"
}

# Adds logs pipeline to OTEL confing
# Input:
#   ---
# Output:
#   ---
function add_logs_pipline_to_otel_config {
    local func_name="${FUNCNAME[0]}"

    local message='Adding logs pipeline to OTEL config ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    add_yaml_file_field_value_to_another_yaml_file_field "$OTEL_RESOURCES_DIR/logs_pipeline.yaml" "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" '' '.service.pipelines'
    if [[ $? -ne 0 ]]; then
        message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
}

# Gets logs OTEL receivers
# Input:
#   ---
# Ouput:
#   LOGS_OTEL_RECEIVERS - List of Logs OTEL receiver names
function get_logs_otel_receivers {
    local func_name="${FUNCNAME[0]}"

    local message='Getting logs OTEL receivers ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    get_json_str_field_value_list "$LOGS_TELEMETRY" '.otel.receivers[]'
    if [[ $? -ne 0 ]]; then
        message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local logs_otel_receivers=("${JSON_VALUE[@]}")

    message="Logs OTEL receivers are '${logs_otel_receivers[@]}'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    LIST=("${logs_otel_receivers[@]}")
    local logs_otel_receivers_str=$(convert_list_to_str)
    write_task_post_run "LOGS_OTEL_RECEIVERS=$logs_otel_receivers_str"
}
