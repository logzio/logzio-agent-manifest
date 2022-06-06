#!/bin/bash

#################################################################################################################################
#################################################### Traces Mac Functions #######################################################
#################################################################################################################################

# Builds enable traces Helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_enable_traces_helm_set () {
    write_log "INFO" "Building enable traces Helm set ..."

    local helm_set=" --set logzio-k8s-telemetry.traces.enabled=true"
    write_log "INFO" "helm_set = $helm_set"
    write_run "helm_sets+='$helm_set'"
}

# Builds Logz.io traces token Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 2
function build_logzio_traces_token_helm_set () {
    write_log "INFO" "Building Logz.io traces token Helm set ..."

    local shipping_token=$(jq -r '.shippingTokens.TRACING' $app_json)
    if [[ "$shipping_token" = null ]]; then
        write_run "print_error \"metrics.bash (2): '.shippingTokens.TRACING' was not found in application JSON\""
        return 2
    fi
    if [[ -z "$shipping_token" ]]; then
        write_run "print_error \"metrics.bash (2): '.shippingTokens.TRACING' is empty in application JSON\""
        return 2
    fi
    
    local helm_set=" --set logzio-k8s-telemetry.secrets.TracesToken=$shipping_token"
    write_log "INFO" "helm_set = $helm_set"
    write_run "helm_sets+='$helm_set'"
}

# Builds Logz.io region Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Error Code 3
function build_logzio_region_helm_set () {
    write_log "INFO" "Building Logz.io region Helm set ..."

    local listener_url=$(jq -r '.listenerUrl' $app_json)
    if [[ "$listener_url" = null ]]; then
        write_run "print_error \"metrics.bash (1): '.listenerUrl' was not found in application JSON\""
        return 3
    fi
    if [[ -z "$listener_url" ]]; then
        write_run "print_error \"metrics.bash (1): '.listenerUrl' is empty in application JSON\""
        return 3
    fi

    local region="us"
    if [[ "$listener_url" = *"-"* ]]; then
        local listener_part=$(cut -d "." -f1 <<< "$listener_url")
        region=$(cut -d "-" -f2 <<< "$listener_part")
    fi
    
    local helm_set=" --set logzio-k8s-telemetry.secrets.LogzioRegion=$region"
    write_log "INFO" "helm_set = $helm_set"
    write_run "helm_sets+='$helm_set'"
}
