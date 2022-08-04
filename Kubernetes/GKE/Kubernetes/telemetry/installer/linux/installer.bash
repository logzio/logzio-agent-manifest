#!/bin/bash

#################################################################################################################################
#################################################### Installer Linux Script #####################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading installer functions ..."
source $logzio_temp_dir/installer_functions.bash

# Get general params
execute_task "get_general_params" "getting general params"

# Get the selected products
execute_task "get_selected_products" "getting the selected products"

# Build tolerations helm sets
execute_task "build_tolerations_helm_sets" "building tolerations Helm sets"

# Build enable metrics or traces helm set
if $is_metrics_option_selected || $is_traces_option_selected; then
    execute_task "build_enable_metrics_or_traces_helm_set" "building enable metrics or traces Helm set"
fi

# Build metrics/traces environment tag helm set
if $is_metrics_option_selected || $is_traces_option_selected; then
    execute_task "build_environment_tag_helm_set" "building metrics/traces environment tag Helm set"
fi

# Get logs scripts
if $is_logs_option_selected; then
    execute_task "get_logs_scripts" "getting logs scripts"
fi

# Get metrics scripts
if $is_metrics_option_selected; then
    execute_task "get_metrics_scripts" "getting metrics scripts"
fi

# Get traces scripts
if $is_traces_option_selected; then
    execute_task "get_traces_scripts" "getting traces scripts"
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

# Run traces script
if $is_traces_option_selected; then
    write_log "INFO" "Running traces script ..."
    echo -e "\ntraces:"
    source $logzio_temp_dir/traces.bash
fi

# Run Helm install
echo -e "\ninstaller:"
execute_task "run_helm_install" "running Helm install"

# Print success message
echo
print_info "##### Logz.io agent was finished successfully #####"
