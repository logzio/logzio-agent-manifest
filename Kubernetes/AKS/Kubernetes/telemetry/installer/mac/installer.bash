#!/bin/bash

#################################################################################################################################
##################################################### Installer Mac Script ######################################################
#################################################################################################################################

# Load functions
source ./logzio-temp/installer_functions.bash

# Get general params
get_general_params
#execute_task "get_general_params" "getting general params"

# Get which products were selected
get_which_products_were_selected
#execute_task "get_which_products_were_selected" "getting which products were selected"
