#!/bin/bash

#################################################################################################################################
########################################## MAC Datasource Metrics Utils Functions ###############################################
#################################################################################################################################

# Builds enable metrics Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_enable_metrics_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building enable metrics Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local helm_set=' --set logzio-k8s-telemetry.metrics.enabled=true'

    local message="Enable metrics Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}

# Builds Logz.io metrics listener URL Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_logzio_metrics_listener_url_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building Logz.io metrics listener url Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local listener_url="https://$LISTENER_URL:8053"
    local helm_set=" --set logzio-k8s-telemetry.secrets.ListenerHost=$listener_url"

    local message="Logz.io metrics listener url Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}

# Builds Logz.io metrics token Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_logzio_metrics_token_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building Logz.io metrics token Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
    
    local helm_set=" --set logzio-k8s-telemetry.secrets.MetricsToken=$METRICS_TOKEN"

    local message="Logz.io metrics token Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}

# Gets is metrics filter was selected
# Input:
#   ---
# Output:
#   IS_FILTER - Tells if metrics filter was selected (true/false)
function get_is_metrics_filter_was_selected {
    local func_name="${FUNCNAME[0]}"

    local message='Getting if metrics filter option was selected ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    PARAMS=("${METRICS_PARAMS[@]}")
    get_param_value_list 'isFilter'
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local is_filter=$PARAM_VALUE

    if $is_filter; then
        message='Metrics filter option was selected'
    else
        message='Metrics filter option was not selected'
    fi
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "IS_FILTER=$is_filter"
}

# Builds enable metrics filter Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_enable_metrics_filter_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building enable metrics filter Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
    
    local helm_set=" --set logzio-k8s-telemetry.enableMetricsFilter.$CLOUD_PROVIDER=true"

    message="Enable metrics filter Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}

# Gets is service graph was selected
# Input:
#   ---
# Output:
#   IS_SERVICE_GRAPH - Tells if service graph was selected (true/false)
function get_is_service_graph_was_selected {
    local func_name="${FUNCNAME[0]}"

    local message='Getting is Service Graph metrics option was selected ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    PARAMS=("${METRICS_PARAMS[@]}")
    get_param_value 'isServiceGraph'
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local is_servicegraph=$PARAM_VALUE

    if $is_servicegraph; then
        message='Service Graph metrics option was selected'
    else
        message='Service Graph metrics option was not selected'
    fi
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "IS_SERVICE_GRAPH=$is_servicegraph"
}
# Builds enable service graph Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_enable_service_graph_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building enable service graph Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
    
    local helm_set=" --set logzio-k8s-telemetry.serviceGraph.enabled=$IS_SERVICE_GRAPH"

    message="Enable service graph Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_METRICS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}