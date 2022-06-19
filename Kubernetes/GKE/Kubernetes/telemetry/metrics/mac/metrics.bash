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
