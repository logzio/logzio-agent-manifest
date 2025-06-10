#!/bin/bash

#################################################################################################################################
############################################## LINUX Datasource Installer Script ################################################
#################################################################################################################################

# Print title
echo
echo -e '######################################'
echo -e "###$PURPLE_COLOR System Datasource Installation $WHITE_COLOR###"
echo -e '######################################'

EXIT_CODE=1

# Load datasource installer utils functions
load_installer_utils

# Get the selected products
execute_task 'get_selected_products' 'Getting selected products'

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
