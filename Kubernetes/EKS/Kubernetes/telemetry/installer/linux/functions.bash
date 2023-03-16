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

    local general_params=$($jq_bin -r '.configuration.subtypes[0].datasources[0].params[]' $app_json)
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

# Gets the selected products (logs/metrics/tracing)
# Output:
#   is_logs_option_selected - Tells if logs option was selected (true/false)
#   logs_params - The logs params if logs option was selected
#   is_metrics_option_selected - Tells if metrics option was selected (true/false)
#   metrics_params - The metrics params if metrics option was selected
#   is_traces_option_selected - Tells if traces option was selected (true/false)
#   traces_params - The traces params if traces option was selected
# Error:
#   Exit Code 2
function get_selected_products () {
    write_log "INFO" "Getting the selected products ..."

    local telemetries=$($jq_bin -c '.configuration.subtypes[0].datasources[0].telemetries[]' $app_json)
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
        local type=$(echo "$telemetry" | $jq_bin -r '.type')
        if [[ "$type" = null ]]; then
            write_run "print_error \"installer.bash (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' was not found in application JSON\""
            return 2
        fi
        if [[ -z "$type" ]]; then
            write_run "print_error \"installer.bash (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' is empty in application JSON\""
            return 2
        fi

        local params=$(echo -e "$telemetry" | $jq_bin -r '.params[]')
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

    local is_taint_value=$(echo -e "$is_taint_param" | $jq_bin -r '.value')
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
                    
    local items=$(kubectl get nodes -o json | $jq_bin -r '.items')
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
        local key=$(echo -e "$taint" | $jq_bin -r '.key')
        if [[ "$key" = null ]]; then
            write_run "print_error \"installer.bash (3): '.items[{item}].key' was not found in kubectl get nodes JSON\""
            return 3
        fi

        local effect=$(echo -e "$taint" | $jq_bin -r '.effect')
        if [[ "$effect" = null ]]; then
            write_run "print_error \"installer.bash (3): '.items[{item}].effect' was not found in kubectl get nodes JSON\""
            return 3
        fi

        local operator="Exists"
        local value=$(echo -e "$taint" | $jq_bin -r '.value')
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
    done < <(echo -e "$items" | $jq_bin -c '.[].spec | select(.taints!=null) | .taints[]')

    write_log "INFO" "tolerations_sets = $tolerations_sets"
    write_run "log_helm_sets+='$tolerations_sets'"
    write_run "helm_sets+='$tolerations_sets'"
}

# Gets environment id
# Output:
#   env_id - The environment id
# Error:
#   Exit Code 4
function get_environment_id () {
    write_log "INFO" "Getting environment id ..."

    local env_id_param=$(find_param "$general_params" "envID")
    if [[ -z "$env_id_param" ]]; then
        write_run "print_error \"installer.bash (4): envID param was not found\""
        return 4
    fi

    local env_id_value=$(echo -e "$env_id_param" | $jq_bin -r '.value')
    if [[ "$env_id_value" = null ]]; then
        write_run "print_error \"installer.bash (4): '.configuration.subtypes[0].datasources[0].params[{name=envID}].value' was not found in application JSON\""
        return 4
    fi
    
    write_log "INFO" "env_id = $env_id_value"
    write_run "env_id='$env_id_value'"
}

# Gets is Fargate was selected
# Output:
#   is_fargate - Tells is Fargate option was selected (true/false)
# Error:
#   Exit Code 11
function get_is_fargate_was_selected () {
    write_log "INFO" "Getting is Fargate was selected ..."

    local is_fargate_param=$(find_param "$general_params" "isFargate")
    if [[ -z "$is_fargate_param" ]]; then
        write_run "print_error \"installer.bash (11): isFargate param was not found\""
        return 11
    fi

    local is_fargate_value=$(echo -e "$is_fargate_param" | $jq_bin -r '.value')
    if [[ "$is_fargate_value" = null ]]; then
        write_run "print_error \"installer.bash (11): '.configuration.subtypes[0].datasources[0].params[{name=isFargate}].value' was not found in application JSON\""
        return 11
    fi
    if [[ -z "$is_fargate_value" ]]; then
        write_run "print_error \"installer.bash (11): '.configuration.subtypes[0].datasources[0].params[{name=isFargate}].value' is empty in application JSON\""
        return 11
    fi

    if ! $is_fargate_value; then
        write_log "INFO isFargate value = false"
    else
        write_log "INFO isFargate value = true"
    fi

    write_run "is_farget=$is_fargate_value"
}

# Downloads eksctl
# Output:
#   eksctl_bin - eksctl bin file in temp directory
# Error:
#   Exit Code 12
function download_eksctl () {
    write_log "INFO" "Downloading eksctl ..."

    curl -fsSL https://github.com/weaveworks/eksctl/releases/download/v0.133.0/eksctl_Linux_amd64.tar.gz > $logzio_temp_dir/eksctl.tar.gz 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"instalelr.bash (12): failed to download eksctl.\n  $err\""
        return 12
    fi

    tar -zxf $logzio_temp_dir/eksctl.tar.gz --directory $logzio_temp_dir
    write_run "eksctl_bin=\"$logzio_temp_dir/eksctl\""
}

