#!/bin/bash

#################################################################################################################################
#################################################### Installer Linux Script #####################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading installer functions ..."
source $logzio_temp_dir/installer_functions.bash

# Get the selected products
execute_task "get_selected_products" "getting the selected products"

# Get logs scripts
if $is_logs_option_selected; then
    execute_task "get_logs_scripts" "getting logs scripts"
fi

# Run logs script
if $is_logs_option_selected; then
    write_log "INFO" "Running logs script ..."
    echo -e "\nlogs:"
    source $logzio_temp_dir/logs.bash
fi

echo
print_info "##### Logz.io agent was finished successfully #####"
