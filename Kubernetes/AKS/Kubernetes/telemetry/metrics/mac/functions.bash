#!/bin/bash

#################################################################################################################################
#################################################### Metrics Mac Functions ######################################################
#################################################################################################################################

# Builds enable metrics Helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_enable_metrics_helm_set () {
    write_log "INFO" "Building enable metrics Helm set ..."

    local helm_set=" --set logzio-k8s-telemetry.metrics.enabled=true"
    write_log "INFO" "helm_set = $helm_set"
    write_run "helm_sets+='$helm_set'"
}

# Builds Logz.io metrics listener URL Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 1
function build_logzio_metrics_listener_url_helm_set () {
    write_log "INFO" "Building Logz.io metrics listener URL Helm set ..."

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
    local helm_set=" --set logzio-k8s-telemetry.secrets.ListenerHost=$listener_url"
    write_log "INFO" "helm_set = $helm_set"
    write_run "helm_sets+='$helm_set'"
}

# Builds Logz.io metrics token Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 2
function build_logzio_metrics_token_helm_set () {
    write_log "INFO" "Building Logz.io metrics token Helm set ..."

    local shipping_token=$(jq -r '.shippingTokens.METRICS' $app_json)
    if [[ "$shipping_token" = null ]]; then
        write_run "print_error \"metrics.bash (2): '.shippingTokens.METRICS' was not found in application JSON\""
        return 2
    fi
    if [[ -z "$shipping_token" ]]; then
        write_run "print_error \"metrics.bash (2): '.shippingTokens.METRICS' is empty in application JSON\""
        return 2
    fi
    
    local helm_set=" --set logzio-k8s-telemetry.secrets.MetricsToken=$shipping_token"
    write_log "INFO" "helm_set = $helm_set"
    write_run "helm_sets+='$helm_set'"
}

# Gets is Kubernetes runs on Windows OS
# Output:
#   is_windows - Tells if Kubernetes runs on Windows OS (true/false)
# Error:
#   Exit Code 3
function get_is_k8s_runs_on_windows_os () {
    write_log "INFO" "Getting if Kubernetes runs on Windows OS ..."

    local is_windows_param=$(find_param "$metrics_params" "isWindows")
    if [[ -z "$is_windows_param" ]]; then
        write_run "print_error \"metrics.bash (3): isWindows param was not found\""
        return 3
    fi

    local is_windows_value=$(echo -e "$is_windows_param" | jq -r '.value')
    if [[ "$is_windows_value" = null ]]; then
        write_run "print_error \"metrics.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=METRICS}].params[{name=isWindows}].value' was not found in application JSON\""
        return 3
    fi
    if [[ -z "$is_windows_value" ]]; then
        write_run "print_error \"installer.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=METRICS}].params[{name=isWindows}].value' is empty in application JSON\""
        return 3
    fi

    write_log "INFO" "is_windows = $is_windows_value"
    write_run "is_windows=$is_windows_value"
}

# Builds Windows Node username and password Helms sets (if Kubernetes runs on Windows OS)
# Output:
#   helm_sets - Contains all the Helm sets
function build_windows_node_username_and_password_helm_sets () {
    write_log "INFO" "Building Windows Node username and password Helm sets ..."

    write_run "read -p \"\033[0;35mPlease enter your Windows Node username:\033[0;37m \" username"
    write_run "read -s -p \"\033[0;35mPlease enter your Windows Node password:\033[0;37m \" password"
    write_run "windows_username_set=\" --set logzio-k8s-telemetry.secrets.windowsNodeUsername=\$username\""
    write_run "windows_password_set=\" --set logzio-k8s-telemetry.secrets.windowsNodePassword=\""
    write_run "secured_password=\"\$password[1]*****\$password[\${#password}]\""
    write_run "write_log \"INFO\" \"windows_sets = \$windows_username_set\$windows_password_set\$secured_password\""
    write_run "helm_sets+=\"\$windows_username_set\$windows_password_set\$password\""
}
