#!/bin/bash

#################################################################################################################################
################################################## LINUX Installer Functions ####################################################
#################################################################################################################################

# Gets selected products (logs/metrics)
# Input:
#   ---
# Output:
#   IS_LOGS_OPTION_WAS_SELECTED - Tells if logs option was selected (true/false)
#   LOGS_TELEMETRY - The logs telemetry if logs option was selected
#   LOGS_PARAMS - The logs params if logs option was selected
#   IS_METRICS_OPTION_WAS_SELECTED - Tells if metrics option was selected (true/false)
#   METRICS_TELEMETRY - The metrics telemetry if metrics option was selected
#   METRICS_PARAMS - The metrics params if metrics option was selected
function get_selected_products {
    local exit_code=1
    local func_name="${FUNCNAME[0]}"

    local message='Getting selected products ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local data_source_index=0
    for data_source in $DATA_SOURCES; do
        if [[ $data_source == $CURRENT_DATA_SOURCE ]]; then
            break
        fi

        ((data_source_index++))
    done

    get_json_file_field_value_list "$AGENT_JSON" ".configuration.subtypes[0].datasources[$data_source_index].telemetries[]"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    local telemetries=("${JSON_VALUE[@]}")
    
    local is_logs_option_selected=false
    local is_metrics_option_selected=false
    
    for telemetry in "${telemetries[@]}"; do
        get_json_str_field_value "$telemetry" '.type'
        if [[ $? -ne 0 ]]; then
            message="installer.bash ($exit_code): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $exit_code
        fi

        local type="$JSON_VALUE"
        local params

        get_json_str_field_value_list "$telemetry" '.params[]'
        local func_status=$?
        if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
            message="installer.bash ($exit_code): $result"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $exit_code
        fi
        if [[ $func_status -ne 0 ]]; then
            params=()
        else
            params=("${JSON_VALUE[@]}")
        fi

        LIST=("${params[@]}")
        local params_str=$(convert_list_to_str)

        if [[ "$type" == 'LOG_ANALYTICS' ]]; then
            message='Logs option was selected'
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_log "$LOG_LEVEL_DEBUG" "$message"
            message="Logs telemetry is '$telemetry'"
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_log "$LOG_LEVEL_DEBUG" "$message"
            message="Logs params are '${params[@]}'"
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_log "$LOG_LEVEL_DEBUG" "$message"

            is_logs_option_was_selected=true
            write_task_post_run "LOGS_TELEMETRY='$telemetry'"
            write_task_post_run "LOGS_PARAMS=$params_str"
        elif [[ "$type" == 'METRICS' ]]; then
            message='Metrics option was selected'
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_log "$LOG_LEVEL_DEBUG" "$message"
            message="Metrics telemetry is '$telemetry'"
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_log "$LOG_LEVEL_DEBUG" "$message"
            message="Metrics params are '${params[@]}'"
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_log "$LOG_LEVEL_DEBUG" "$message"

            is_metrics_option_was_selected=true
            write_task_post_run "METRICS_TELEMETRY='$telemetry'"
            write_task_post_run "METRICS_PARAMS=$params_str"
        fi
    done

    write_task_post_run "IS_LOGS_OPTION_WAS_SELECTED=$is_logs_option_was_selected"
    write_task_post_run "IS_METRICS_OPTION_WAS_SELECTED=$is_metrics_option_was_selected"
}
