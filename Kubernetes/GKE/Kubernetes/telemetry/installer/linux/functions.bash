#!/bin/bash

#################################################################################################################################
################################################## Installer Linux Functions ####################################################
#################################################################################################################################

# Gets general params (params under datasource)
# Output:
#   general_params - The params under datasource
# Error:
#   Exit Code 1
function get_general_params () {
    write_log "INFO" "Getting general params ..."

    local general_params=$(jq -r '.configuration.subtypes[0].datasources[0].params[]' $app_json)
    if [[ "$general_params" = null ]]; then
        write_run "print_error \"installer.bash (1): .configuration.subtypes[0].datasources[0].params[] was not found in application JSON\""
        return 1
    fi
    if [[ -z "$general_params" ]]; then
        write_run "print_error \"installer.bash (1): '.configuration.subtypes[0].datasources[0].params[]' is empty in application JSON\""
        return 1
    fi

    write_log "INFO" "general_params = $general_params"
    write_run "general_params='$general_params'"
}

# Gets which products were selected (logs/metrics/tracing)
# Output:
#   is_logs_option_selected - Tells if logs option was selected (true/false)
#   logs_params - The logs params if logs option was selected
#   is_metrics_option_selected - Tells if metrics option was selected (true/false)
#   metrics_params - The metrics params if metrics option was selected
#   is_traces_option_selected - Tells if traces option was selected (true/false)
#   traces_params - The traces params if traces option was selected
# Error:
#   Exit Code 2
function get_which_products_were_selected () {
    write_log "INFO" "Getting which products were selected ..."

    local telemetries=$(jq -c '.configuration.subtypes[0].datasources[0].telemetries[]' $app_json)
    if [[ "$telemetries" = null ]]; then
        write_run "print_error \"installer.bash (2): .configuration.subtypes[0].datasources[0].telemetries[] was not found in application JSON\""
        return 2
    fi
    if [[ -z "$telemetries" ]]; then
        write_run "print_error \"installer.bash (2): .configuration.subtypes[0].datasources[0].telemetries[] is empty in application JSON\""
        return 2
    fi

    local is_logs_option_selected=false
    local is_metrics_option_selected=false
    local is_traces_option_selected=false
    local index=0

    while read -r telemetry; do
        local type=$(echo "$telemetry" | jq -r '.type')
        if [[ "$type" = null ]]; then
            write_run "print_error \"installer.bash (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' was not found in application JSON\""
            return 2
        fi
        if [[ -z "$type" ]]; then
            write_run "print_error \"installer.bash (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' is empty in application JSON\""
            return 2
        fi

        local params=$(echo -e "$telemetry" | jq -r '.params[]')
        if [[ "$params" = null ]]; then
            write_run "print_error \"installer.bash (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].params[]' was not found in application JSON\""
            return 2
        fi

        if [[ "$type" = "LOG_ANALYTICS" ]]; then
            write_log "INFO" "is_logs_option_selected = true"
            write_log "INFO" "logs_params = $params"

            is_logs_option_selected=true
            write_run "logs_params='$params'"
        elif [[ "$type" = "METRICS" ]]; then
            write_log "INFO" "is_metrics_option_selected = true"
            write_log "INFO" "metrics_params = $params"

            is_metrics_option_selected=true
            write_run "metrics_params='$params'"
        elif [[ "$type" = "TRACING" ]]; then
            write_log "INFO" "is_traces_option_selected = true"
            write_log "INFO" "traces_params = $params"

            is_traces_option_selected=true
            write_run "traces_params='$params'"
        fi

        let "index++"
    done < <(echo -e "$telemetries")

    write_run "is_logs_option_selected=$is_logs_option_selected"
    write_run "is_metrics_option_selected=$is_metrics_option_selected"
    write_run "is_traces_option_selected=$is_traces_option_selected"
}

