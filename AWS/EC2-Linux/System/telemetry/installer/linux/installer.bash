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

# Create Logz.io opt directory
execute_task "create_logzio_opt_dir" "creating Logz.io opt directory"

# Get OTEL collector binary
execute_task "get_otel_collector_binary" "getting OTEL collector binary"

# Get OTEL config
execute_task "get_otel_config" "getting OTEL config"

# Get Logz.io OTEL collector service file
execute_task "get_logzio_otel_collector_service_file" "getting Logz.io OTEL collector service file"

# Get logs scripts
if $is_logs_option_selected; then
    execute_task "get_logs_scripts" "getting logs scripts"
fi

# Get metrics scripts
if $is_metrics_option_selected; then
    execute_task "get_metrics_scripts" "getting metrics scripts"
fi

# Run logs script
if $is_logs_option_selected; then
    write_log "INFO" "Running logs script ..."
    echo -e "\nlogs:"
    source $logzio_temp_dir/logs.bash
fi

# Run metrics script
if $is_metrics_option_selected; then
    write_log "INFO" "Running metrics script ..."
    echo -e "\nmetrics:"
    source $logzio_temp_dir/metrics.bash
fi

# Run Logz.io OTEL collector service
echo -e "\ninstaller:"
execute_task "run_logzio_otel_collector_service" "running Logz.io OTEL collector service"

# Print success message
echo
print_info "##### Logz.io agent was finished successfully #####"

# Print information
echo -e "\nInformation:\n"
echo -e "\033[0;35mCollector Binary\033[0;37m: $otel_bin"
echo -e "\033[0;35mCollector Config\033[0;37m: $otel_config"
echo -e "\033[0;35mStart Service Command\033[0;37m: sudo systemctl start $service_name"
echo -e "\033[0;35mStop Service Command\033[0;37m: sudo systemctl stop $service_name"
echo -e "\033[0;35mShow Service Command\033[0;37m: sudo systemctl | grep $service_name"
echo -e "\033[0;35mShow Logs Command\033[0;37m: sudo systemctl status -l $service_name"
echo
