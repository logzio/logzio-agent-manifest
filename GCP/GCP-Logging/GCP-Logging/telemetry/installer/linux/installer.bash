#!/bin/bash

#################################################################################################################################
#################################################### Installer Linux Script #####################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading installer functions ..."
source $logzio_temp_dir/installer_functions.bash

# Check if Logz.io OTEL collector service exist
execute_task "is_logzio_otel_collector_service_exist" "checking if Logz.io OTEL collector service exist"
if $is_service_exist; then
    while true; do
        echo -ne "\033[0;33mcom.logzio.OTELCollector service is already exist. If you continue the service will be removed. Are you sure? (y/n)\033[0;37m " 
        read answer
        if [[ "$answer" = "y" ]]; then
            systemctl stop logzioOTELCollector >/dev/null 2>&1
            break
        elif [[ "$answer" = "n" ]]; then
            tput cnorm -- normal
            delete_temp_dir
            exit
        fi
    done
    echo
fi

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
