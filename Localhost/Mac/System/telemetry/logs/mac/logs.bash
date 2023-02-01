#!/bin/bash

#################################################################################################################################
####################################################### Logs Mac Script #########################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading logs functions ..."
source $logzio_temp_dir/logs_functions.bash

# Get Logz.io region
execute_task "get_logzio_region" "getting Logz.io region"

# Get Logz.io logs token
execute_task "get_logzio_logs_token" "getting Logz.io logs token"

# Get log sources
execute_task "get_log_sources" "getting log sources"

# Add logs receivers to OTEL config
sudo -v
execute_task "add_logs_receivers_to_otel_config" "adding logs receivers to OTEL config"

# Add logs exporter to OTEL config
sudo -v
execute_task "add_logs_exporter_to_otel_config" "adding logs exporter to OTEL config"

# Add logs service pipeline to OTEL config
sudo -v
execute_task "add_logs_service_pipeline_to_otel_config" "adding logs service pipeline to OTEL config"
