#!/bin/bash

#################################################################################################################################
###################################################### Metrics Mac Script #######################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading metrics functions ..."
source $logzio_temp_dir/metrics_functions.bash

# Get Logz.io metrics listener URL
execute_task "get_logzio_metrics_listener_url" "getting Logz.io metrics listener URL"

# Get Logz.io metrics token
execute_task "get_logzio_metrics_token" "getting Logz.io metrics token"

# Add metrics receivers to OTEL config
execute_task "add_metrics_receivers_to_otel_config" "adding metrics receivers to OTEL config"

# Add metrics exporter to OTEL config
execute_task "add_metrics_exporter_to_otel_config" "adding metrics exporter to OTEL config"