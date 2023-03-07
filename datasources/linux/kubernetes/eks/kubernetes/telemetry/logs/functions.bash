#!/bin/bash

#################################################################################################################################
############################################## LINUX Datasource Logs Functions ##################################################
#################################################################################################################################

# Loads datasource logs utils functions
# Input:
#   ---
# Output:
#   ---
function load_logs_utils {
    local func_name="${FUNCNAME[0]}"

    local message='Laoding logs utils functions ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$ALL_RESOURCES_LINUX_DIR/datasource_logs_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="logs.bash ($EXIT_CODE): error loading logs utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    source "$KUBERNETES_RESOURCES_LINUX_DIR/datasource_logs_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="logs.bash ($EXIT_CODE): error loading logs utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    ((EXIT_CODE++))
}

# Gets is Fargate was selected
# Input:
#   ---
# Output:
#   IS_FARGATE - Tells if Fargate was selected (true/false)
function get_is_fargate_was_selected {
    local func_name="${FUNCNAME[0]}"

    local message='Getting is Fargate was selected ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    PARAMS=("${LOGS_PARAMS[@]}")
    get_param_value 'isFargate'
    if [[ $? -ne 0 ]]; then
        message="logs.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local is_fargate=$PARAM_VALUE

    if $is_fargate; then
        message="AWS Fargate option was selected"
    else
        message="AWS Fargate option was not selected"
    fi
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "IS_FARGATE=$is_fargate"
}

# Builds enable Fargate Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_enable_fargate_helm_set {    
    local func_name="${FUNCNAME[0]}"

    local message='Building enable Fargate Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local helm_set=" --set fargateLogRouter.enabled=true"

    message="Enable Fargate Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}
