#!/bin/bash

#################################################################################################################################
################################################### Metrics Linux Functions #####################################################
#################################################################################################################################

# Builds enable metrics Helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_enable_metrics_helm_set () {
    write_log "INFO" "Building enable metrics Helm set ..."

    local helm_set=" --set logzio-k8s-telemetry.metrics.enabled=true"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}

# Builds Logz.io metrics listener URL Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 1
function build_logzio_metrics_listener_url_helm_set () {
    write_log "INFO" "Building Logz.io metrics listener URL Helm set ..."

    local listener_url=$($jq_bin -r '.listenerUrl' $app_json)
    if [[ "$listener_url" = null ]]; then
        write_run "print_error \"metrics.bash (1): '.listenerUrl' was not found in application JSON\""
        return 1
    fi
    if [[ -z "$listener_url" ]]; then
        write_run "print_error \"metrics.bash (1): '.listenerUrl' is empty in application JSON\""
        return 1
    fi

    listener_url="https://$listener_url:8053"
    local helm_set=" --set logzio-k8s-telemetry.secrets.ListenerHost=$listener_url"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}

# Builds Logz.io metrics token Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 2
function build_logzio_metrics_token_helm_set () {
    write_log "INFO" "Building Logz.io metrics token Helm set ..."

    local shipping_token=$($jq_bin -r '.shippingTokens.METRICS' $app_json)
    if [[ "$shipping_token" = null ]]; then
        write_run "print_error \"metrics.bash (2): '.shippingTokens.METRICS' was not found in application JSON\""
        return 2
    fi
    if [[ -z "$shipping_token" ]]; then
        write_run "print_error \"metrics.bash (2): '.shippingTokens.METRICS' is empty in application JSON\""
        return 2
    fi
    
    local helm_set=" --set logzio-k8s-telemetry.secrets.MetricsToken=$shipping_token"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}

# Gets if metrics filter was selected
# Output:
#   is_filter - Tells if metrics filter was selected (true/false)
# Error:
#   Exit Code 3
function get_is_metrics_filter_was_selected () {
    write_log "INFO" "Getting if metrics filter was selected ..."

    local is_filter_param=$(find_param "$metrics_params" "isFilter")
    if [[ -z "$is_filter_param" ]]; then
        write_run "print_error \"metrics.bash (3): isFilter param was not found\""
        return 3
    fi

    local is_filter_value=$(echo -e "$is_filter_param" | $jq_bin -r '.value')
    if [[ "$is_filter_value" = null ]]; then
        write_run "print_error \"metrics.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=METRICS}].params[{name=isFilter}].value' was not found in application JSON\""
        return 3
    fi
    if [[ -z "$is_filter_value" ]]; then
        write_run "print_error \"installer.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=METRICS}].params[{name=isFilter}].value' is empty in application JSON\""
        return 3
    fi

    write_log "INFO" "is_filter = $is_filter_value"
    write_run "is_filter=$is_filter_value"
}

# Builds enable metrics filter Helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_enable_metrics_filter_helm_set () {
    write_log "INFO" "Building enable metrics filter Helm set ..."
    
    local helm_set=" --set logzio-k8s-telemetry.enableMetricsFilter.eks=true"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}

# Builds Fargate collector mode standalone Helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_fargate_collector_mode_standalone_helm_set () {
    write_log "INFO" "Building Fargate collector standalone Helm set ..."

    local helm_set=" --set logzio-k8s-telemetry.collector.mode=standalone"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}
