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
# Build enable deploy events Helm set
execute_task "build_enable_deploy_events_helm_set" "Building enable deploy events Helm set"
# Build Logz.io deploy events logs token Helm set
execute_task "build_logzio_logs_token_helm_set" "Building Logz.io deploy events logs token Helm set"
