#!/bin/bash

#################################################################################################################################
############################################## LINUX Datasource Installer Script ################################################
#################################################################################################################################

# Print title
echo
echo -e '##########################################'
echo -e "###$PURPLE_COLOR Kubernetes Datasource Installation $WHITE_COLOR###"
echo -e '##########################################'

EXIT_CODE=1

# Load datasource installer utils functions
load_installer_utils

# Get the selected products
execute_task 'get_selected_products' 'Getting selected products'
# Get general params
execute_task 'get_general_params' 'Getting general params'
# Get is Taints and Tolerations option was selected
execute_task 'get_is_taints_and_toleration_was_selected' 'Getting is Taints and Tolerations option was selected'
if $IS_TAINT; then
    # Build tolerations Helm sets
    BUILD_WINDOWS_TOLERATIONS_HELM_SETS=true
    execute_task 'build_tolerations_helm_sets' 'Building tolerations Helm sets'
fi
# Get environment id
execute_task 'get_environment_id' 'Getting environment id'
if $IS_METRICS_OPTION_WAS_SELECTED || $IS_TARCES_OPTION_WAS_SELECTED; then
    # Build enable metrics or traces Helm set
    execute_task 'build_enable_metrics_or_traces_helm_set' 'Building enable metrics or traces Helm set'
    # Build environment tag Helm set
    execute_task 'build_environment_tag_helm_set' 'Building environment tag Helm set'
    # Build environment id Helm set
    execute_task 'build_environment_id_helm_set' 'Building environment id Helm set'
fi

DATA_SOURCE_INSTALLER_EXIT_CODE=$EXIT_CODE

if $IS_LOGS_OPTION_WAS_SELECTED; then
    # Run logs script
    run_logs
fi
if $IS_METRICS_OPTION_WAS_SELECTED; then
    # Run metrics script
    run_metrics
fi
if $IS_TRACES_OPTION_WAS_SELECTED; then
    # Run traces script
    run_traces
fi
