#!/bin/bash

#################################################################################################################################
################################################ LINUX Subtype Installer Script #################################################
#################################################################################################################################

EXIT_CODE=1

# Print title
echo
echo -e '########################'
echo -e "###$PURPLE_COLOR Pre-Installation $WHITE_COLOR###"
echo -e '########################'

# Load subtype installer utils scripts
load_installer_utils

# Check if Logz.io OTEL collector service exists
sudo echo >/dev/null
execute_task 'is_logzio_otel_collector_service_exists' 'Checking if Logz.io OTEL collector service exists'
if $IS_SERVICE_EXISTS; then
    # Get user answer about removing the existed service and run logic according the answer
    sudo echo >/dev/null
    remove_service_or_exit
fi
# Download OTEL collector exe
execute_task 'download_otel_collector_binary' 'Downloading OTEL collector binary'
# Run each datasource scripts
run_all_data_sources

# Print title
echo
echo -e '####################'
echo -e "###$PURPLE_COLOR Installation $WHITE_COLOR###"
echo -e '####################'

# Create Logz.io opt subdirectory
execute_task 'create_logzio_opt_sub_dir' 'Creating Logz.io opt subdirectory'
# Copy Logz.io OTEL files to opt subdirectory
execute_task 'copy_logzio_otel_files_to_opt_sub_dir' 'Copying Logz.io OTEL files to opt subdirectory'
# Copy Logz.io OTEL collector service file to systemd system directory
sudo echo >/dev/null
execute_task 'copy_logzio_otel_collector_service_file_to_systemd_system_dir' 'Copying Logz.io OTEL collector service file to systemd system directory'
# Copy delete service script file to opt subdirectory
execute_task 'copy_delete_service_script_to_opt_sub_dir' 'Copying delete service script file to opt subdirectory'
# Run Logz.io OTEL collector service
execute_task 'run_logzio_otel_collector_service' 'Running Logz.io OTEL collector service'
