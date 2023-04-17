#!/bin/bash

#################################################################################################################################
############################################### LINUX Datasource Metrics Script #################################################
#################################################################################################################################

# Print title
echo
echo -e '###############'
echo -e "###$PURPLE_COLOR Metrics $WHITE_COLOR###"
echo -e '###############'

EXIT_CODE=1

# Load datasource metrics utils functions
load_metrics_utils

# Get Logz.io metrics token
execute_task 'get_logzio_metrics_token' 'Getting Logz.io metrics token'
# Build enable metrics Helm set
execute_task 'build_enable_metrics_helm_set' 'Building enable metrics Helm set'
# Build Logz.io metrics listener URL Helm set
execute_task 'build_logzio_metrics_listener_url_helm_set' 'Building Logz.io metrics listener URL Helm set'
# Build Logz.io metrics token Helm set
execute_task 'build_logzio_metrics_token_helm_set' 'Building Logz.io metrics token Helm set'
# Get if metrics filter option was selected
execute_task 'get_is_metrics_filter_was_selected' 'Getting is metrics filter was selected'
if $IS_FILTER; then
    # Build enable metrics filter Helm set
    execute_task 'build_enable_metrics_filter_helm_set' 'Building enable metrics filter Helm set'
fi
