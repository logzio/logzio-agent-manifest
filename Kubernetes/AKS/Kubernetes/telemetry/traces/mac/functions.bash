#!/bin/bash

#################################################################################################################################
#################################################### Traces Mac Functions #######################################################
#################################################################################################################################

# Builds enable traces Helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_enable_traces_helm_set () {
    local helm_set=" --set logzio-k8s-telemetry.traces.enabled=true"
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run_post_task
}

# Builds Logz.io traces token Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 2
function build_logzio_traces_token_helm_set () {
    local shipping_token=$(jq -r '.shippingTokens.TRACING' logzio-temp/app.json)
    if [ "$shipping_token" = null ]; then
        echo -e "print_error \"metrics.bash (2): '.shippingTokens.TRACING' was not found in application JSON\"" > logzio-temp/run
        return 2
    fi
    if [ -z "$shipping_token" ]; then
        echo -e "print_error \"metrics.bash (2): '.shippingTokens.TRACING' is empty in application JSON\"" > logzio-temp/run
        return 2
    fi
    
    local helm_set=" --set logzio-k8s-telemetry.secrets.TracesToken=$shipping_token"
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run
}

# Builds Logz.io region Helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_logzio_region_helm_set () {
    local region="us"                                       ######################## Get region from app.json
    local helm_set=" --set secrets.LogzioRegion=$region"
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run
}
