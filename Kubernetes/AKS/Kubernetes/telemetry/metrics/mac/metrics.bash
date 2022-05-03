#!/bin/bash

#################################################################################################################################
###################################################### Metrics Mac Script #######################################################
#################################################################################################################################

# Load functions
source ./logzio-temp/metrics_functions.bash

# Build enable metrics Helm set
execute_task "build_enable_metrics_helm_set" "building enable metrics Helm set"

# Build Logz.io metrics listener URL Helm set
execute_task "build_logzio_metrics_listener_url_helm_set" "building Logz.io metrics listener URL Helm set"

# Build Logz.io metrics token Helm set
execute_task "build_logzio_metrics_token_helm_set" "building Logz.io metrics token Helm set"

# Get is Kubernetes runs on Windows OS
execute_task "get_is_kubernetes_runs_on_windows_os" "getting is Kubernetes runs on Windows OS"

# Build Windows Node username and password Helm sets
if $is_windows; then
    execute_task "build_windows_node_username_and_password_helm_sets" "building Windows Node username and password Helm sets"
fi
