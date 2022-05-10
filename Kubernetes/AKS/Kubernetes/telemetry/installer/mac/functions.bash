#!/bin/bash

#################################################################################################################################
################################################### Installer Mac Functions #####################################################
#################################################################################################################################

# Gets general params (params under datasource)
# Output:
#   general_params - The params under datasource
# Error:
#   Exit Code 1
function get_general_params () {
    local general_params=$(jq -r '.configuration.subtypes[0].datasources[0].params[]' logzio-temp/app.json)
    if [ "$general_params" = null ]; then
        echo -e "print_error \"installer.bash (1): .configuration.subtypes[0].datasources[0].params[] was not found in application JSON\"" > logzio-temp/run
        return 1
    fi
    if [ -z "$general_params" ]; then
        echo -e "print_error \"installer.bash (1): '.configuration.subtypes[0].datasources[0].params[]' is empty in application JSON\"" > logzio-temp/run
        return 1
    fi

    echo -e "general_params='$general_params'" > logzio-temp/run
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
    local telemetries=$(jq -c '.configuration.subtypes[0].datasources[0].telemetries[]' logzio-temp/app.json)
    if [ "$telemetries" = null ]; then
        echo -e "print_error \"installer.bash (2): .configuration.subtypes[0].datasources[0].telemetries[] was not found in application JSON\"" > logzio-temp/run
        return 2
    fi
    if [ -z "$telemetries" ]; then
        echo -e "print_error \"installer.bash (2): .configuration.subtypes[0].datasources[0].telemetries[] is empty in application JSON\"" > logzio-temp/run
        return 2
    fi

    local is_logs_option_selected=false
    local is_metrics_option_selected=false
    local is_traces_option_selected=false
    local index=0

    while read -r telemetry; do
        local type=$(echo "$telemetry" | jq -r '.type')
        if [ "$type" = null ]; then
            echo -e "print_error \"installer.bash (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' was not found in application JSON\"" > logzio-temp/run
            return 2
        fi
        if [ -z "$type" ]; then
            echo -e "print_error \"installer.bash (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' is empty in application JSON\"" > logzio-temp/run
            return 2
        fi

        local params=$(echo -e "$telemetry" | jq -r '.params[]')
        if [ "$params" = null ]; then
            echo -e "print_error \"installer.bash (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].params[]' was not found in application JSON\"" > logzio-temp/run
            return 2
        fi

        if [ "$type" = "LOG_ANALYTICS" ]; then
            is_logs_option_selected=true
            echo -e "logs_params='$params'" >> logzio-temp/run
        elif [ "$type" = "METRICS" ]; then
            is_metrics_option_selected=true
            echo -e "metrics_params='$params'" >> logzio-temp/run
        elif [ "$type" = "TRACING" ]; then
            is_traces_option_selected=true
            echo -e "traces_params='$params'" >> logzio-temp/run
        fi

        let "index++"
    done < <(echo -e "$telemetries")

    echo -e "is_logs_option_selected=$is_logs_option_selected" >> logzio-temp/run
    echo -e "is_metrics_option_selected=$is_metrics_option_selected" >> logzio-temp/run
    echo -e "is_traces_option_selected=$is_traces_option_selected" >> logzio-temp/run
}

