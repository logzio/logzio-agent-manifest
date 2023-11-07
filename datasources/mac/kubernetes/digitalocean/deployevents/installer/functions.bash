#!/bin/bash

#################################################################################################################################
############################################# MAC Datasource Installer Functions ################################################
#################################################################################################################################

# Loads datasource installer utils functions
# Input:
#   ---
# Output:
#   ---
function load_installer_utils {
    local func_name="${FUNCNAME[0]}"

    local message='Loading installer utils functions ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$ALL_RESOURCES_MAC_DIR/datasource_installer_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error loading installer utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    source "$KUBERNETES_RESOURCES_MAC_DIR/datasource_installer_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error loading installer utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    ((EXIT_CODE++))
}

# Gets environment id
# Input:
#   ---
# Output:
#   ENV_ID - The environment id
function get_environment_id {
    local func_name="${FUNCNAME[0]}"

    local message='Getting environment id ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    PARAMS=("${GENERAL_PARAMS[@]}")
    get_param_value 'envID'
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local env_id="$PARAM_VALUE"
    
    if [[ "$env_id" == '' ]]; then
        env_id=$(kubectl config current-context 2>"$TASK_ERROR_FILE")
        if [[ $? -ne 0 ]]; then
            local err=$(get_task_error_message)
            if [[ "$err" == *"ERROR"* ]]; then
                env_id=$(echo "$RANDOM" | md5sum | cut -c 1-32)
            fi
        fi
    fi

    message="Environment id is '$env_id'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
    
    write_task_post_run "ENV_ID='$env_id'"
}
