#!/bin/bash

#################################################################################################################################
################################################ LINUX Datasource Logs Script ###################################################
#################################################################################################################################

# Print title
echo
echo -e '############'
echo -e "###$PURPLE_COLOR Logs $WHITE_COLOR###"
echo -e '############'

EXIT_CODE=1

# Load datasource logs utils functions
load_logs_utils

# Get Logz.io logs token
execute_task 'get_logzio_logs_token' 'Getting Logz.io logs token'
# Build enable logs Helm set
execute_task 'build_enable_logs_helm_set' 'Building enable logs Helm set'
# Build enable opentelemetry log collection Helm set
execute_task 'build_enable_opentelemetry_log_collection_helm_set' 'Building enable opentelemetry log collection Helm set'
# Build disable fluentd log collection Helm set
execute_task 'build_disable_fluentd_log_collection_helm_set' 'Building disable fluentd log collection Helm set'
# Build Logz.io logs region Helm set
execute_task 'build_logzio_logs_region_helm_set' 'Building Logz.io logs region Helm set'
# Build Logz.io logs token Helm set
execute_task 'build_logzio_logs_token_helm_set' 'Building Logz.io logs token Helm set'
# Build environment id Helm set
execute_task 'build_environment_id_helm_set' 'Building environment id Helm set'
# Get is scan security risks option was selected
#execute_task "get_is_scan_security_risks_option_was_selected" "Getting is scan security risks option was selected"
#if $IS_SCAN_SECURITY_RISKS_OPTION_WAS_SELCTED; then
    # Build enable security report Helm set
#    execute_task "build_enable_security_report_helm_set" "Building enable security report Helm set"
    # Build Logz.io Trivy logs listener URL Helm set
#    execute_task "build_logzio_trivy_logs_listener_url_helm_set" "Building Logz.io Trivy logs listener URL Helm set"
    # Build Logz.io Trivy logs token Helm set
#    execute_task "build_logzio_trivy_logs_token_helm_set" "Building Logz.io Trivy logs token Helm set"
    # Build Trivy environment id Helm set
#    execute_task "build_trivy_environment_id_helm_set" "Building Trivy environment id Helm set"
#fi
