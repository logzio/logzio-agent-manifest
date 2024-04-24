#!/bin/bash

#################################################################################################################################
############################################### LINUX Datasource Metrics Script #################################################
#################################################################################################################################

# Print title
echo
echo -e '###############'
echo -e "###$PURPLE_COLOR Metrics $WHITE_COLOR###"
echo -e '###############'

EXIT_CODE=1

# Load datasource metrics utils functions
load_metrics_utils

# Get Logz.io metrics token
execute_task 'get_logzio_metrics_token' 'Getting Logz.io metrics token'
# Build enable metrics Helm set
execute_task 'build_enable_metrics_helm_set' 'Building enable metrics Helm set'
# Build Logz.io metrics listener URL Helm set
execute_task 'build_logzio_metrics_listener_url_helm_set' 'Building Logz.io metrics listener URL Helm set'
# Build Logz.io metrics token Helm set
execute_task 'build_logzio_metrics_token_helm_set' 'Building Logz.io metrics token Helm set'
# Get if Kubernetes runs on Windows OS option was selected
execute_task 'get_is_kubernetes_run_on_windows_os_was_selected' 'Getting is Kubernetes runs on Windows OS option was selected'
if $IS_WINDOWS; then
    # Build Windows node username and password Helm sets
    build_windows_node_username_and_password_helm_sets
fi
# Get if metrics filter option was selected
execute_task 'get_is_metrics_filter_was_selected' 'Getting is metrics filter was selected'
if $IS_FILTER; then
    # Build enable metrics filter Helm set
    CLOUD_PROVIDER='aks'
    execute_task 'build_enable_metrics_filter_helm_set' 'Building enable metrics filter Helm set'
fi
# Get if Kubernetes object logs option was selected
execute_task 'get_is_object_logs_was_selected' 'Getting is Kubernetes object logs was selected'
if $IS_OBJECT_LOGS; then
    # Build Logz.io region Helm set
    execute_task 'build_logzio_region_helm_set' 'Building Logz.io region Helm set'
    # Build Logz.io Kubernetes object logs token Helm set
    execute_task 'build_logzio_object_logs_token_helm_set' 'Building Logz.io Kubernetes object logs token Helm set'
    # Build enable Kubernetes object logs Helm set
    execute_task 'build_enable_object_logs_helm_set'  'Building enable Kubernetes object logs Helm set'
fi
