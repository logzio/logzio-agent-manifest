#!/bin/bash

#################################################################################################################################
############################################# LINUX Datasource Metrics Functions ################################################
#################################################################################################################################

# Loads datasource metrics utils functions
# Input:
#   ---
# Output:
#   ---
function load_metrics_utils {
    local func_name="${FUNCNAME[0]}"

    local message='Laoding metrics utils functions ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$ALL_RESOURCES_LINUX_DIR/datasource_metrics_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): error loading logs utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    source "$OTEL_RESOURCES_LINUX_DIR/datasource_metrics_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): error loading metrics utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    ((EXIT_CODE++))
}