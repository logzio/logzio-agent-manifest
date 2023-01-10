#!/bin/bash

#################################################################################################################################
######################################### LINUX Datasource Metrics Utils Functions ##############################################
#################################################################################################################################

# Gets Logz.io metrics token
# Input:
#   ---
# Output:
#   METRICS_TOKEN - Logz.io metrics token
function get_logzio_metrics_token {
    local exit_code=2
    local func_name="${FUNCNAME[0]}"

    local message='Getting Logz.io metrics token ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    get_json_file_field_value "$AGENT_JSON" '.shippingTokens.METRICS'
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($ExitCode): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
    
    local shipping_token="$JSON_VALUE"

    message="Logz.io metrics token is '$shipping_token'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "METRICS_TOKEN='$shipping_token'"
}
