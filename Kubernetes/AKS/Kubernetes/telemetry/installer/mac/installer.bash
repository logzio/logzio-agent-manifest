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

# Get tolerations helm sets
execute_task "get_tolerations_helm_sets" "getting tolerations helm sets"

# Get enable metrics or traces helm set
if $is_metrics_option_selected || $is_traces_option_selected; then
    execute_task "get_enable_metrics_or_traces_helm_set" "getting enable metrics or traces helm set"
fi

# Get metrics/traces environment tag helm set
if $is_metrics_option_selected || $is_traces_option_selected; then
    execute_task "get_environment_tag_helm_set" "getting metrics/traces environment tag helm set"
fi

# Run logs script
#echo -e "\nlogs:"
#source ./logzio-temp/logs.bash
