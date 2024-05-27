#!/bin/bash

#################################################################################################################################
######################################## LINUX Datasource Installer Utils Functions #############################################
#################################################################################################################################

# Gets is Taints and Tolerations option was selected
# Input:
#   ---
# Output:
#   IS_TAINT - Tells if Taints and Tolerations option was selected (true/false)
function get_is_taints_and_toleration_was_selected {
    local func_name="${FUNCNAME[0]}"

    local message='Getting is Taints and Toleration was selected ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    PARAMS=("${GENERAL_PARAMS[@]}")
    get_param_value 'isTaint'
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local is_taint=$PARAM_VALUE

    if $is_taint; then
        message='Taints and Tolerations option was selected'
    else
        message='Taints and Tolerations option was not selected'
    fi
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "IS_TAINT=$is_taint"
}

# Builds tolerations Helm sets
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_tolerations_helm_sets {
    local func_name="${FUNCNAME[0]}"

    local message='Building tolerations Helm sets ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local nodes
    nodes=$(kubectl get nodes -o json 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        local err=$(get_task_error_message)
        if [[ "$err" == *"ERROR"* ]]; then
            message="installer.bash ($EXIT_CODE): error getting nodes: $err"
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi
    fi
    
    get_json_str_field_value_list "$nodes" '.items[].spec | select(.taints!=null) | .taints[]'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        message="installer.bash ($EXIT_CODE): error getting nodes: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    if [[ $func_status -ne 0 ]]; then
        message='No taints found'
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        return
    fi

    local taints=("${JSON_VALUE[@]}")

    local tolerations_helm_sets=''
    local toleration_index=0
    for taint in "${taints[@]}"; do
        get_json_str_field_value "$taint" '.key'
        if [[ $? -ne 0 ]]; then
            message="installer.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi

        local key="$JSON_VALUE"

        get_json_str_field_value "$taint" '.effect'
        if [[ $? -ne 0 ]]; then
            message="installer.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi

        local effect="$JSON_VALUE"

        local value
        get_json_str_field_value "$taint" '.value'
        local func_status=$?
        if [[ $func_status -ne 0 && $func_status -ne 3 ]]; then
            message="installer.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi
        if [[ $func_status -ne 0 ]]; then
            value=''
        else
            value="$JSON_VALUE"
        fi
        
        if $BUILD_WINDOWS_TOLERATIONS_HELM_SETS; then
            toleartions_helm_sets=$(build_windows_toleration_helm_sets "$tolerations_helm_sets" $toleration_index "$value" "$key" "$operator" "$effect")
        fi

        toleartions_helm_sets=$(build_no_windows_toleration_helm_sets "$tolerations_helm_sets" $toleration_index "$value" "$key" "$operator" "$effect")

        ((toleration_index++))
    done

    message="Toleration Helm sets are '$toleration_helm_sets'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$toleration_helm_sets'"
    write_task_post_run "HELM_SETS+='$toleration_helm_sets'"
}

# Builds Windows toleration Helm sets
# Input:
#   tolerations_helm_sets - The tolerations Helm sets string
#   toleration_index - The toleartion index
#   value - Taint's value
#   key - Taint's key
#   effect - Taint's effect
# Output:
#   The toleration_helm_sets with the appended Helm sets
function build_windows_toleration_helm_sets {
    tolerations_helm_sets="$1"
    toleration_index=$2
    value="$3"
    key="$4"
    effect="$5"

    local operator='Exists'

    if [[ ! -z "$value" ]]; then
        operator='Equal'

        if $IS_LOGS_OPTION_WAS_SELECTED; then
            tolerations_helm_sets+=" --set-string logzio-logs-collector.tolerations[$toleration_index].value=$value"
        fi
    fi
    
    if $IS_LOGS_OPTION_WAS_SELECTED; then
        tolerations_helm_sets+=" --set-string logzio-logs-collector.tolerations[$toleration_index].key=$key"
        tolerations_helm_sets+=" --set-string logzio-logs-collector.tolerations[$toleration_index].operator=$operator"
        tolerations_helm_sets+=" --set-string logzio-logs-collector.tolerations[$toleration_index].effect=$effect"
    fi

    echo -e "$toleration_helm_sets"
}

# Builds no Windows toleration Helm sets
# Input:
#   tolerations_helm_sets - The tolerations Helm sets string
#   toleration_index - The toleartion index
#   value - Taint's value
#   key - Taint's key
#   effect - Taint's effect
# Output:
#   The toleration_helm_sets with the appended Helm sets
function build_no_windows_toleration_helm_sets {
    tolerations_helm_sets="$1"
    toleration_index=$2
    value="$3"
    key="$4"
    effect="$5"

    local operator='Exists'

    if [[ ! -z "$value" ]]; then
        operator='Equal'

        if $IS_LOGS_OPTION_WAS_SELECTED; then
            tolerations_helm_sets+=" --set-string logzio-logs-collector.tolerations[$toleration_index].value=$value"
        fi
        if $IS_METRICS_OPTION_WAS_SELECTED || $IS_TRACES_OPTION_WAS_SELECTED; then
            tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$toleration_index].value=$value"
            tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$toleration_index].value=$value"
            tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$toleration_index].value=$value"
            tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.tolerations[$toleration_index].value=$value"
        fi
    fi
    
    if $IS_LOGS_OPTION_WAS_SELECTED; then
        tolerations_helm_sets+=" --set-string logzio-logs-collector.tolerations[$toleration_index].key=$key"
        tolerations_helm_sets+=" --set-string logzio-logs-collector.tolerations[$toleration_index].operator=$operator"
        tolerations_helm_sets+=" --set-string llogzio-logs-collector.tolerations[$toleration_index].effect=$effect"
    fi
    if $IS_METRICS_OPTION_WAS_SELECTED || $IS_TRACES_OPTION_WAS_SELECTED; then
        tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$toleration_index].key=$key"
        tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$toleration_index].operator=$operator"
        tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$toleration_index].effect=$effect"
        tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$toleration_index].key=$key"
        tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$toleration_index].operator=$operator"
        tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$toleration_index].effect=$effect"
        tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$toleration_index].key=$key"
        tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$toleration_index].operator=$operator"
        tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$toleration_index].effect=$effect"
        tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.tolerations[$toleration_index].key=$key"
        tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.tolerations[$toleration_index].operator=$operator"
        tolerations_helm_sets+=" --set-string logzio-k8s-telemetry.tolerations[$toleration_index].effect=$effect"
    fi

    echo -e "$toleration_helm_sets"
}

# Builds enable metrics or traces Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_enable_metrics_or_traces_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building enable metrics or traces Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local helm_set=' --set metricsOrTraces.enabled=true'
    
    message="Enable metrics or traces Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}

# Builds metrics/traces environment tag Helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_environment_tag_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building environment tag Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local helm_set=" --set logzio-k8s-telemetry.secrets.p8s_logzio_name=$ENV_ID"
    
    message="Environment tag Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}

# Builds metrics/traces environment id helm set
# Input:
#   ---
# Output:
#   LOG_HELM_SETS - Contains all the Helm sets for logging
#   HELM_SETS - Contains all the Helm sets
function build_environment_id_helm_set {
    local func_name="${FUNCNAME[0]}"

    local message='Building environment id Helm set ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local helm_set=" --set logzio-k8s-telemetry.secrets.env_id=$ENV_ID"

    message="Environment id Helm set is '$helm_set'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LOG_HELM_SETS+='$helm_set'"
    write_task_post_run "HELM_SETS+='$helm_set'"
}