# Creates Fargate profile with monitoring namespace on Kubernetes cluster
# Error:
#   Exit Code 13
function create_fargate_profile () {
    write_log "INFO" "Creating Fargate profile with monitoring namespace on Kubernetes cluster ..."

    local kubectl_context
    kubectl_context=$(kubectl config current-context 2>$task_error_file)
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"instalelr.bash (13): error getting kubectl current context.\n  $err\""
        return 13
    fi

    local cluster_name=$(echo -e "$kubectl_context" | cut -d'/' -f2)
    local cluster_region=$(echo -e "$kubectl_context" | cut -d':' -f4)

    local fargate_profiles
    fargate_profiles=$($eksctl_bin get fargateprofile --region "$cluster_region" --cluster "$cluster_name" 2>$task_error_file)
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"instalelr.bash (13): error checking if Fargate profile 'fp-monitoring' in region '$cluster_region' on Kubernetes cluster '$cluster_name' exists.\n  $err\""
        return 13
    fi

    local monitoringFargateProfile=$(echo -e "$fargate_profiles" | grep -e '\smonitoring')
    if [[ ! -z "$monitoringFargateProfile" ]]; then
        write_log "INFO" "Fargate profile 'fp-monitoring' in region '$cluster_region' on Kubernetes cluster '$cluster_name' is already exists"
        return
    fi

    $eksctl_bin create fargateprofile --region $cluster_region --namespace monitoring --cluster $cluster_name --name 'fp-monitoring' 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"instalelr.bash (13): error creating Fargate profile 'fp-monitoring' in region '$cluster_region' with namespace 'monitoring' on Kubernetes cluster '$cluster_name'.\n  $err\""
        return 13
    fi
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
function build_environment_tag_helm_set () {
    write_log "INFO" "Building environment tag Helm set ..."

    local helm_set=" --set logzio-k8s-telemetry.secrets.p8s_logzio_name=$env_id"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}

# Builds metrics/traces environment id helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_environment_id_helm_set () {
    write_log "INFO" "Building environment id Helm set ..."

    if [[ -z "$env_id" ]]; then
        write_log "INFO" "env_id is empty. Default value will be used."
        return
    fi

    local helm_set=" --set logzio-k8s-telemetry.secrets.env_id=$env_id"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}

# Gets logs scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 6
function get_logs_scripts () {
    write_log "INFO" "Getting logs script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/logs/linux/logs.bash > $logzio_temp_dir/logs.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (6): failed to get logs script file from logzio-agent-manifest repo.\n  $err\""
        return 6
    fi

    write_log "INFO" "Getting logs functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/logs/linux/functions.bash > $logzio_temp_dir/logs_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (6): failed to get logs functions script file from logzio-agent-manifest repo.\n  $err\""
        return 6
    fi
}

# Gets metrics scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 7
function get_metrics_scripts () {
    write_log "INFO" "Getting metrics script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/metrics/linux/metrics.bash > $logzio_temp_dir/metrics.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (7): failed to get metrics script file from logzio-agent-manifest repo.\n  $err\""
        return 7
    fi

    write_log "INFO" "Getting metrics functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/metrics/linux/functions.bash > $logzio_temp_dir/metrics_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (7): failed to get metrics functions script file from logzio-agent-manifest repo.\n  $err\""
        return 7
    fi
}

# Gets traces scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 8
function get_traces_scripts () {
    write_log "INFO" "Getting traces script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/traces/linux/traces.bash > $logzio_temp_dir/traces.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (8): failed to get traces script file from logzio-agent-manifest repo.\n  $err\""
        return 8
    fi

    write_log "INFO" "Getting traces functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/traces/linux/functions.bash > $logzio_temp_dir/traces_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (8): failed to get traces functions script file from logzio-agent-manifest repo.\n  $err\""
        return 8
    fi
}

# Runs Helm install
# Error:
#   Exit Code 9
function run_helm_install () {
    write_log "INFO" "Running Helm install ..."
    write_log "INFO" "helm_sets = $log_helm_sets"

    echo -e "helm install -n monitoring $helm_sets --create-namespace logzio-monitoring logzio-helm/logzio-monitoring" > ./logzio.helm
    
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
    write_run "print_error \"installer.bash (9): failed to run Helm install.\n  $err\""
    return 9
}

# Gets postrequisites scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 10
function get_postrequisites_scripts () {
    write_log "INFO" "Getting postrequisites script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/postrequisites/linux/postrequisites.bash > $logzio_temp_dir/postrequisites.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (10): failed to get postrequisites script file from logzio-agent-manifest repo.\n  $err\""
        return 10
    fi

    write_log "INFO" "Getting postrequisites functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/postrequisites/linux/functions.bash > $logzio_temp_dir/postrequisites_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (10): failed to get postrequisites functions script file from logzio-agent-manifest repo.\n  $err\""
        return 10
    fi
}
