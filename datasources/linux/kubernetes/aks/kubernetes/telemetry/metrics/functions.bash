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

    local message='Loading metrics utils functions ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$ALL_RESOURCES_LINUX_DIR/datasource_metrics_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): error loading metrics utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    source "$KUBERNETES_RESOURCES_LINUX_DIR/datasource_metrics_utils.bash" 2>"$TASK_ERROR_FILE"
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

# Gets if Kubernetes runs on Windows OS option was selected
# Input:
#   ---
# Output:
#   IS_WINDOWS - Tells if Kubernetes runs on Windows OS (true/false)
function get_is_kubernetes_run_on_windows_os_was_selected {
    local func_name="${FUNCNAME[0]}"

    local message='Getting is Kubernetes runs on Windows OS option was selected ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    PARAMS=("${METRICS_PARAMS[@]}")
    get_param_value 'isWindows'
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local is_windows=$PARAM_VALUE

    if $is_windows; then
        message='Kubernetes runs on Windows OS option was selected'
    else
        message='Kubernetes runs on Windows OS option was not selected'
    fi
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "IS_WINDOWS=$is_windows"
}

# Builds Windows node username and password Helm sets (if Kubernetes runs on Windows OS)
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_windows_node_username_and_password_helm_sets {
    local func_name="${FUNCNAME[0]}"

    local message='Building Windows node username and password Helm sets ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local username=''
    local password=''

    echo -ne "${PURPLE_COLOR}Please enter your Windows Node username: $WHITE_COLOR"
    read username
    echo -ne "${PURPLE_COLOR}Please enter your Windows Node password: $WHITE_COLOR"
    read -s password
    echo
    
    local windows_username_helm_set=" --set logzio-k8s-telemetry.secrets.windowsNodeUsername=$username"
    local windows_password_helm_set=" --set logzio-k8s-telemetry.secrets.windowsNodePassword="
    local log_password="${password:0:1}*****${password: -1}"

    local message="Windows node username and password Helm sets are '$windows_username_helm_set$windows_password_helm_set$log_password'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    LOG_HELM_SETS+="$windows_username_helm_set$windows_password_helm_set$log_password"
    HELM_SETS+="$windows_username_helm_set$windows_password_helm_set$password"
}
