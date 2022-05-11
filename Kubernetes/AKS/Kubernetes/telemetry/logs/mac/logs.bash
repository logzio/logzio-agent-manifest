#!/bin/bash

#################################################################################################################################
####################################################### Logs Mac Script #########################################################
#################################################################################################################################

# Load functions
echo -e "[INFO] Loading logs functions ..." >> logzio_agent.log
source ./logzio-temp/logs_functions.bash

# Build enable logs Helm set
execute_task "build_enable_logs_helm_set" "building enable logs Helm set"

# Build Logz.io logs listener URL Helm set
execute_task "build_logzio_logs_listener_url_helm_set" "building Logz.io logs listener URL Helm set"

# Build Logz.io logs token Helm set
execute_task "build_logzio_logs_token_helm_set" "building Logz.io logs token Helm set"

# Build multiline Helm sets
#execute_task "build_multiline_helm_sets" "building multiline Helm sets"
