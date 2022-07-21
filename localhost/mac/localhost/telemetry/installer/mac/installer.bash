#!/bin/bash

#################################################################################################################################
##################################################### Installer Mac Script ######################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading installer functions ..."
source $logzio_temp_dir/installer_functions.bash

# Get general params
execute_task "get_general_params" "getting general params"

# Get which products were selected
execute_task "get_which_products_were_selected" "getting which products were selected"

# Get OTEL config
execute_task "get_otel_config" "getting OTEL config"

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

# Run otelcontribcol binary with OTEL config
execute_task "run_otelcontribcol_binary" "running otelcontribcal binary"

# Print success message
echo
print_info "##### Logz.io agent was finished successfully #####"
