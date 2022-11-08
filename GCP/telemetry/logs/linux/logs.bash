#!/bin/bash

#################################################################################################################################
################################################## Prerequisites Linux Script ###################################################
#################################################################################################################################


# Load functions
write_log "INFO" "Loading logs functions ..."
source $logzio_temp_dir/logs_functions.bash

# Get Logz.io region
execute_task "get_logzio_region" "getting Logz.io region"

# Get Logz.io logs token
execute_task "get_logzio_logs_token" "getting Logz.io logs token"

# Get log sources
execute_task "get_google_cloud_fuction_name" "getting google cloud function name"

# Build configuration file
execute_task "populate_data_to_config" "add data to config"

# Deploy config file to Cloud Build service to start process
execute_task "deploy_settings_to_gcp" "deploy config to Cloud Build to setup flow for sending logs"
