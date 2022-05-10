#!/bin/bash

#################################################################################################################################
##################################################### Installer Mac Script ######################################################
#################################################################################################################################

# Load functions
source ./logzio-temp/installer_functions.bash

# Get general params
execute_task "get_general_params" "getting general params"

# Get which products were selected
execute_task "get_which_products_were_selected" "getting which products were selected"

# Build tolerations helm sets
execute_task "build_tolerations_helm_sets" "getting tolerations helm sets"

# Build enable metrics or traces helm set
if $is_metrics_option_selected || $is_traces_option_selected; then
    execute_task "build_enable_metrics_or_traces_helm_set" "getting enable metrics or traces helm set"
fi

# Build metrics/traces environment tag helm set
if $is_metrics_option_selected || $is_traces_option_selected; then
    execute_task "build_environment_tag_helm_set" "getting metrics/traces environment tag helm set"
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
    echo -e "\nlogs:"
    source ./logzio-temp/logs.bash
fi

# Run metrics script
if $is_metrics_option_selected; then
    echo -e "\nmetrics:"
    source ./logzio-temp/metrics.bash
fi

# Run traces script
if $is_traces_option_selected; then
    echo -e "\ntraces:"
    source ./logzio-temp/traces.bash
fi

# Run Helm install
echo -e "\ninstaller:"
execute_task "run_helm_install" "running Helm install"

print_success "Helm charts were installed successfully"
print_info "run the following command to check if all pods are up and running: 'kubectl -n monitoring get pods'"
