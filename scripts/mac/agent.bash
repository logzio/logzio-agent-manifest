#!/bin/bash

#################################################################################################################################
####################################################### Agent Mac Script ########################################################
#################################################################################################################################

# Load functions
source ./functions.bash

# Get arguments and check validation
get_arguments "$@"
check_validation

# Init progress bar
completed_tasks=0
print_progressbar_status

# Prerequisite installations
echo "Running prerequisite installations..."
install_jq

# Get app JSON
get_app_json

# Build path to logzio-agent-scripts repo
build_repo_path

# Get prerequisite script from logzio-agent-scripts repo
get_prerequisite_script

# Run prerequisites script
echo "Running prerequisites..."
source ./prerequisites.bash
