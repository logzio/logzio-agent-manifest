#!/bin/bash

#################################################################################################################################
##################################################### Logs Mac Functions ########################################################
#################################################################################################################################

# Build enable logs helm set
function build_enable_logs_helm_set () {
    local helm_set=" --set logs.enabled=true"
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run_post_task
}

# Build Logz.io logs listener helm set
function build_logzio_logs_listener_helm_set () {
    local listener_url=$(jq -r '.listenerUrl' logzio-temp/app.json)
    local helm_set=" --set logzio-fluentd.secrets.logzioListener=$listener_url"
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run_post_task
}

# Build Logz.io logs token helm set
function build_logzio_logs_token_helm_set () {
    local shipping_token=$(jq -r '.shippingTokens.LOG_ANALYTICS' logzio-temp/app.json)
    local helm_set=" --set logzio-fluentd.secrets.logzioShippingToken=$shipping_token"
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run_post_task
}

# Build multiline Helm sets
function build_multiline_helm_sets () {
    local multiline_param=$(find_param "$logs_params" "multiline")
    if [ -z "$multiline_param" ]; then
        echo -e "print_error \"logs.bash (1): multiline param was not found\"" > logzio-temp/run
        return 1
    fi

    local multiline_value=$(echo -e "$multiline_param" | jq -c '.value[]')
    if [ "$multiline_value" = null ]; then
        echo -e "print_error \"logs.bash (1): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[]' was not found in application JSON\"" > logzio-temp/run
        return 1
    fi
    if [ -z "$multiline_value" ]; then
        return
    fi
                    
    local paths=""
    local index=1

    touch logzio-temp/sources.conf
    touch logzio-temp/filters.conf

    curl -fsSL $repo_path/telemetry/logs/multiline_source.conf > logzio-temp/multiline_source.conf 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "print_error \"logs.script (1): failed to get multiline source conf file from logzio-agent-scripts repo\"" > logzio-temp/run
        return 1
    fi

    curl -fsSL $repo_path/telemetry/logs/multiline_filter.conf > logzio-temp/multiline_filter.conf 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "print_error \"logs.script (1): failed to get multiline filter conf file from logzio-agent-scripts repo\"" > logzio-temp/run
        return 1
    fi

    while read -r obj; do
        local source=$(cat logzio-temp/multiline_source.conf)
        local filter=$(cat logzio-temp/multiline_filter.conf)
        local name="custom$index"

        local path=$(echo -e "$obj" | jq -r '.path')
        if [ "$path" = null ]; then
            echo -e "print_error \"logs.script (1): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[{obj}].path' was not found in application JSON\"" > logzio-temp/run
            return 1
        fi

        paths+=",$path"

        local regex=$(echo -e "$obj" | jq -r '.regex')
        if [ "$path" = null ]; then
            echo -e "print_error \"logs.script (1): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[{obj}].regex' was not found in application JSON\"" > logzio-temp/run
            return 1
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
    local multiline_helm_sets+=" --set-file configmap.customSources=logzio-temp/sources.conf"
    multiline_helm_sets+=" --set-file configmap.customFilters=logzio-temp/filters.conf"
    multiline_helm_sets+=" --set daemonset.extraExclude=\"$paths\""
    helm_sets+="'$multiline_helm_sets'"
}
