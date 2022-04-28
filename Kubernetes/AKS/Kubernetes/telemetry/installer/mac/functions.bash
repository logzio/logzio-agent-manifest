#!/bin/bash

#################################################################################################################################
################################################### Installer Mac Functions #####################################################
#################################################################################################################################

# Gets general params (params under datasource)
# Error
#   Exit Code 1
function get_general_params () {
    general_params=$(jq -c '.configuration.subtypes[0].datasources[0].params[]' logzio-temp/app.json 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo -e "print_error \"installer.bash (1): '.configuration.subtypes[0].datasources[0].params[]' key not found in app JSON\"" > logzio-temp/run_post_task
        return 1
    fi

    echo -e "general_params=\"$general_params\"" > logzio-temp/run_post_task
}

# Gets which products were selected (logs/metrics/tracing)
function get_which_products_were_selected () {
    while read -r telemetry; do
        local type=$(echo "$telemetry" | jq -r '.type')

        if [ "$type" = "LOG_ANALYTICS" ]; then
            echo -e "is_logs_option_selected=true" >> logzio-temp/run_post_task
            echo -e "logs_params=\$(echo -e \"$telemetry\" | jq -r '.params[]')" >> logzio-temp/run_post_task
        elif [ "$type" = "METRICS" ]; then
            echo -e "is_metrics_option_selected=true" >> logzio-temp/run_post_task
            echo -e "metrics_params=\$(echo -e \"$telemetry\" | jq -r '.params[]')" >> logzio-temp/run_post_task
        elif [ "$type" = "TRACING" ]; then
            echo -e "is_tracing_option_selected=true" >> logzio-temp/run_post_task
            echo -e "tracing_params=\$(echo -e \"$telemetry\" | jq -r '.params[]')" >> logzio-temp/run_post_task
        fi
    done < <(jq -c '.configuration.subtypes[0].datasources[0].telemetries[]' logzio-temp/app.json)
}