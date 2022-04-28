#!/bin/bash

#################################################################################################################################
################################################### Installer Mac Functions #####################################################
#################################################################################################################################

# Gets general params (params under datasource)
function get_general_params () {
    echo -e "general_params=$(jq -r '.configuration.subtypes[0].datasources[0].params[]' logzio-temp/app.json)" > logzio-temp/run_post_task
    #general_params=$(jq -r '.configuration.subtypes[0].datasources[0].params[]' logzio-temp/app.json)
}

# Gets which products were selected (logs/metrics/tracing)
function get_which_products_were_selected () {
    #echo "Getting which products were selected..."
    while read -r telemetry; do
        local type=$(echo "$telemetry" | jq -r '.type')

        if [ "$type" = "LOG_ANALYTICS" ]; then
            #logs_params=$(echo "$telemetry" | jq -r '.params[]')
            echo -e "is_logs_option_selected=true" >> logzio-temp/run_post_task
            echo -e "logs_params=$(echo \"$telemetry\" | jq -r '.params[]')" >> logzio-temp/run_post_task
        elif [ "$type" = "METRICS" ]; then
            #metrics_params=$(echo "$telemetry" | jq -r '.params[]')
            echo -e "is_metrics_option_selected=true" >> logzio-temp/run_post_task
            echo -e "metrics_params=$(echo \"$telemetry\" | jq -r '.params[]')" >> logzio-temp/run_post_task
        elif [ "$type" = "TRACING" ]; then
            #tracing_params=$(echo "$telemetry" | jq -r '.params[]')
            echo -e "is_tracing_option_selected=true" >> logzio-temp/run_post_task
            echo -e "tracing_params=$(echo \"$telemetry\" | jq -r '.params[]')" >> logzio-temp/run_post_task
        fi
    done < <(jq -c '.configuration.subtypes[0].datasources[0].telemetries[]' logzio-temp/app.json)
}