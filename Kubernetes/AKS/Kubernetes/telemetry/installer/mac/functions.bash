#!/bin/bash

#################################################################################################################################
################################################### Installer Mac Functions #####################################################
#################################################################################################################################

# Gets general params (params under datasource)
# Error:
#   Exit Code 1
function get_general_params () {
    general_params=$(jq -r '.configuration.subtypes[0].datasources[0].params[]' logzio-temp/app.json 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo -e "print_error \"installer.bash (1): '.configuration.subtypes[0].datasources[0].params[]' key not found in app JSON\"" > logzio-temp/run_post_task
        return 1
    fi

    echo -e "general_params='$general_params'" > logzio-temp/run_post_task
}

# Gets which products were selected (logs/metrics/tracing)
# Error:
#   Exit Code 2
function get_which_products_were_selected () {
    while read -r telemetry; do
        local type=$(echo "$telemetry" | jq -r '.type')
        local params=$(echo -e "$telemetry" | jq -r '.params[]')
        if [ $? -ne 0 ]; then
            echo -e "print_error \"installer.bash (2): $type '.params[]' key not found in app JSON\"" >> logzio-temp/run_post_task
            return 2
        fi

        if [ "$type" = "LOG_ANALYTICS" ]; then
            echo -e "is_logs_option_selected=true" >> logzio-temp/run_post_task
            echo -e "logs_params='$params'" >> logzio-temp/run_post_task
        elif [ "$type" = "METRICS" ]; then
            echo -e "is_metrics_option_selected=true" >> logzio-temp/run_post_task
            echo -e "metrics_params='$params'" >> logzio-temp/run_post_task
        elif [ "$type" = "TRACING" ]; then
            echo -e "is_tracing_option_selected=true" >> logzio-temp/run_post_task
            echo -e "tracing_params='$params'" >> logzio-temp/run_post_task
        fi
    done < <(jq -c '.configuration.subtypes[0].datasources[0].telemetries[]' logzio-temp/app.json)
}

# Gets tolerations Helm sets
# Error:
#   Exit Code 3
function get_tolerations_helm_sets () {
    local is_taint_param=$(find_param "$general_params" "isTaint")
    if [ -z "$is_taint_param" ]; then
        echo -e "print_error \"installer.bash (3): isTaint param was not found\"" >> logzio-temp/run_post_task
        return 3
    fi

    local is_taint=$(echo -e "$is_taint_param" | jq -r '.value')
    if ! $is_taint; then
        return
    fi
                    
    local items=$(kubectl get nodes -o json | jq -r '.items')
    local tolerations_sets=""
    local index=0

    while read -r taint; do
        local key=$(echo -e "$taint" | jq -r '.key')
        local operator="Exists"
        local effect=$(echo -e "$taint" | jq -r '.effect')

        if $(echo "$taint" | jq -r 'has("value")'); then
            local value=$(echo -e "$taint" | jq -r '.value')
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

        let "index+=1"
    done < <(echo -e "$items" | jq -c '.[] | .spec | select(.taints!=null) | .taints[]')
    echo -e "helm_sets+='$tolerations_sets'" > logzio-temp/run_post_task
}

# Gets enable metrics or traces Helm set
function get_enable_metrics_or_traces_helm_set () {
    local helm_set+=" --set metricsOrTraces.enabled=true"
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run_post_task
}

# Gets metrics/traces environment tag helm set
function get_environment_tag_helm_set () {
    local env_tag=$(jq -r '.id' logzio-temp/app.json)
    local helm_set=" --set logzio-k8s-telemetry.secrets.p8s_logzio_name=$env_tag"
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run_post_task
}
