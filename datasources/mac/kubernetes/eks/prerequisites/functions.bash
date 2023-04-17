#!/bin/bash

#################################################################################################################################
############################################### MAC Subtype Prerequisites Script ################################################
#################################################################################################################################

# Loads prerequisites utils functions
# Input:
#   ---
# Output:
#   ---
function load_prerequisites_utils {
    local func_name="${FUNCNAME[0]}"

    local message='Loading prerequisites utils functions ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$KUBERNETES_RESOURCES_MAC_DIR/subtype_prerequisites_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="prerequisites.bash ($EXIT_CODE): error loading prerequisites utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    ((EXIT_CODE++))
}
