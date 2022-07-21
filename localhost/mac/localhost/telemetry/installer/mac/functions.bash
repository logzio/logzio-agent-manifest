#!/bin/bash

#################################################################################################################################
################################################### Installer Mac Functions #####################################################
#################################################################################################################################

# Gets which products were selected (logs/metrics)
# Output:
#   is_logs_option_selected - Tells if logs option was selected (true/false)
#   logs_params - The logs params if logs option was selected
#   is_metrics_option_selected - Tells if metrics option was selected (true/false)
#   metrics_params - The metrics params if metrics option was selected
# Error:
#   Exit Code 1
function get_which_products_were_selected () {
    write_log "INFO" "Getting which products were selected ..."

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

# Gets otelcol-contrib binary
# Error:
#   Exit Code 2
function get_otelcol_contrib_binary () {
    write_log "INFO" "Getting otelcol-contrib binary ..."
    curl -fsSL https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.55.0/otelcol-contrib_0.55.0_darwin_amd64.tar.gz > $logzio_temp_dir/otelcol-contrib.tar.gz 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"instalelr.bash (2): failed to get otelcol-contrib binary file from open-telemetry repo.\n  $err\""
        return 2
    fi

    tar -zxf $logzio_temp_dir/otelcol-contrib.tar.gz otelcol-contrib
}

# Gets OTEL config from logzio-agent-manifest repo
# Output:
#   otel_config - The OTEL config file path
# Error:
#   Exit Code 3
function get_otel_config () {
    write_log "INFO" "Getting OTEL config file from logzio-agent-manifest repo ..."

    otel_config="./otel_config"
    curl -fsSL $repo_path/telemetry/installer/otel_config.yaml > $otel_config 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (3): failed to get OTEL config file from logzio-agent-manifest repo.\n  $err\""
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
        write_run "print_error \"installer.bash (4): failed to get logs script file from logzio-agent-manifest repo.\n  $err\""
        return 4
    fi

    write_log "INFO" "Getting logs functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/logs/mac/functions.bash > $logzio_temp_dir/logs_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (4): failed to get logs functions script file from logzio-agent-manifest repo.\n  $err\""
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
        write_run "print_error \"installer.bash (5): failed to get metrics script file from logzio-agent-manifest repo.\n  $err\""
        return 5
    fi

    write_log "INFO" "Getting metrics functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/metrics/mac/functions.bash > $logzio_temp_dir/metrics_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (5): failed to get metrics functions script file from logzio-agent-manifest repo.\n  $err\""
        return 5
    fi
}

# Run otelcol-contrib binary with OTEL config
# Error:
#   Exit Code 6
function run_otelcol_contrib_binary () {
    write_log "INFO" "Running otelcol-contrib binary ..."
    write_log "INFO" "OTEL config =\n$(cat $otel_config)"

    local otel_binary_full_path=$(realpath ./otelcol-contrib)
    local otel_config_full_path=$(realpath $otel_config)

    osascript -e "tell app \"Terminal\" to do script \"$otel_binary_full_path --config $otel_config_full_path\"" >/dev/null 2>$task_error_file
    if [[ $? -eq 0 ]]; then
        return
    fi

    local err=$(cat $task_error_file)
    write_run "print_error \"installer.bash (6): failed to run otelcol-contrib binary in another terminal.\n  $err\""
    return 6
}
