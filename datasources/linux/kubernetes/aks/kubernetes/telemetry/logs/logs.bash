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
