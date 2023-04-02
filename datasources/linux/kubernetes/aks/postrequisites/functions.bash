#!/bin/bash

#################################################################################################################################
############################################# LINUX Subtype Post-Requisites Script ##############################################
#################################################################################################################################

# Loads bustype postrequistes utils functions
# Input:
#   ---
# Output:
#   ---
function load_postrequisites_utils {
    local func_name="${FUNCNAME[0]}"

    local message='Loading post-requisites utils functions ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$KUBERNETES_RESOURCES_LINUX_DIR/subtype_postrequisites_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="postrequisites.bash ($EXIT_CODE): error loading post-requisites utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_POSTREQUISITES_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    ((EXIT_CODE++))
}
