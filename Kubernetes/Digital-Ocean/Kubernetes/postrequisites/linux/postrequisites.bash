#!/bin/bash

#################################################################################################################################
################################################# Postrequisites Linux Script ###################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading postrequisites functions ..."
source ./logzio-temp/postrequisites_functions.bash

# Check if all pods are running or completed
execute_task "are_all_pods_running_or_completed" "checking if all pods are running or completed"

if ! $are_all_pods_running_or_completed; then
    # Check if any pod is pending
    execute_task "is_any_pod_pending" "checking if any pod is pending"
    # Check if any pod is failed
    execute_task "is_any_pod_failed" "checking if any pod is failed"
fi
