#!/bin/bash

#################################################################################################################################
####################################################### Logs Mac Script #########################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading logs functions ..."
source $logzio_temp_dir/logs_functions.bash

# Build enable logs Helm set
execute_task "build_enable_logs_helm_set" "building enable logs Helm set"

# Build Logz.io logs listener URL Helm set
execute_task "build_logzio_logs_listener_url_helm_set" "building Logz.io logs listener URL Helm set"

# Build Logz.io logs token Helm set
execute_task "build_logzio_logs_token_helm_set" "building Logz.io logs token Helm set"

# Build environment ID Helm set
execute_task "build_environment_id_helm_set" "building environment ID Helm set"

# Get is scan security risks option was selected
execute_task "get_is_scan_security_risks_option_was_selected" "Getting is scan security risks option was selected"

if $is_scan_security_risks_option_was_selected; then
    # Build enable security report Helm set
    execute_task "build_enable_security_report_helm_set" "Building enable security report Helm set"
    # Build Logz.io Trivy logs listener URL Helm set
    execute_task "build_logzio_trivy_logs_listener_url_helm_set" "Building Logz.io Trivy logs listener URL Helm set"
    # Build Logz.io Trivy logs token Helm set
    execute_task "build_logzio_trivy_logs_token_helm_set" "Building Logz.io Trivy logs token Helm set"
    # Build Trivy environment id Helm set
    execute_task "build_trivy_environment_id_helm_set" "Building Trivy environment id Helm set"
fi

# Build multiline Helm sets
#execute_task "build_multiline_helm_sets" "building multiline Helm sets"
