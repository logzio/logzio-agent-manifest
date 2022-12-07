#!/bin/bash

#################################################################################################################################
###################################################### Metrics Mac Script #######################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading metrics functions ..."
source $logzio_temp_dir/metrics_functions.bash

# Build enable metrics Helm set
execute_task "build_enable_metrics_helm_set" "building enable metrics Helm set"

# Build Logz.io metrics listener URL Helm set
execute_task "build_logzio_metrics_listener_url_helm_set" "building Logz.io metrics listener URL Helm set"

# Build Logz.io metrics token Helm set
execute_task "build_logzio_metrics_token_helm_set" "building Logz.io metrics token Helm set"

# Get is Kubernetes runs on Windows OS
execute_task "get_is_k8s_runs_on_windows_os" "getting is Kubernetes runs on Windows OS"

# Build Windows Node username and password Helm sets
if $is_windows; then
    execute_task "build_windows_node_username_and_password_helm_sets" "building Windows Node username and password Helm sets"
fi

# Get if metrics filter was selected
execute_task "get_is_metrics_filter_was_selected" "getting if metrics filter was selected"
if $is_filter; then
    # Build enable metrics filter Helm set
    execute_task "build_enable_metrics_filter_helm_set" "building enable metrics filter Helm set"
fi
