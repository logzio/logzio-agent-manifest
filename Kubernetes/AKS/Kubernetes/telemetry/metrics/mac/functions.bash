#!/bin/bash

#################################################################################################################################
#################################################### Metrics Mac Functions ######################################################
#################################################################################################################################

# Builds enable metrics Helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_enable_metrics_helm_set () {
    echo -e "[INFO] Building enable metrics Helm set ..." >> logzio_agent.log

    local helm_set=" --set logzio-k8s-telemetry.metrics.enabled=true"
    echo -e "[INFO] helm_set = $helm_set" >> logzio_agent.log
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run
}

# Builds Logz.io metrics listener URL Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 1
function build_logzio_metrics_listener_url_helm_set () {
    echo -e "[INFO] Building Logz.io metrics listener URL Helm set ..." >> logzio_agent.log

    local listener_url=$(jq -r '.listenerUrl' logzio-temp/app.json)
    if [ "$listener_url" = null ]; then
        echo -e "print_error \"metrics.bash (1): '.listenerUrl' was not found in application JSON\"" > logzio-temp/run
        return 1
    fi
    if [ -z "$listener_url" ]; then
        echo -e "print_error \"metrics.bash (1): '.listenerUrl' is empty in application JSON\"" > logzio-temp/run
        return 1
    fi

    listener_url="https://$listener_url:8053"
    local helm_set=" --set logzio-k8s-telemetry.secrets.ListenerHost=$listener_url"
    echo -e "[INFO] helm_set = $helm_set" >> logzio_agent.log
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run
}

# Builds Logz.io metrics token Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 2
function build_logzio_metrics_token_helm_set () {
    echo -e "[INFO] Building Logz.io metrics token Helm set ..." >> logzio_agent.log

    local shipping_token=$(jq -r '.shippingTokens.METRICS' logzio-temp/app.json)
    if [ "$shipping_token" = null ]; then
        echo -e "print_error \"metrics.bash (2): '.shippingTokens.METRICS' was not found in application JSON\"" > logzio-temp/run
        return 2
    fi
    if [ -z "$shipping_token" ]; then
        echo -e "print_error \"metrics.bash (2): '.shippingTokens.METRICS' is empty in application JSON\"" > logzio-temp/run
        return 2
    fi
    
    local helm_set=" --set logzio-k8s-telemetry.secrets.MetricsToken=$shipping_token"
    echo -e "[INFO] helm_set = $helm_set" >> logzio_agent.log
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run
}

# Gets is Kubernetes runs on Windows OS
# Output:
#   is_windows - Tells if Kubernetes runs on Windows OS (true/false)
# Error:
#   Exit Code 3
function get_is_k8s_runs_on_windows_os () {
    echo -e "[INFO] Getting if Kubernetes runs on Windows OS ..." >> logzio_agent.log

    local is_windows_param=$(find_param "$metrics_params" "isWindows")
    if [ -z "$is_windows_param" ]; then
        echo -e "print_error \"metrics.bash (3): isWindows param was not found\"" > logzio-temp/run
        return 3
    fi

    local is_windows_value=$(echo -e "$is_windows_param" | jq -r '.value')
    if [ "$is_windows_value" = null ]; then
        echo -e "print_error \"metrics.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=METRICS}].params[{name=isWindows}].value' was not found in application JSON\"" > logzio-temp/run
        return 3
    fi
    if [ -z "$is_windows_value" ]; then
        echo -e "print_error \"installer.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=METRICS}].params[{name=isWindows}].value' is empty in application JSON\"" > logzio-temp/run
        return 3
    fi

    echo -e "[INFO] is_windows = $is_windows_value" >> logzio_agent.log
    echo -e "is_windows=$is_windows_value" > logzio-temp/run
}

# Builds Windows Node username and password Helms sets (if Kubernetes runs on Windows OS)
# Output:
#   helm_sets - Contains all the Helm sets
function build_windows_node_username_and_password_helm_sets () {
    echo -e "[INFO] Building Windows Node username and password Helm sets ..." >> logzio_agent.log

    echo -e "read -p \"\033[0;35mPlease enter your Windows Node username:\033[0;37m \" username </dev/tty" >> logzio-temp/run
    echo -e "read -p \"\033[0;35mPlease enter your Windows Node password:\033[0;37m \" password </dev/tty" >> logzio-temp/run
    echo -e "windows_sets+=\" --set logzio-k8s-telemetry.secrets.windowsNodeUsername=$username\"" >> logzio-temp/run
    echo -e "windows_sets+=\" --set logzio-k8s-telemetry.secrets.windowsNodePassword=$password\"" >> logzio-temp/run
    echo -e "echo -e \"[INFO] windows_sets = $windows_sets\" >> logzio_agent.log" >> logzio-temp/run
    echo -e "helm_sets+='$windows_sets'" >> logzio-temp/run
}
