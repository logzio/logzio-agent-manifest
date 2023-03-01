#!/bin/bash

#################################################################################################################################
##################################################### Logs Mac Functions ########################################################
#################################################################################################################################

# Builds enable logs Helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_enable_logs_helm_set () {
    write_log "INFO" "Building enable logs Helm set ..."
    
    local helm_set=" --set logs.enabled=true"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}

# Builds Logz.io logs listener URL Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 1
function build_logzio_logs_listener_url_helm_set () {
    write_log "INFO" "Building Logz.io logs listener URL Helm set ..."

    local listener_url=$($jq_bin -r '.listenerUrl' $app_json)
    if [[ "$listener_url" = null ]]; then
        write_run "print_error \"logs.bash (1): '.listenerUrl' was not found in application JSON\""
        return 1
    fi
    if [[ -z "$listener_url" ]]; then
        write_run "print_error \"logs.bash (1): '.listenerUrl' is empty in application JSON\""
        return 1
    fi

    local helm_set=" --set logzio-fluentd.secrets.logzioListener=$listener_url"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}

# Builds Logz.io logs token Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 2
function build_logzio_logs_token_helm_set () {
    write_log "INFO" "Building Logz.io logs token Helm set ..."

    local shipping_token=$($jq_bin -r '.shippingTokens.LOG_ANALYTICS' $app_json)
    if [[ "$shipping_token" = null ]]; then
        write_run "print_error \"logs.bash (2): '.shippingTokens.LOG_ANALYTICS' was not found in application JSON\""
        return 2
    fi
    if [[ -z "$shipping_token" ]]; then
        write_run "print_error \"logs.bash (2): '.shippingTokens.LOG_ANALYTICS' is empty in application JSON\""
        return 2
    fi

    local helm_set=" --set logzio-fluentd.secrets.logzioShippingToken=$shipping_token"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}

# Builds environment id helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_environment_id_helm_set () {
    write_log "INFO" "Building environment id Helm set ..."

    if [[ -z "$env_id" ]]; then
        write_log "INFO" "env_id is empty. Default value will be used."
        return
    fi

    local helm_set=" --set logzio-fluentd.env_id=$env_id"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}

# Gets is scan security risks option was selected
# Output:
#   is_scan_security_risks_option_was_selected - Tells if scan security risks option was selected (true/false)
# Error:
#   Exit Code 3
function get_is_scan_security_risks_option_was_selected () {
    write_log "INFO" "Checking if scan security risks option was selected ..."
    
    local is_scan_security_risks_param=$(find_param "$logs_params" "isScanSecurityRisks")
    if [[ -z "$is_scan_security_risks_param" ]]; then
        write_run "print_error \"logs.bash (3): isScanSecurityRisks param was not found\""
        return 3
    fi

    local is_scan_security_risks_value=$(echo -e "$is_scan_security_risks_param" | $jq_bin -r '.value')
    if [[ "$is_scan_security_risks_value" = null ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOGS}].params[{name=isScanSecurityRisks}].value' was not found in application JSON\""
        return 3
    fi
    if [[ -z "$is_scan_security_risks_value" ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOGS}].params[{name=isScanSecurityRisks}].value' is empty in application JSON\""
        return 3
    fi

    write_log "INFO" "is_scan_security_risks_option_was_selected = $is_scan_security_risks_value"
    write_run "is_scan_security_risks_option_was_selected=$is_scan_security_risks_value"
}

# Builds enable security report Helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_enable_security_report_helm_set () {
    write_log "INFO" "Building enable security report Helm set ..."
    
    local helm_set=" --set securityReport.enabled=true"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}

# Builds Logz.io Trivy logs listener URL Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 4
function build_logzio_trivy_logs_listener_url_helm_set () {
    write_log "INFO" "Building Logz.io Trivy logs listener URL Helm set ..."

    local listener_url=$($jq_bin -r '.listenerUrl' $app_json)
    if [[ "$listener_url" = null ]]; then
        write_run "print_error \"logs.bash (4): '.listenerUrl' was not found in application JSON\""
        return 4
    fi
    if [[ -z "$listener_url" ]]; then
        write_run "print_error \"logs.bash (4): '.listenerUrl' is empty in application JSON\""
        return 4
    fi

    local helm_set=" --set logzio-trivy.secrets.logzioListener=$listener_url"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}

