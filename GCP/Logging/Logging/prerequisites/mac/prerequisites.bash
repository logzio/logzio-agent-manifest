#!/bin/bash

#################################################################################################################################
################################################## Prerequisites Linux Script ###################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading prerequisites functions ..."
source ./logzio-temp/prerequisites_functions.bash

# Check if user installed gcloud CLI
execute_task "is_gcloud_install" "Checking if gcloud is installed"

# Check if user is logged in Google Cloud Platform
execute_task "gcloud_user_login" "Login to proper Google Account"


