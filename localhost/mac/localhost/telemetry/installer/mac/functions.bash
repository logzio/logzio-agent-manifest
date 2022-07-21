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
    write_log "INFO" "Getting general params ..."

    local general_params=$(jq -r '.configuration.subtypes[0].datasources[0].params[]' $app_json)
    if [[ "$general_params" = null ]]; then
        write_run "print_error \"installer.bash (1): .configuration.subtypes[0].datasources[0].params[] was not found in application JSON\""
        return 1
    fi
    if [[ -z "$general_params" ]]; then
        write_run "print_error \"installer.bash (1): '.configuration.subtypes[0].datasources[0].params[]' is empty in application JSON\""
        return 1
    fi

    write_log "INFO" "general_params = $general_params"
    write_run "general_params='$general_params'"
}

# Gets which products were selected (logs/metrics)
# Output:
#   is_logs_option_selected - Tells if logs option was selected (true/false)
#   logs_params - The logs params if logs option was selected
#   is_metrics_option_selected - Tells if metrics option was selected (true/false)
#   metrics_params - The metrics params if metrics option was selected
# Error:
#   Exit Code 2
function get_which_products_were_selected () {
    write_log "INFO" "Getting which products were selected ..."

    local telemetries=$(jq -c '.configuration.subtypes[0].datasources[0].telemetries[]' $app_json)
    if [[ "$telemetries" = null ]]; then
        write_run "print_error \"installer.bash (2): .configuration.subtypes[0].datasources[0].telemetries[] was not found in application JSON\""
        return 2
    fi
    if [[ -z "$telemetries" ]]; then
        write_run "print_error \"installer.bash (2): .configuration.subtypes[0].datasources[0].telemetries[] is empty in application JSON\""
        return 2
    fi

    local is_logs_option_selected=false
    local is_metrics_option_selected=false
    local index=0

    while read -r telemetry; do
        local type=$(echo "$telemetry" | jq -r '.type')
        if [[ "$type" = null ]]; then
            write_run "print_error \"installer.bash (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' was not found in application JSON\""
            return 2
        fi
        if [[ -z "$type" ]]; then
            write_run "print_error \"installer.bash (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' is empty in application JSON\""
            return 2
        fi

        local params=$(echo -e "$telemetry" | jq -r '.params[]')
        if [[ "$params" = null ]]; then
            write_run "print_error \"installer.bash (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].params[]' was not found in application JSON\""
            return 2
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

# Gets OTEL config from logzio-agent-manifest repo
# Output:
#   otel_config - The OTEL config file path
# Error:
#   Exit Code 3
function get_otel_config () {
    write_log "INFO" "Getting OTEL config file from logzio-agent-manifest repo ..."

    otel_config="./otel_config"
    curl -fsSL $repo_path/telemetry/installer/otel_config.yaml > $otel_config/logs.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.script (3): failed to get OTEL config file from logzio-agent-manifest repo.\n  $err\""
        return 3
    fi

    write_run "otel_config=\"$otel_config\""
}

# Gets logs scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 4
function get_logs_scripts () {
    write_log "INFO" "Getting logs script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/logs/mac/logs.bash > $logzio_temp_dir/logs.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.script (4): failed to get logs script file from logzio-agent-manifest repo.\n  $err\""
        return 4
    fi

    write_log "INFO" "Getting logs functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/logs/mac/functions.bash > $logzio_temp_dir/logs_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.script (4): failed to get logs functions script file from logzio-agent-manifest repo.\n  $err\""
        return 4
    fi
}

# Gets metrics scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 5
function get_metrics_scripts () {
    write_log "INFO" "Getting metrics script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/metrics/mac/metrics.bash > $logzio_temp_dir/metrics.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.script (5): failed to get metrics script file from logzio-agent-manifest repo.\n  $err\""
        return 5
    fi

    write_log "INFO" "Getting metrics functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/metrics/mac/functions.bash > $logzio_temp_dir/metrics_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.script (5): failed to get metrics functions script file from logzio-agent-manifest repo.\n  $err\""
        return 5
    fi
}

# Run otelconribcol with OTEL config
function run_otelcontribcol_binary () {
    write_log "INFO" "Running otelcontribcol binary ..."
    xterm -e "./otelcontribcol --config ./otel_config.yaml" --hold
}
