#!/bin/bash

#################################################################################################################################
############################################### MAC Datasource Traces Functions ##################################################
#################################################################################################################################

# Loads datasource traces utils functions
# Input:
#   ---
# Output:
#   ---
function load_traces_utils {
    local func_name="${FUNCNAME[0]}"

    local message='Loading traces utils functions ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$ALL_RESOURCES_MAC_DIR/datasource_traces_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): error loading traces utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    source "$OTEL_RESOURCES_MAC_DIR/datasource_traces_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): error loading traces utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    # For span metrics
    source "$ALL_RESOURCES_MAC_DIR/datasource_metrics_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): error loading metrics utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    ((EXIT_CODE++))
}