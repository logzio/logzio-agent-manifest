#!/bin/bash

#################################################################################################################################
################################################## Logs Linux Script ###################################################
#################################################################################################################################


# Load functions
write_log "INFO" "Loading logs functions ..."
source $logzio_temp_dir/logs_functions.bash

# Get Google Cloud project id
execute_task "get_project_id" "get google project id"

# Set Google Cloud default project id
execute_task "set_project_id" "set google project id as default"

# Get Logz.io region
execute_task "get_logzio_listener" "getting Logz.io listener"

# Get Logz.io logs token
execute_task "get_logzio_logs_token" "getting Logz.io logs token"

# Get Gcloud Function name
execute_task "get_google_cloud_fuction_name_from_id" "getting google cloud function name from id"

# Get Gcloud Function name
# execute_task "get_logzio_log_type" "getting log type"

# Get Gcloud Function  region
execute_task "get_gcloud_function_region_log" "getting google cloud function region"

# Get Filter for logs
execute_task "get_resources_type" "getting google cloud logging resource type"

# Create Filter pattern 
execute_task "populate_filter_for_service_name" "populate resource type to filter"



# Download integration to deploy Google cloud logic for sending logs to logz.io
execute_task "download_logzio_pubsub_integration" " run service integration to deploy Google cloud logic for sending logs to logz.io"


# Run service integration to deploy Google cloud logic for sending logs to logz.io
execute_task "run_logzio_pubsub_integration" " run service integration to deploy Google cloud logic for sending logs to logz.io"

