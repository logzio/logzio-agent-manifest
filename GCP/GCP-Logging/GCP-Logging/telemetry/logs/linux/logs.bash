#!/bin/bash

#################################################################################################################################
################################################## Prerequisites Linux Script ###################################################
#################################################################################################################################


# Load functions
write_log "INFO" "Loading logs functions ..."
source $logzio_temp_dir/logs_functions.bash

# Get Logz.io region
execute_task "get_logzio_listener" "getting Logz.io listener"

# Get Logz.io logs token
execute_task "get_logzio_logs_token" "getting Logz.io logs token"

# Get Gcloud Function name
execute_task "get_google_cloud_fuction_name" "getting google cloud function name"

# Get Gcloud Function name
execute_task "get_logzio_log_type" "getting log type"

# Get Gcloud Function  region
execute_task "get_gcloud_function_region_log" "getting google cloud function region"

# Get Filter for logs
execute_task "get_filter_log" "getting google cloud logging filter"


# Build configuration file
execute_task "populate_data_to_config" "add data to config"

# Deploy config file to Cloud Build service to start process
execute_task "deploy_settings_to_gcp" "deploy config to Cloud Build to setup flow for sending logs"
