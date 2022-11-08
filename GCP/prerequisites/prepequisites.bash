#!/bin/bash

#################################################################################################################################
################################################## Prerequisites Linux Script ###################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading prerequisites functions ..."
source ./logzio-temp/prerequisites_functions.bash

# Install yq
execute_task "install_yq" "installing yq"

# Check if user installed gcloud CLI
execute_task "is_gcloud_install" "checking if EC2 server can connect to Logz.io logs"

# Check if user is logged in Google Cloud Platform
execute_task "is_gcloud_user_login" "checking if EC2 server can connect to Logz.io logs"


