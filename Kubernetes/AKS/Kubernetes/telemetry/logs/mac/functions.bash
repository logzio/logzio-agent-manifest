#!/bin/bash

#################################################################################################################################
##################################################### Logs Mac Functions ########################################################
#################################################################################################################################

# Builds enable logs Helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_enable_logs_helm_set () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Building enable logs Helm set ..." >> logzio_agent.log
    
    local helm_set=" --set logs.enabled=true"
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] helm_set = $helm_set" >> logzio_agent.log
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run
}

# Builds Logz.io logs listener URL Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 1
function build_logzio_logs_listener_url_helm_set () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Building Logz.io logs listener URL Helm set ..." >> logzio_agent.log

    local listener_url=$(jq -r '.listenerUrl' logzio-temp/app.json)
    if [[ "$listener_url" = null ]]; then
        echo -e "print_error \"logs.bash (1): '.listenerUrl' was not found in application JSON\"" > logzio-temp/run
        return 1
    fi
    if [[ -z "$listener_url" ]]; then
        echo -e "print_error \"logs.bash (1): '.listenerUrl' is empty in application JSON\"" > logzio-temp/run
        return 1
    fi

    local helm_set=" --set logzio-fluentd.secrets.logzioListener=$listener_url"
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] helm_set = $helm_set" >> logzio_agent.log
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run
}

# Builds Logz.io logs token Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 2
function build_logzio_logs_token_helm_set () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Building Logz.io logs token Helm set ..." >> logzio_agent.log

    local shipping_token=$(jq -r '.shippingTokens.LOG_ANALYTICS' logzio-temp/app.json)
    if [[ "$shipping_token" = null ]]; then
        echo -e "print_error \"logs.bash (2): '.shippingTokens.LOG_ANALYTICS' was not found in application JSON\"" > logzio-temp/run
        return 2
    fi
    if [[ -z "$shipping_token" ]]; then
        echo -e "print_error \"logs.bash (2): '.shippingTokens.LOG_ANALYTICS' is empty in application JSON\"" > logzio-temp/run
        return 2
    fi

    local helm_set=" --set logzio-fluentd.secrets.logzioShippingToken=$shipping_token"
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] helm_set = $helm_set" >> logzio_agent.log
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run
}

# Builds multiline Helm sets
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 3
function build_multiline_helm_sets () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Building multiline Helm sets ..." >> logzio_agent.log

    local multiline_param=$(find_param "$logs_params" "multiline")
    if [[ -z "$multiline_param" ]]; then
        echo -e "print_error \"logs.bash (3): multiline param was not found\"" > logzio-temp/run
        return 3
    fi

    local multiline_value=$(echo -e "$multiline_param" | jq -c '.value[]')
    if [[ "$multiline_value" = null ]]; then
        echo -e "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[]' was not found in application JSON\"" > logzio-temp/run
        return 3
    fi
    if [[ -z "$multiline_value" ]]; then
        return
    fi
                    
    local paths=""
    local index=1

    curl -fsSL $repo_path/telemetry/logs/multiline_source.conf > logzio-temp/multiline_source.conf 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"logs.script (3): failed to get multiline source conf file from logzio-agent-scripts repo\"" >> logzio-temp/run
        return 3
    fi

    curl -fsSL $repo_path/telemetry/logs/multiline_filter.conf > logzio-temp/multiline_filter.conf 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"logs.script (3): failed to get multiline filter conf file from logzio-agent-scripts repo\"" >> logzio-temp/run
        return 3
    fi

    while read -r obj; do
        local source=$(cat logzio-temp/multiline_source.conf)
        local filter=$(cat logzio-temp/multiline_filter.conf)
        local name="custom$index"

        local path=$(echo -e "$obj" | jq -r '.path')
        if [[ "$path" = null ]]; then
            echo -e "print_error \"logs.script (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[{obj}].path' was not found in application JSON\"" > logzio-temp/run
            return 3
        fi

        paths+=",$path"

        local regex=$(echo -e "$obj" | jq -r '.regex')
        if [[ "$path" = null ]]; then
            echo -e "print_error \"logs.script (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[{obj}].regex' was not found in application JSON\"" > logzio-temp/run
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

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] sources.conf:" >> logzio_agent.log
    cat logzio-temp/sources.conf >> logzio_agent.log
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] filters.conf:" >> logzio_agent.log
    cat logzio-temp/filters.conf >> logzio_agent.log
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] multiline_sets = $multiline_sets" >> logzio_agent.log

    echo -e "helm_sets+='$multiline_sets'" > logzio-temp/run
}
