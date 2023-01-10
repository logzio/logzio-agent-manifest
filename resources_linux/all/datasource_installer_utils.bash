#!/bin/bash

#################################################################################################################################
######################################## LINUX Datasource Installer Utils Functions #############################################
#################################################################################################################################

# Gets selected products (logs/metrics/traces)
# Input:
#   ---
# Output:
#   IS_LOGS_OPTION_WAS_SELECTED - Tells if logs option was selected (true/false)
#   LOGS_TELEMETRY - The logs telemetry if logs option was selected
#   LOGS_PARAMS - The logs params if logs option was selected
#   IS_METRICS_OPTION_WAS_SELECTED - Tells if metrics option was selected (true/false)
#   METRICS_TELEMETRY - The metrics telemetry if metrics option was selected
#   METRICS_PARAMS - The metrics params if metrics option was selected
#   IS_TRACES_OPTION_WAS_SELECTED - Tells if traces option was selected (true/false)
#   TRACES_TELEMETRY - The traces telemetry if metrics option was selected
#   TRACES_PARAMS - The traces params if metrics option was selected
function get_selected_products {
    local exit_code=2
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
        elif [[ "$type" == 'TRACING' ]]; then
            message='Traces option was selected'
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_log "$LOG_LEVEL_DEBUG" "$message"
            message="Traces telemetry is '$telemetry'"
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_log "$LOG_LEVEL_DEBUG" "$message"
            message="Traces params are '${params[@]}'"
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_log "$LOG_LEVEL_DEBUG" "$message"

            is_traces_option_was_selected=true
            write_task_post_run "TRACES_TELEMETRY='$telemetry'"
            write_task_post_run "TRACES_PARAMS=$params_str"
        else
            message="installer.bash ($exit_code): unknown product name '$type'"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $exit_code
        fi
    done

    write_task_post_run "IS_LOGS_OPTION_WAS_SELECTED=$is_logs_option_was_selected"
    write_task_post_run "IS_METRICS_OPTION_WAS_SELECTED=$is_metrics_option_was_selected"
    write_task_post_run "IS_TRACES_OPTION_WAS_SELECTED=$is_traces_option_was_selected"
}

# Runs logs
# Input:
#   ---
# Output:
#   ---
function run_logs {
    local exit_code=2
    local func_name="${FUNCNAME[0]}"

    local message="Loading $CURRENT_DATA_SOURCE datasource logs functions ..."
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/${CURRENT_DATA_SOURCE,,}/$LOGS_FUNCTIONS_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error loading $CURRENT_DATA_SOURCE datasource logs functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $exit_code
    fi

    message="Running $CURRENT_DATA_SOURCE datasource logs ..."
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/${CURRENT_DATA_SOURCE,,}/$LOGS_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error running $CURRENT_DATA_SOURCE datasource logs: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $exit_code
    fi
}

# Runs metrics
# Input:
#   ---
# Output:
#   ---
function run_metrics {
    local exit_code=3
    local func_name="${FUNCNAME[0]}"

    local message="Loading $CURRENT_DATA_SOURCE datasource metrics functions ..."
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/${CURRENT_DATA_SOURCE,,}/$METRICS_FUNCTIONS_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error loading $CURRENT_DATA_SOURCE datasource metrics functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $exit_code
    fi

    message="Running $CURRENT_DATA_SOURCE datasource metrics ..."
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/${CURRENT_DATA_SOURCE,,}/$METRICS_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error running $CURRENT_DATA_SOURCE datasource metrics: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $exit_code
    fi
}
