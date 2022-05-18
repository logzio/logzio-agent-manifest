#!/bin/bash

#################################################################################################################################
#################################################### Traces Mac Functions #######################################################
#################################################################################################################################

# Builds enable traces Helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_enable_traces_helm_set () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Building enable traces Helm set ..." >> logzio_agent.log

    local helm_set=" --set logzio-k8s-telemetry.traces.enabled=true"
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] helm_set = $helm_set" >> logzio_agent.log
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run
}

# Builds Logz.io traces token Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 2
function build_logzio_traces_token_helm_set () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Building Logz.io traces token Helm set ..." >> logzio_agent.log

    local shipping_token=$(jq -r '.shippingTokens.TRACING' logzio-temp/app.json)
    if [[ "$shipping_token" = null ]]; then
        echo -e "print_error \"metrics.bash (2): '.shippingTokens.TRACING' was not found in application JSON\"" > logzio-temp/run
        return 2
    fi
    if [[ -z "$shipping_token" ]]; then
        echo -e "print_error \"metrics.bash (2): '.shippingTokens.TRACING' is empty in application JSON\"" > logzio-temp/run
        return 2
    fi
    
    local helm_set=" --set logzio-k8s-telemetry.secrets.TracesToken=$shipping_token"
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] helm_set = $helm_set" >> logzio_agent.log
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run
}

# Builds Logz.io region Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Error Code 3
function build_logzio_region_helm_set () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Building Logz.io region Helm set ..." >> logzio_agent.log

    local listener_url=$(jq -r '.listenerUrl' logzio-temp/app.json)
    if [[ "$listener_url" = null ]]; then
        echo -e "print_error \"metrics.bash (1): '.listenerUrl' was not found in application JSON\"" > logzio-temp/run
        return 3
    fi
    if [[ -z "$listener_url" ]]; then
        echo -e "print_error \"metrics.bash (1): '.listenerUrl' is empty in application JSON\"" > logzio-temp/run
        return 3
    fi

    local region="us"
    if [[ "$listener_url" = *"-"* ]]; then
        local listener_part=$(cut -d "." -f1 <<< "$listener_url")
        region=$(cut -d "-" -f2 <<< "$listener_part")
    fi
    
    local helm_set=" --set logzio-k8s-telemetry.secrets.LogzioRegion=$region"
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] helm_set = $helm_set" >> logzio_agent.log
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run
}
