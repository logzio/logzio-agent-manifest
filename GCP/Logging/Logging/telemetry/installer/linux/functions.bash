#!/bin/bash

#################################################################################################################################
################################################## Installer Linux Functions ####################################################
#################################################################################################################################



# Gets the selected products (logs/metrics)
# Output:
#   is_logs_option_selected - Tells if logs option was selected (true/false)
#   logs_params - The logs params if logs option was selected
#   is_metrics_option_selected - Tells if metrics option was selected (true/false)
#   metrics_params - The metrics params if metrics option was selected
# Error:
#   Exit Code 1
function get_selected_products () {
    write_log "INFO" "Getting the selected products ..."

    local telemetries=$(jq -c '.configuration.subtypes[0].datasources[0].telemetries[]' $app_json)
    if [[ "$telemetries" = null ]]; then
        write_run "print_error \"installer.bash (1): .configuration.subtypes[0].datasources[0].telemetries[] was not found in application JSON\""
        return 1
    fi
    if [[ -z "$telemetries" ]]; then
        write_run "print_error \"installer.bash (1): .configuration.subtypes[0].datasources[0].telemetries[] is empty in application JSON\""
        return 1
    fi

    local is_logs_option_selected=false
    local is_metrics_option_selected=false
    local index=0

    while read -r telemetry; do
        local type=$(echo "$telemetry" | jq -r '.type')
        if [[ "$type" = null ]]; then
            write_run "print_error \"installer.bash (1): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' was not found in application JSON\""
            return 1
        fi
        if [[ -z "$type" ]]; then
            write_run "print_error \"installer.bash (1): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' is empty in application JSON\""
            return 1
        fi

        local params=$(echo -e "$telemetry" | jq -r '.params[]')
        if [[ "$params" = null ]]; then
            write_run "print_error \"installer.bash (1): '.configuration.subtypes[0].datasources[0].telemetries[$index].params[]' was not found in application JSON\""
            return 1
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
        fi

        let "index++"
    done < <(echo -e "$telemetries")

    write_run "is_logs_option_selected=$is_logs_option_selected"
    write_run "is_metrics_option_selected=$is_metrics_option_selected"
}


# Gets logs scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 5
function get_logs_scripts () {
    write_log "INFO" "Getting logs script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/logs/linux/logs.bash > $logzio_temp_dir/logs.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (5): failed to get logs script file from logzio-agent-manifest repo.\n  $err\""
        return 5
    fi

    write_log "INFO" "Getting logs functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/logs/linux/functions.bash > $logzio_temp_dir/logs_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (5): failed to get logs functions script file from logzio-agent-manifest repo.\n  $err\""
        return 5
    fi
}
