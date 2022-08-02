#!/bin/bash

#################################################################################################################################
##################################################### Installer Mac Script ######################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading installer functions ..."
source $logzio_temp_dir/installer_functions.bash

# Get the selected products
execute_task "get_selected_products" "getting the selected products"

# Create Logz.io opt directory
execute_task "create_logzio_opt_dir" "creating Logz.io opt directory"

# Get OTEL collector binary
execute_task "get_otel_collector_binary" "getting OTEL collector binary"

# Get OTEL config
execute_task "get_otel_config" "getting OTEL config"

# Get Logz.io OTEL collector plist
execute_task "get_logzio_otel_collector_plist" "getting Logz.io OTEL collector plist"

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
echo -e "Collector Binary: $otel_bin"
echo -e "Collector Config: $otel_config"
echo -e "Start Service Command: sudo launchctl load $service_plist"
echo -e "Stop Service Command: sudo launchctl unload $service_name"
echo -e "Show Logs Command: tail -F $logzio_opt_dir/logzio_otel_collector.log"
echo