# Builds tolerations Helm sets
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 3
function build_tolerations_helm_sets () {
    write_log "INFO" "Building tolerations Helm set ..."

    local is_taint_param=$(find_param "$general_params" "isTaint")
    if [[ -z "$is_taint_param" ]]; then
        write_run "print_error \"installer.bash (3): isTaint param was not found\""
        return 3
    fi

    local is_taint_value=$(echo -e "$is_taint_param" | jq -r '.value')
    if [[ "$is_taint_value" = null ]]; then
        write_run "print_error \"installer.bash (3): '.configuration.subtypes[0].datasources[0].params[{name=isTaint}].value' was not found in application JSON\""
        return 3
    fi
    if [[ -z "$is_taint_value" ]]; then
        write_run "print_error \"installer.bash (3): '.configuration.subtypes[0].datasources[0].params[{name=isTaint}].value' is empty in application JSON\""
        return 3
    fi

    if ! $is_taint_value; then
        write_log "INFO isTaint value = false"
        return
    fi
                    
    local items=$(kubectl get nodes -o json 2>/dev/null | jq -r '.items')
    if [[ "$items" = null ]]; then
        write_run "print_error \"installer.bash (3): '.items[]' was not found in kubectl get nodes JSON\""
        return 3
    fi
    if [[ -z "$items" ]]; then
        write_run "print_error \"installer.bash (3): '.items[]' is empty in kubectl get nodes JSON\""
        return 3
    fi

    local tolerations_sets=""
    local index=0

    while read -r taint; do
        local key=$(echo -e "$taint" | jq -r '.key')
        if [[ "$key" = null ]]; then
            write_run "print_error \"installer.bash (3): '.items[{item}].key' was not found in kubectl get nodes JSON\""
            return 3
        fi

        local effect=$(echo -e "$taint" | jq -r '.effect')
        if [[ "$effect" = null ]]; then
            write_run "print_error \"installer.bash (3): '.items[{item}].effect' was not found in kubectl get nodes JSON\""
            return 3
        fi

        local operator="Exists"
        local value=$(echo -e "$taint" | jq -r '.value')
        if [[ "$value" != null ]]; then
            operator="Equal"

            if $is_logs_option_selected; then
                tolerations_sets+=" --set-string logzio-fluentd.daemonset.tolerations[$index].value=$value"
            fi
            if $is_metrics_option_selected || $is_traces_option_selected; then
                tolerations_sets+=" --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$index].value=$value"
                tolerations_sets+=" --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$index].value=$value"
                tolerations_sets+=" --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$index].value=$value"
                tolerations_sets+=" --set-string logzio-k8s-telemetry.tolerations[$index].value=$value"
            fi
        fi

        if $is_logs_option_selected; then
            tolerations_sets+=" --set-string logzio-fluentd.daemonset.tolerations[$index].key=$key"
            tolerations_sets+=" --set-string logzio-fluentd.daemonset.tolerations[$index].operator=$operator"
            tolerations_sets+=" --set-string logzio-fluentd.daemonset.tolerations[$index].effect=$effect"
        fi
        if $is_metrics_option_selected || $is_traces_option_selected; then
            tolerations_sets+=" --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$index].key=$key"
            tolerations_sets+=" --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$index].operator=$operator"
            tolerations_sets+=" --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$index].effect=$effect"
            tolerations_sets+=" --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$index].key=$key"
            tolerations_sets+=" --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$index].operator=$operator"
            tolerations_sets+=" --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$index].effect=$effect"
            tolerations_sets+=" --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$index].key=$key"
            tolerations_sets+=" --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$index].operator=$operator"
            tolerations_sets+=" --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$index].effect=$effect"
            tolerations_sets+=" --set-string logzio-k8s-telemetry.tolerations[$index].key=$key"
            tolerations_sets+=" --set-string logzio-k8s-telemetry.tolerations[$index].operator=$operator"
            tolerations_sets+=" --set-string logzio-k8s-telemetry.tolerations[$index].effect=$effect"
        fi

        let "index++"
    done < <(echo -e "$items" | jq -c '.[].spec | select(.taints!=null) | .taints[]')

    write_log "INFO" "tolerations_sets = $tolerations_sets"
    write_run "log_helm_sets+='$tolerations_sets'"
    write_run "helm_sets+='$tolerations_sets'"
}

# Builds enable metrics or traces Helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_enable_metrics_or_traces_helm_set () {
    write_log "INFO" "Building enable metrics or traces Helm set ..."

    local helm_set=" --set metricsOrTraces.enabled=true"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}

# Builds metrics/traces environment tag helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 4
function build_environment_tag_helm_set () {
    write_log "INFO" "Building environment tag Helm set ..."

    local env_tag=$(jq -r '.id' $app_json)
    if [[ "$env_tag" = null ]]; then
        write_run "print_error \"installer.bash (4): '.id' was not found in application JSON\""
        return 4
    fi
    if [[ -z "$env_tag" ]]; then
        write_run "print_error \"installer.bash (4): '.id' is empty in application JSON\""
        return 4
    fi

    local helm_set=" --set logzio-k8s-telemetry.secrets.p8s_logzio_name=$env_tag"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}

# Gets logs scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 5
function get_logs_scripts () {
    write_log "INFO" "Getting logs script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/logs/linux/logs.bash > $logzio_temp_dir/logs.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.script (5): failed to get logs script file from logzio-agent-manifest repo.\n  $err\""
        return 5
    fi

    write_log "INFO" "Getting logs functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/logs/linux/functions.bash > $logzio_temp_dir/logs_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.script (5): failed to get logs functions script file from logzio-agent-manifest repo.\n  $err\""
        return 5
    fi
}

# Gets metrics scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 6
function get_metrics_scripts () {
    write_log "INFO" "Getting metrics script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/metrics/linux/metrics.bash > $logzio_temp_dir/metrics.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.script (6): failed to get metrics script file from logzio-agent-manifest repo.\n  $err\""
        return 6
    fi

    write_log "INFO" "Getting metrics functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/metrics/linux/functions.bash > $logzio_temp_dir/metrics_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.script (6): failed to get metrics functions script file from logzio-agent-manifest repo.\n  $err\""
        return 6
    fi
}

# Gets traces scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 7
function get_traces_scripts () {
    write_log "INFO" "Getting traces script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/traces/linux/traces.bash > $logzio_temp_dir/traces.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.script (7): failed to get traces script file from logzio-agent-manifest repo.\n  $err\""
        return 7
    fi

    write_log "INFO" "Getting traces functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/traces/linux/functions.bash > $logzio_temp_dir/traces_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.script (7): failed to get traces functions script file from logzio-agent-manifest repo.\n  $err\""
        return 7
    fi
}

# Runs Helm install
# Error:
#   Exit Code 8
function run_helm_install () {
    write_log "INFO" "Running Helm install ..."
    write_log "INFO" "helm_sets = $log_helm_sets"

    retries=0
    while [ $retries -lt 3 ]; do
        let "retries++"
        helm install -n monitoring $helm_sets --create-namespace logzio-monitoring logzio-helm/logzio-monitoring >/dev/null 2>$task_error_file
        if [[ $? -eq 0 ]]; then
            return
        fi

        sleep 5
    done

    local err=$(cat $task_error_file)
    write_run "print_error \"installer.bash (8): failed to run Helm install.\n  $err\""
    return 8
}
