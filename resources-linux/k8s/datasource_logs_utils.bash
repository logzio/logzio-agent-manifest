#!/bin/bash

#################################################################################################################################
########################################### LINUX Datasource Logs Utils Functions ###############################################
#################################################################################################################################

# Builds enable logs Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_enable_logs_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building enable logs Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
    
    local helm_set=' --set logs.enabled=true'

    message="Enable logs Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}

# Builds Logz.io logs listener url Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_logzio_logs_listener_url_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building Logz.io logs listener url Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local helm_set=" --set logzio-fluentd.secrets.logzioListener=$LISTENER_URL"

    message="Logz.io logs listener url Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}

# Builds Logz.io logs token Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_logzio_logs_token_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building Logz.io logs token Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local helm_set=" --set logzio-fluentd.secrets.logzioShippingToken=$LOGS_TOKEN"
    
    message="Logz.io logs token Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}

# Builds environment id Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_environment_id_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building environment id Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local helm_set=" --set logzio-fluentd.env_id=$ENV_ID"

    message="Environment id Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}

# Builds enable security report Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_enable_security_report_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building enable security report Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local helm_set=" --set securityReport.enabled=true"

    message="Enable security report Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}

# Builds Logz.io Trivy logs listener URL Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_logzio_trivy_logs_listener_url_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building Logz.io Trivy logs listener url Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local helm_set=" --set logzio-trivy.secrets.logzioListener=$LISTENER_URL"

    message="Logz.io Trivy logs listener url Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}

# Builds Logz.io Trivy logs token Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_logzio_trivy_logs_token_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building Logz.io Trivy logs token Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local helm_set=" --set logzio-trivy.secrets.logzioShippingToken=$LOGS_TOKEN"

    message="Logz.io Trivy logs token Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}

# Builds Trivy environment id helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_trivy_environment_id_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building Trivy environment id Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local helm_set=" --set logzio-trivy.env_id=$ENV_ID"

    message="Trivy environment id Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_LOGS" "$LOG_SCRIPT_LOGS" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}
