#!/bin/bash

#################################################################################################################################
################################################# MAC Datasource Logs Script ####################################################
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
# Build enable security report Helm set
execute_task "build_enable_security_report_helm_set" "Building enable security report Helm set"
# Build Logz.io Trivy logs token Helm set
execute_task "build_logzio_logs_token_helm_set" "Building Logz.io Trivy logs token Helm set"
