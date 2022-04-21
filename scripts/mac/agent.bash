#!/bin/bash

#################################################################################################################################
####################################################### Agent Mac Script ########################################################
#################################################################################################################################

# Load functions
source ./functions.bash

# Get arguments and check validation
get_arguments "$@"
check_validation

# Prerequisite installations
echo "Running prerequisite installations..."
install_jq

# Get app JSON
get_app_json
