#!/bin/bash

#################################################################################################################################
############################################ LINUX Prerequisites Utils Functions ################################################
#################################################################################################################################

# Checks if the machine can connect to Logz.io logs (port 8071)
# Input:
#   ---
# Output:
#   ---
function can_machine_connect_to_logzio_logs {
    local exit_code=1
    local func_name="${FUNCNAME[0]}"

    local message="Checking if $MACHINE_NAME can connect to Logz.io logs (port 8071) ..."
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    curl --connect-timeout 5 "$LISTENER_URL:8071" >/dev/null 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="prerequisites.bash ($exit_code): $MACHINE_NAME cannot connect to '$LISTENER_URL:8071'. please check your $MACHINE_NAME network for port 8071: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Checks if the machine can connect to Logz.io metrics (port 8053)
# Input:
#   ---
# Ouput:
#   ---
function can_machine_connect_to_logzio_metrics {
    local exit_code=2
    local func_name="${FUNCNAME[0]}"

    local message="Checking if $MACHINE_NAME can connect to Logz.io metrics (port 8053) ..."
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    curl --connect-timeout 5 "$LISTENER_URL:8053" >/dev/null 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="prerequisites.bash ($exit_code): $MACHINE_NAME cannot connect to '$LISTENER_URL:8053'. please check your $MACHINE_NAME network for port 8053: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}
