#!/bin/bash

#################################################################################################################################
#################################################### Metrics Mac Functions ######################################################
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
