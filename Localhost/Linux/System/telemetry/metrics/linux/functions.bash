#!/bin/bash

#################################################################################################################################
################################################### Metrics Linux Functions #####################################################
#################################################################################################################################

# Gets Logz.io metrics listener URL
# Output:
#   metrics_listener_url - Logz.io metrics listener URL
# Error:
#   Exit Code 1
function get_logzio_metrics_listener_url () {
    write_log "INFO" "Getting Logz.io metrics listener URL ..."

    local listener_url=$(jq -r '.listenerUrl' $app_json)
    if [[ "$listener_url" = null ]]; then
        write_run "print_error \"metrics.bash (1): '.listenerUrl' was not found in application JSON\""
        return 1
    fi
    if [[ -z "$listener_url" ]]; then
        write_run "print_error \"metrics.bash (1): '.listenerUrl' is empty in application JSON\""
        return 1
    fi

    listener_url="https://$listener_url:8053"
    write_log "INFO" "metrics_lister_url = $listener_url"
    write_run "metrics_listener_url=\"$listener_url\""
}

# Gets Logz.io metrics token
# Output:
#   metrics_token - Logz.io metrics token
# Error:
#   Exit Code 2
function get_logzio_metrics_token () {
    write_log "INFO" "Getting Logz.io metrics token ..."

    local shipping_token=$(jq -r '.shippingTokens.METRICS' $app_json)
    if [[ "$shipping_token" = null ]]; then
        write_run "print_error \"metrics.bash (2): '.shippingTokens.METRICS' was not found in application JSON\""
        return 2
    fi
    if [[ -z "$shipping_token" ]]; then
        write_run "print_error \"metrics.bash (2): '.shippingTokens.METRICS' is empty in application JSON\""
        return 2
    fi

    write_log "INFO" "metrics_token = $shipping_token"
    write_run "metrics_token=\"$shipping_token\""
}

# Adds metrics receivers to OTEL config
# Error:
#   Exit Code 3
function add_metrics_receivers_to_otel_config () {
    write_log "INFO" "Adding metrics receivers to OTEL config ..."

    curl -fsSL $repo_path/telemetry/metrics/metrics_otel_receivers.yaml > $logzio_temp_dir/metrics_otel_receivers.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"metrics.bash (3): failed to get metrics_otel_receivers yaml file from logzio-agent-manifest repo.\n  $err\""
        return 3
    fi

    $yq_bin eval-all -i 'select(fileIndex==0).receivers += select(fileIndex==1) | select(fileIndex==0)' $otel_config $logzio_temp_dir/metrics_otel_receivers.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"metrics.bash (3): failed to add metrics receivers to OTEL config file.\n  $err\""
        return 3
    fi

    $yq_bin -i '.service.pipelines.metrics.receivers += "hostmetrics"' $otel_config 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"metrics.bash (3): failed to add service pipeline metrics receiver to OTEL config file.\n  $err\""
        return 3
    fi
}

# Adds metrics exporter to OTEL config
# Error:
#   Exit Code 4
function add_metrics_exporter_to_otel_config () {
    write_log "INFO" "Adding metrics exporter to OTEL config ..."

    curl -fsSL $repo_path/telemetry/metrics/metrics_otel_exporter.yaml > $logzio_temp_dir/metrics_otel_exporter.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"metrics.bash (4): failed to get metrics_otel_exporter yaml file from logzio-agent-manifest repo.\n  $err\""
        return 4
    fi

    $yq_bin -i ".prometheusremotewrite.endpoint = \"$metrics_listener_url\"" $logzio_temp_dir/metrics_otel_exporter.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"metrics.bash (4): failed to insert Logz.io metrics listener URL into metrics_otel_exporter yaml file.\n  $err\""
        return 4
    fi

    $yq_bin -i ".prometheusremotewrite.headers.Authorization = \"Bearer $metrics_token\"" $logzio_temp_dir/metrics_otel_exporter.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"metrics.bash (4): failed to insert Logz.io metrics token into metrics_otel_exporter yaml file.\n  $err\""
        return 4
    fi

    $yq_bin eval-all -i 'select(fileIndex==0).exporters += select(fileIndex==1) | select(fileIndex==0)' $otel_config $logzio_temp_dir/metrics_otel_exporter.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"metrics.bash (4): failed to add metrics exporter to OTEL config file.\n  $err\""
        return 4
    fi

    $yq_bin -i '.service.pipelines.metrics.exporters += "prometheusremotewrite"' $otel_config 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"metrics.bash (4): failed to add service pipeline metrics exporter to OTEL config file.\n  $err\""
        return 4
    fi
}

# Adds metrics address to OTEL config
# Error:
#   Exit Code 5
function add_metrics_address_to_otel_config () {
    write_log "INFO" "Adding metrics address to OTEL config ..."

    local port=8888
    local result=$(lsof -i -n -P | grep TCP | grep LISTEN | grep 127.0.0.1:$port)
    if [[ ! -z "$result" ]]; then
        while true; do
            let "port++"
            result=$(lsof -i -n -P | grep TCP | grep LISTEN | grep 127.0.0.1:$port)
            if [[ -z "$result" ]]; then
                break
            fi
        done
    fi

    $yq_bin -i ".service.telemetry.metrics.address = \"localhost:$port\"" $otel_config 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"metrics.bash (5): failed to add service telemetry metrics address to OTEL config file.\n  $err\""
        return 5
    fi
}