# Builds Logz.io Trivy logs token Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 5
function build_logzio_trivy_logs_token_helm_set () {
    write_log "INFO" "Building Logz.io Trivy logs token Helm set ..."

    local shipping_token=$($jq_bin -r '.shippingTokens.LOG_ANALYTICS' $app_json)
    if [[ "$shipping_token" = null ]]; then
        write_run "print_error \"logs.bash (5): '.shippingTokens.LOG_ANALYTICS' was not found in application JSON\""
        return 5
    fi
    if [[ -z "$shipping_token" ]]; then
        write_run "print_error \"logs.bash (5): '.shippingTokens.LOG_ANALYTICS' is empty in application JSON\""
        return 5
    fi

    local helm_set=" --set logzio-trivy.secrets.logzioShippingToken=$shipping_token"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}

# Builds Trivy environment id helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_trivy_environment_id_helm_set () {
    write_log "INFO" "Building Trivy environment id Helm set ..."

    if [[ -z "$env_id" ]]; then
        write_log "INFO" "env_id is empty. Default value will be used."
        return
    fi

    local helm_set=" --set logzio-trivy.env_id=$env_id"
    write_log "INFO" "helm_set = $helm_set"
    write_run "log_helm_sets+='$helm_set'"
    write_run "helm_sets+='$helm_set'"
}


# Builds multiline Helm sets
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 3
function build_multiline_helm_sets () {
    write_log "INFO" "Building multiline Helm sets ..."

    local multiline_param=$(find_param "$logs_params" "multiline")
    if [[ -z "$multiline_param" ]]; then
        write_run "print_error \"logs.bash (3): multiline param was not found\""
        return 3
    fi

    local multiline_value=$(echo -e "$multiline_param" | $jq_bin -c '.value[]')
    if [[ "$multiline_value" = null ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[]' was not found in application JSON\""
        return 3
    fi
    if [[ -z "$multiline_value" ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[]' is empty in application JSON\""
        return 3
    fi

    curl -fsSL $repo_path/telemetry/logs/multiline_source.conf > $logzio_temp_dir/multiline_source.conf 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (3): failed to get multiline source conf file from logzio-agent-manifest repo.\n  $err\""
        return 3
    fi

    curl -fsSL $repo_path/telemetry/logs/multiline_filter.conf > $logzio_temp_dir/multiline_filter.conf 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (3): failed to get multiline filter conf file from logzio-agent-manifest repo.\n  $err\""
        return 3
    fi

    local paths=""
    local index=1

    while read -r obj; do
        local source=$(cat $logzio_temp_dir/multiline_source.conf)
        local filter=$(cat $logzio_temp_dir/multiline_filter.conf)
        local name="custom$index"

        local path=$(echo -e "$obj" | $jq_bin -r '.source')
        if [[ "$path" = null ]]; then
            write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[{obj}].source' was not found in application JSON\""
            return 3
        fi
        if [[ -z "$path" ]]; then
            write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[{obj}].source' is empty in application JSON\""
            return 3
        fi

        paths+=",$path"

        local regex=$(echo -e "$obj" | $jq_bin -r '.pattern')
        if [[ "$regex" = null ]]; then
            write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[{obj}].pattern' was not found in application JSON\""
            return 3
        fi
        if [[ -z "$regex" ]]; then
            write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[{obj}].pattern' is empty in application JSON\""
            return 3
        fi

        source=$(echo "${source//NAME/$name}")
        source=$(echo "${source//PATH/$path}")
        filter=$(echo "${filter//NAME/$name}")
        filter=$(echo "${filter//REGEX/$regex}")
        echo -e "$source" > logzio-temp/sources.conf
        echo -e "$filter" > logzio-temp/filters.conf
        let "index++"
    done < <(echo -e "$multiline_value")

    paths=${paths:1}

    local multiline_sets+=" --set-file configmap.customSources=logzio-temp/sources.conf"
    multiline_sets+=" --set-file configmap.customFilters=logzio-temp/filters.conf"
    multiline_sets+=" --set daemonset.extraExclude=\"$paths\""

    local sources=$(cat $logzio_temp_dir/sources.conf)
    local filters=$(cat $logzio_temp_dir/filters.conf)
    write_log "INFO" "sources.conf:\n$sources"
    write_log "INFO" "filters.conf:\n$filters"
    write_log "INFO" "multiline_sets = $multiline_sets"

    write_run "log_helm_sets+='$multiline_sets'"
    write_run "helm_sets+='$multiline_sets'"
}
