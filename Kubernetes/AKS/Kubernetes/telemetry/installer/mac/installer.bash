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
