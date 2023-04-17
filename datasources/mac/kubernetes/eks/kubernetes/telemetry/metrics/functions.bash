#!/bin/bash

#################################################################################################################################
############################################## MAC Datasource Metrics Functions #################################################
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

    source "$ALL_RESOURCES_MAC_DIR/datasource_metrics_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): error loading metrics utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    source "$KUBERNETES_RESOURCES_MAC_DIR/datasource_metrics_utils.bash" 2>"$TASK_ERROR_FILE"
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

# Builds Fargate collector mode standalone Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_fargate_collector_mode_standalone_helm_set {   
    local func_name="${FUNCNAME[0]}"

    local message='Building Fargate collector mode standalone Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local helm_set=" --set logzio-k8s-telemetry.collector.mode=standalone"

    message="Fargate collector mode standalone Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}
