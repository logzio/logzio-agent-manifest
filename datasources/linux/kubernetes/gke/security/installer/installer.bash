#!/bin/bash

#################################################################################################################################
############################################## LINUX Datasource Installer Script ################################################
#################################################################################################################################

# Print title
echo
echo -e '########################################'
echo -e "###$PURPLE_COLOR Security Datasource Installation $WHITE_COLOR###"
echo -e '########################################'

EXIT_CODE=1

# Load datasource installer utils functions
load_installer_utils

# Get the selected products
execute_task 'get_selected_products' 'Getting selected products'
# Get general params
execute_task 'get_general_params' 'Getting general params'
# Get environment id
execute_task 'get_environment_id' 'Getting environment id'

DATA_SOURCE_INSTALLER_EXIT_CODE=$EXIT_CODE

if $IS_LOGS_OPTION_WAS_SELECTED; then
    # Run logs script
    run_logs
fi
