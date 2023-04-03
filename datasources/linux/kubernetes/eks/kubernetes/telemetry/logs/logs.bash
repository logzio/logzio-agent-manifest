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
# Build Logz.io logs listener url Helm set
execute_task 'build_logzio_logs_listener_url_helm_set' 'Building Logz.io logs listener url Helm set'
# Build Logz.io logs token Helm set
execute_task 'build_logzio_logs_token_helm_set' 'Building Logz.io logs token Helm set'
# Build environment id Helm set
execute_task 'build_environment_id_helm_set' 'Building environment id Helm set'
# Get is Fargate option was selected
execute_task 'get_is_fargate_was_selected' 'Getting is Fargate was selected'
if $IS_FARGATE; then
    # Build enable Fargate Helm set
    execute_task 'build_enable_fargate_helm_set' 'Building enable Fargate Helm set'
fi
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
