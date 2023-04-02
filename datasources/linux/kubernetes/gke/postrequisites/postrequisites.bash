#!/bin/bash

#################################################################################################################################
############################################# LINUX Subtype Post-Requisites Script ##############################################
#################################################################################################################################

# Print title
echo
echo -e '#######################'
echo -e "###$PURPLE_COLOR Post-Requisites $WHITE_COLOR###"
echo -e '#######################'

IS_POSTREQUISITES_STEP=true
EXIT_CODE=1

# Load subtype postrequisites utils functions
load_postrequisites_utils

# Check if all pods are running or completed
execute_task 'are_all_pods_running_or_completed' 'Checking if all pods are running or completed'
if ! $ARE_ALL_PODS_RUNNING_OR_COMPLETED; then
    CONTINUE_IF_FAILED=true

    # Check if any pod is pending
    execute_task 'is_any_pod_pending' 'Checking if any pod is pending'
    # Check if any pod is failed
    execute_task 'is_any_pod_failed' 'Checking if any pod is failed'

    CONTINUE_IF_FAILED=false
fi

IS_POSTREQUISITES_STEP=false
