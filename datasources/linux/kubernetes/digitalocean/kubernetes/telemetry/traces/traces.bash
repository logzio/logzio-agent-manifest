#!/bin/bash

#################################################################################################################################
############################################### LINUX Datasource Traces Script ##################################################
#################################################################################################################################

# Print title
echo
echo -e '##############'
echo -e "###$PURPLE_COLOR Traces $WHITE_COLOR###"
echo -e '##############'

EXIT_CODE=1

# Load datasource traces utils functions
load_traces_utils

# Get Logz.io traces token
execute_task 'get_logzio_traces_token' 'Getting Logz.io traces token'
# Build enable traces Helm set
execute_task 'build_enable_traces_helm_set' 'Building enable traces Helm set'
# Build Logz.io traces token Helm set
execute_task 'build_logzio_traces_token_helm_set' 'Building Logz.io traces token Helm set'
# Get Logz.io SPM token
execute_task 'get_logzio_metrics_token' 'Getting Logz.io SPM token'
# Build enable SPM Helm set
execute_task 'build_enable_spm_helm_set' 'Building enable SPM Helm set'
# Build Logz.io SPM token Helm set
execute_task 'build_logzio_spm_token_helm_set' 'Building Logz.io SPM token Helm set'
