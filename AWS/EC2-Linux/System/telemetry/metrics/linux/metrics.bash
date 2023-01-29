#!/bin/bash

#################################################################################################################################
##################################################### Metrics Linux Script ######################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading metrics functions ..."
source $logzio_temp_dir/metrics_functions.bash

# Get Logz.io metrics listener URL
execute_task "get_logzio_metrics_listener_url" "getting Logz.io metrics listener URL"

# Get Logz.io metrics token
execute_task "get_logzio_metrics_token" "getting Logz.io metrics token"

# Add metrics receivers to OTEL config
sudo echo >/dev/null
execute_task "add_metrics_receivers_to_otel_config" "adding metrics receivers to OTEL config"

# Add metrics exporter to OTEL config
sudo echo >/dev/null
execute_task "add_metrics_exporter_to_otel_config" "adding metrics exporter to OTEL config"

# Add metrics address to OTEL config
sudo echo >/dev/null
execute_task "add_metrics_address_to_otel_config" "addind metrics address to OTEL config"

# Add metrics service pipeline to OTEL config
sudo echo >/dev/null
execute_task "add_metrics_service_pipeline_to_otel_config" "adding metrics service pipeline to OTEL config"
