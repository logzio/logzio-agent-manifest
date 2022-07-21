#!/bin/bash

#################################################################################################################################
####################################################### Logs Mac Script #########################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading logs functions ..."
source $logzio_temp_dir/logs_functions.bash

# Get Logz.io logs listener URL
execute_task "get_logzio_logs_listener_url" "getting Logz.io logs listener URL"

# Get Logz.io logs token
execute_task "get_logzio_logs_token" "getting Logz.io logs token"

# Add logs receivers to OTEL config
execute_task "add_logs_receivers_to_otel_config" "adding logs receivers to OTEL config"

# Add logs exporter to OTEL config
execute_task "add_logs_exporter_to_otel_config" "adding logs exporter to OTEL config"
