#!/bin/bash

#################################################################################################################################
##################################################### Logs Mac Functions ########################################################
#################################################################################################################################

# Gets Logz.io region
# Output:
#   logzio_region - Logz.io region
# Error:
#   Exit Code 1
function get_logzio_region () {
    write_log "INFO" "Getting Logz.io region ..."

    local listener_url=$(jq -r '.listenerUrl' $app_json)
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

    local shipping_token=$(jq -r '.shippingTokens.LOG_ANALYTICS' $app_json)
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

# Adds logs receivers to OTEL config
# Error:
#   Exit Code 3
function add_logs_receivers_to_otel_config () {
    write_log "INFO" "Adding logs receivers to OTEL config ..."

    curl -fsSL $repo_path/telemetry/logs/logs_otel_receivers.yaml > $logzio_temp_dir/logs_otel_receivers.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (3): failed to get logs_otel_receivers yaml file from logzio-agent-manifest repo.\n  $err\""
        return 3
    fi

    yq eval-all -i 'select(fileIndex==0).receivers = select(fileIndex==1) | select(fileIndex==0)' $otel_config $logzio_temp_dir/logs_otel_receivers.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (3): failed to add logs receivers to OTEL config file.\n  $err\""
        return 3
    fi

    local receivers=$(yq e 'keys' $logzio_temp_dir/logs_otel_receivers.yaml 2>$task_error_file)
    local err=$(cat $task_error_file)
    if [[ ! -z "$err" ]]; then
        write_run "print_error \"logs.bash (3): failed to get receiver names from logs_otel_receivers yaml file.\n  $err\""
        return 3
    fi

    for receiver in $receivers; do
        receiver=$(echo $receiver | cut -d ' ' -f2)

        yq e -i ".service.pipelines.logs.receivers += \"$receiver\"" $otel_config 2>$task_error_file
        if [[ $? -ne 0 ]]; then
            local err=$(cat $task_error_file)
            write_run "print_error \"logs.bash (3): failed to add service pipeline logs receiver to OTEL config file.\n  $err\""
            return 3
        fi
    done
}

# Adds logs exporter to OTEL config
# Error:
#   Exit Code 4
function add_logs_exporter_to_otel_config () {
    write_log "INFO" "Adding logs exporter to OTEL config ..."

    curl -fsSL $repo_path/telemetry/logs/logs_otel_exporter.yaml > $logzio_temp_dir/logs_otel_exporter.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (4): failed to get logs_otel_exporter yaml file from logzio-agent-manifest repo.\n  $err\""
        return 4
    fi

    yq e -i "logzio/logs.account_token = \"$logs_token\"" $logzio_temp_dir/logs_otel_exporter.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (4): failed to insert Logz.io logs token into logs_otel_exporter yaml file.\n  $err\""
        return 4
    fi

    yq e -i "logzio/logs.region = \"$logzio_region\"" $logzio_temp_dir/logs_otel_exporter.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (4): failed to insert Logz.io region into logs_otel_exporter yaml file.\n  $err\""
        return 4
    fi

    yq eval-all -i 'select(fileIndex==0).receivers = select(fileIndex==1) | select(fileIndex==0)' $otel_config $logzio_temp_dir/logs_otel_exporter.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (4): failed to add logs exporter to OTEL config file.\n  $err\""
        return 4
    fi

    yq e -i '.service.pipelines.logs.exporters += "logzio/logs"' $otel_config 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (4): failed to add service pipeline logs exporter to OTEL config file.\n  $err\""
        return 4
    fi
}