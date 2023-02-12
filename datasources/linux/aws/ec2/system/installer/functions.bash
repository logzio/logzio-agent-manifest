#!/bin/bash

#################################################################################################################################
############################################ LINUX Datasource Installer Functions ###############################################
#################################################################################################################################

# Loads datasource installer utils scripts
# Input:
#   ---
# Output:
#   ---
function load_installer_utils {
    local func_name="${FUNCNAME[0]}"

    local message='Laoding installer utils functions ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$ALL_RESOURCES_LINUX_DIR/datasource_installer_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error loading installer utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    ((EXIT_CODE++))
}
