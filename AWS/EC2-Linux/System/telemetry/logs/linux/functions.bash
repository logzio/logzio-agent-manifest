#!/bin/bash

#################################################################################################################################
#################################################### Logs Linux Functions #######################################################
#################################################################################################################################

# Gets Logz.io region
# Output:
#   logzio_region - Logz.io region
# Error:
#   Exit Code 1
function get_logzio_region () {
    write_log "INFO" "Getting Logz.io region ..."

    local listener_url=$($jq_bin -r '.listenerUrl' $app_json)
    if [[ "$listener_url" = null ]]; then
        write_run "print_error \"logs.bash (1): '.listenerUrl' was not found in application JSON\""
        return 1
    fi
    if [[ -z "$listener_url" ]]; then
        write_run "print_error \"logs.bash (1): '.listenerUrl' is empty in application JSON\""
        return 1
    fi

    local region="us"
    if [[ "$listener_url" = *"-"* ]]; then
        local listener_part=$(cut -d "." -f1 <<< "$listener_url")
        region=$(cut -d "-" -f2 <<< "$listener_part")
    fi

    write_log "INFO" "logzio_region = $region"
    write_run "logzio_region=\"$region\""
}

# Gets Logz.io logs token
# Output:
#   logs_token - Logz.io logs token
# Error:
#   Exit Code 2
function get_logzio_logs_token () {
    write_log "INFO" "Getting Logz.io logs token ..."

    local shipping_token=$($jq_bin -r '.shippingTokens.LOG_ANALYTICS' $app_json)
    if [[ "$shipping_token" = null ]]; then
        write_run "print_error \"logs.bash (2): '.shippingTokens.LOG_ANALYTICS' was not found in application JSON\""
        return 2
    fi
    if [[ -z "$shipping_token" ]]; then
        write_run "print_error \"logs.bash (2): '.shippingTokens.LOG_ANALYTICS' is empty in application JSON\""
        return 2
    fi

    write_log "INFO" "logs_token = $shipping_token"
    write_run "logs_token=\"$shipping_token\""
}

# Gets log sources
# Output:
#   log_sources - list of log sources
# Error:
#   Exit Code 3
function get_log_sources () {
    write_log "INFO" "Getting log sources ..."

    local log_sources_param=$(find_param "$logs_params" "logSources")
    if [[ -z "$log_sources_param" ]]; then
        write_run "print_error \"logs.bash (3): log sources param was not found\""
        return 3
    fi

    local log_sources_value=$(echo -e "$log_sources_param" | $jq_bin -c '.value[]')
    if [[ "$log_sources_value" = null ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=optional-log-sources}].value[]' was not found in application JSON\""
        return 3
    fi
    if [[ -z "$log_sources_value" ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=optional-log-sources}].value[]' is empty in application JSON\""
        return 3
    fi
    
    write_log "INFO" "log_sources = $log_sources_value"
    write_run "log_sources=\"$log_sources_value\""
}

# Adds logs receivers to OTEL config
# Error:
#   Exit Code 4
function add_logs_receivers_to_otel_config () {
    write_log "INFO" "Adding logs receivers to OTEL config ..."

    curl -fsSL $repo_path/telemetry/logs/logs_otel_receivers.yaml > $logzio_temp_dir/logs_otel_receivers.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (4): failed to get logs_otel_receivers yaml file from logzio-agent-manifest repo.\n  $err\""
        return 4
    fi

    while read -r log_source; do
        $yq_bin -i ".filelog.include += \"$log_source\"" $logzio_temp_dir/logs_otel_receivers.yaml 2>$task_error_file
        if [[ $? -ne 0 ]]; then
            local err=$(cat $task_error_file)
            write_run "print_error \"logs.bash (4): failed to insert log sources into logs_otel_receivers yaml file.\n  $err\""
            return 4
        fi
    done < <(echo -e "$log_sources")

    sudo $yq_bin eval-all -i 'select(fileIndex==0).receivers += select(fileIndex==1) | select(fileIndex==0)' $otel_config $logzio_temp_dir/logs_otel_receivers.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (4): failed to add logs receivers to OTEL config file.\n  $err\""
        return 4
    fi
}

# Adds logs exporter to OTEL config
# Error:
#   Exit Code 5
function add_logs_exporter_to_otel_config () {
    write_log "INFO" "Adding logs exporter to OTEL config ..."

    curl -fsSL $repo_path/telemetry/logs/logs_otel_exporter.yaml > $logzio_temp_dir/logs_otel_exporter.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (5): failed to get logs_otel_exporter yaml file from logzio-agent-manifest repo.\n  $err\""
        return 5
    fi

    $yq_bin -i ".logzio/logs.account_token = \"$logs_token\"" $logzio_temp_dir/logs_otel_exporter.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (5): failed to insert Logz.io logs token into logs_otel_exporter yaml file.\n  $err\""
        return 5
    fi

    $yq_bin -i ".logzio/logs.region = \"$logzio_region\"" $logzio_temp_dir/logs_otel_exporter.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (5): failed to insert Logz.io region into logs_otel_exporter yaml file.\n  $err\""
        return 5
    fi

    sudo $yq_bin eval-all -i 'select(fileIndex==0).exporters += select(fileIndex==1) | select(fileIndex==0)' $otel_config $logzio_temp_dir/logs_otel_exporter.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (5): failed to add logs exporter to OTEL config file.\n  $err\""
        return 5
    fi
}

# Adds logs service pipeline to OTEL config
# Error:
#   Exit Code 6
function add_logs_service_pipeline_to_otel_config () {
    write_log "INFO" "Adding logs service pipeline to OTEL config ..."

    curl -fsSL $repo_path/telemetry/logs/logs_otel_service_pipeline.yaml > $logzio_temp_dir/logs_otel_service_pipeline.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (5): failed to get logs_otel_service_pipeline yaml file from logzio-agent-manifest repo.\n  $err\""
        return 5
    fi

    $yq_bin -i '.logs.receivers += "filelog"' $logzio_temp_dir/logs_otel_service_pipeline.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (6): failed to add service pipeline logs receiver into logs_otel_service_pipeline yaml file.\n  $err\""
        return 6
    fi

    $yq_bin -i '.logs.exporters += "logzio/logs"' $logzio_temp_dir/logs_otel_service_pipeline.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (6): failed to add service pipeline logs exporter into logs_otel_service_pipeline yaml file.\n  $err\""
        return 6
    fi

    sudo $yq_bin eval-all -i 'select(fileIndex==0).service.pipelines += select(fileIndex==1) | select(fileIndex==0)' $otel_config $logzio_temp_dir/logs_otel_service_pipeline.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (6): failed to add logs service pipeline to OTEL config file.\n  $err\""
        return 6
    fi
}
