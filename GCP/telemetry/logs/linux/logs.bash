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

execute_task "populate_data_to_config" "add data to config"

execute_task "deploy_settings_to_gcp" "deploy config to Cloud Build to setup flow for sending logs"



# # Add logs receivers to OTEL config
# execute_task "add_logs_receivers_to_otel_config" "adding logs receivers to OTEL config"

# # Add logs exporter to OTEL config
# execute_task "add_logs_exporter_to_otel_config" "adding logs exporter to OTEL config"

# # Add logs service pipeline to OTEL config
# execute_task "add_logs_service_pipeline_to_otel_config" "adding logs service pipeline to OTEL config"