# Builds tolerations Helm sets
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 3
function build_tolerations_helm_sets () {
    local is_taint_param=$(find_param "$general_params" "isTaint")
    if [ -z "$is_taint_param" ]; then
        echo -e "print_error \"installer.bash (3): isTaint param was not found\"" > logzio-temp/run
        return 3
    fi

    local is_taint_value=$(echo -e "$is_taint_param" | jq -r '.value')
    if [ "$is_taint_value" = null ]; then
        echo -e "print_error \"installer.bash (3): '.configuration.subtypes[0].datasources[0].params[{name=isTaint}].value' was not found in application JSON\"" > logzio-temp/run
        return 3
    fi
    if [ -z "$is_taint_value" ]; then
        echo -e "print_error \"installer.bash (3): '.configuration.subtypes[0].datasources[0].params[{name=isTaint}].value' is empty in application JSON\"" > logzio-temp/run
        return 3
    fi

    if ! $is_taint_value; then
        return
    fi
                    
    local items=$(kubectl get nodes -o json | jq -r '.items')
    if [ "$items" = null ]; then
        echo -e "print_error \"installer.bash (3): '.items[]' was not found in kubectl get nodes JSON\"" > logzio-temp/run
        return 3
    fi

    local tolerations_sets=""
    local index=0

    while read -r taint; do
        local key=$(echo -e "$taint" | jq -r '.key')
        if [ "$key" = null ]; then
            echo -e "print_error \"installer.bash (3): '.items[{item}].key' was not found in kubectl get nodes JSON\"" > logzio-temp/run
            return 3
        fi

        local effect=$(echo -e "$taint" | jq -r '.effect')
        if [ "$effect" = null ]; then
            echo -e "print_error \"installer.bash (3): '.items[{item}].effect' was not found in kubectl get nodes JSON\"" > logzio-temp/run
            return 3
        fi

        local operator="Exists"
        local value=$(echo -e "$taint" | jq -r '.value')
        if [ "$value" != null ]; then
            operator="Equal"

            if $is_logs_option_selected; then
                tolerations_sets+=" --set-string logzio-fluentd.daemonset.tolerations[$index].value=$value"
                tolerations_sets+=" --set-string logzio-fluentd.windowsDaemonset.tolerations[$index].value=$value"
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
            tolerations_sets+=" --set-string logzio-fluentd.windowsDaemonset.tolerations[$index].key=$key"
            tolerations_sets+=" --set-string logzio-fluentd.windowsDaemonset.tolerations[$index].operator=$operator"
            tolerations_sets+=" --set-string logzio-fluentd.windowsDaemonset.tolerations[$index].effect=$effect"
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
    echo -e "helm_sets+='$tolerations_sets'" > logzio-temp/run
}

# Builds enable metrics or traces Helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_enable_metrics_or_traces_helm_set () {
    local helm_set+=" --set metricsOrTraces.enabled=true"
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run
}

# Builds metrics/traces environment tag helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_environment_tag_helm_set () {
    local env_tag=$(jq -r '.id' logzio-temp/app.json)       ######################## Change the id to something else?
    local helm_set=" --set logzio-k8s-telemetry.secrets.p8s_logzio_name=$env_tag"
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run
}

# Gets logs scripts from logzio-agent-scripts repo
# Error:
#   Exit Code 4
function get_logs_scripts () {
    curl -fsSL $repo_path/telemetry/logs/mac/logs.bash > logzio-temp/logs.bash 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "print_error \"installer.script (4): failed to get logs script file from logzio-agent-scripts repo\"" > logzio-temp/run
        return 4
    fi

    curl -fsSL $repo_path/telemetry/logs/mac/functions.bash > logzio-temp/logs_functions.bash 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "print_error \"installer.script (4): failed to get logs functions script file from logzio-agent-scripts repo\"" > logzio-temp/run
        return 4
    fi
}

# Gets metrics scripts from logzio-agent-scripts repo
# Error:
#   Exit Code 5
function get_metrics_scripts () {
    curl -fsSL $repo_path/telemetry/metrics/mac/metrics.bash > logzio-temp/metrics.bash 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "print_error \"installer.script (5): failed to get metrics script file from logzio-agent-scripts repo\"" > logzio-temp/run
        return 5
    fi

    curl -fsSL $repo_path/telemetry/metrics/mac/functions.bash > logzio-temp/metrics_functions.bash 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "print_error \"installer.script (5): failed to get metrics functions script file from logzio-agent-scripts repo\"" > logzio-temp/run
        return 5
    fi
}

# Gets traces scripts from logzio-agent-scripts repo
# Error:
#   Exit Code 6
function get_traces_scripts () {
    curl -fsSL $repo_path/telemetry/traces/mac/traces.bash > logzio-temp/traces.bash 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "print_error \"installer.script (6): failed to get traces script file from logzio-agent-scripts repo\"" > logzio-temp/run
        return 6
    fi

    curl -fsSL $repo_path/telemetry/traces/mac/functions.bash > logzio-temp/traces_functions.bash 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "print_error \"installer.script (6): failed to get traces functions script file from logzio-agent-scripts repo\"" > logzio-temp/run
        return 6
    fi
}

# Runs Helm install
# Error:
#   Exit Code 7
function run_helm_install () {
    helm install -n monitoring $helm_sets --create-namespace logzio-monitoring logzio-helm/logzio-monitoring > logzio-temp/task_result 2>&1
    if [ $? -ne 0 ]; then
        local result=$(cat logzio-temp/task_result)
        echo -e "echo -e \"$result\""  > logzio-temp/run
        echo -e "print_error \"installer.bash (7): failed to run Helm install\"" >> logzio-temp/run
        return 7
    fi
}
