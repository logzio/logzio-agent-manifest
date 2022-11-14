#!/bin/bash

#################################################################################################################################
################################################## Installer Linux Functions ####################################################
#################################################################################################################################

# Checks if Logz.io OTEL collector service exist
# Output:
#   is_service_exist - Tells if Logz.io OTEL collector service exist
function is_logzio_otel_collector_service_exist () {
    write_log "INFO" "Checking if Logz.io OTEL collector service exist ..."

    local service=$(systemctl | grep logzioOTELCollector)
    if [[ -z $service ]]; then
        write_log "is_service_exist = false"
        write_run "is_service_exist=false"
        return
    fi

    write_log "is_service_exist = true"
    write_run "is_service_exist=true"
}

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

    local telemetries=$($jq_bin -c '.configuration.subtypes[0].datasources[0].telemetries[]' $app_json)
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
        local type=$(echo "$telemetry" | $jq_bin -r '.type')
        if [[ "$type" = null ]]; then
            write_run "print_error \"installer.bash (1): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' was not found in application JSON\""
            return 1
        fi
        if [[ -z "$type" ]]; then
            write_run "print_error \"installer.bash (1): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' is empty in application JSON\""
            return 1
        fi

        local params=$(echo -e "$telemetry" | $jq_bin -r '.params[]')
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

# Creates Logz.io opt directory
# Output:
#   logzio_opt_dir - The Logz.io opt directory path
function create_logzio_opt_dir () {
    write_log "INFO" "Creating Logz.io opt directory ..."

    logzio_opt_dir="/opt/logzio-otel-collector"
    mkdir -p $logzio_opt_dir
    write_run "logzio_opt_dir=\"$logzio_opt_dir\""
}

# Gets OTEL collector binary
# Output:
#   otel_bin - The OTEL collector binary file path
# Error:
#   Exit Code 2
function get_otel_collector_binary () {
    write_log "INFO" "Getting OTEL collector binary ..."
    curl -fsSL https://github.com/logzio/otel-collector-distro/releases/download/v0.56.1/otelcol-logzio-linux_amd64.tar.gz > $logzio_temp_dir/otelcol-logzio.tar.gz 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"instalelr.bash (2): failed to get OTEL collector binary file from Logz.io repo.\n  $err\""
        return 2
    fi

    otel_bin="$logzio_opt_dir/otelcol-logzio-linux_amd64"
    tar -zxf $logzio_temp_dir/otelcol-logzio.tar.gz --directory $logzio_opt_dir
    write_run "otel_bin=\"$otel_bin\""
}

# Gets OTEL config from logzio-agent-manifest repo
# Output:
#   otel_config - The OTEL config file path
# Error:
#   Exit Code 3
function get_otel_config () {
    write_log "INFO" "Getting OTEL config file from logzio-agent-manifest repo ..."

    otel_config="$logzio_opt_dir/otel_config.yaml"
    curl -fsSL $repo_path/telemetry/installer/otel_config.yaml > $otel_config 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (3): failed to get OTEL config file from logzio-agent-manifest repo.\n  $err\""
        return 3
    fi

    write_run "otel_config=\"$otel_config\""
}

# Gets service file from logzio-agent-manifest repo
# Output:
#   service_name - The Logz.io OTEL collector service name
# Error:
#   Exit Code 4
function get_logzio_otel_collector_service_file () {
    write_log "INFO" "Getting Logz.io OTEL collector service file ..."

    service_name="logzioOTELCollector"
    curl -fsSL $repo_path/telemetry/installer/logzioOTELCollector.service > /etc/systemd/system/$service_name.service 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (4): failed to get Logz.io OTEL collector service file from logzio-agent-manifest repo.\n  $err\""
        return 4
    fi

    write_run "service_name=\"$service_name\""
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

# Gets metrics scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 6
function get_metrics_scripts () {
    write_log "INFO" "Getting metrics script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/metrics/linux/metrics.bash > $logzio_temp_dir/metrics.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (6): failed to get metrics script file from logzio-agent-manifest repo.\n  $err\""
        return 6
    fi

    write_log "INFO" "Getting metrics functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/metrics/linux/functions.bash > $logzio_temp_dir/metrics_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"installer.bash (6): failed to get metrics functions script file from logzio-agent-manifest repo.\n  $err\""
        return 6
    fi
}

# Runs Logz.io OTEL collector service
# Error:
#   Exit Code 7
function run_logzio_otel_collector_service () {
    write_log "INFO" "Running Logz.io OTEL collector service ..."
    write_log "INFO" "OTEL config =\n$(cat $otel_config)"

    systemctl start $service_name >/dev/null 2>$task_error_file
    local err=$(cat $task_error_file)
    if [[ ! -z "$err" ]]; then
        write_run "print_error \"installer.bash (7): failed to start Logz.io OTEL collector service.\n  $err\""
        return 7
    fi

    is_running=$(systemctl status $service_name | grep "$service_name.service failed")
    if [[ -z "$is_running" ]]; then
        return
    fi

    write_run "print_error \"installer.bash (7): failed to run Logz.io OTEL collector service.\n  Run `sudo systemctl status -l $service_name` to see the error.\""
    return 7
}
