#!/bin/bash

#################################################################################################################################
################################################ LINUX Subtype Installer Script #################################################
#################################################################################################################################

# Print title
echo
echo -e '########################'
echo -e "###$PURPLE_COLOR Pre-Installation $WHITE_COLOR###"
echo -e '########################'

EXIT_CODE=1

# Load subtype installer utils functions
load_installer_utils

# Check if Logz.io Helm exists
execute_task 'is_logzio_helm_exists' 'Checking if Logz.io Helm exists'
if $IS_HELM_EXISTS; then
    # Get user answer about uninstalling the existed Logz.io Helm and run logic according the answer
    uninstall_helm_or_exit
fi
# Run each datasource scripts
SUB_TYPE_INSTALLER_EXIT_CODE=$EXIT_CODE
run_all_data_sources

# Print title
echo
echo -e '########################'
echo -e "###$PURPLE_COLOR Installation $WHITE_COLOR###"
echo -e '########################'

EXIT_CODE=$SUB_TYPE_INSTALLER_EXIT_CODE

# Create Logz.io opt subdirectory
execute_task 'create_logzio_opt_sub_dir' 'Creating Logz.io opt subdirectory'
# Create Logz.io Helm file with Helm install command
execute_task 'create_logzio_helm_file_with_helm_install' 'Creating Logz.io Helm file with Helm install command'
# Run Helm install
execute_task 'run_helm_install' 'Running Helm install'
