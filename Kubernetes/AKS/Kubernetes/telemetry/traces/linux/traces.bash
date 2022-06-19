#!/bin/bash

#################################################################################################################################
##################################################### Traces Linux Script #######################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading traces functions ..."
source $logzio_temp_dir/traces_functions.bash

# Build enable traces Helm set
execute_task "build_enable_traces_helm_set" "building enable traces Helm set"

# Build Logz.io traces token Helm set
execute_task "build_logzio_traces_token_helm_set" "building Logz.io traces token Helm set"

# Build Logz.io region Helm set
execute_task "build_logzio_region_helm_set" "building Logz.io region Helm set"
