#!/bin/bash

#################################################################################################################################
################################################### Prerequisites Mac Script ####################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading prerequisites functions ..."
source ./logzio-temp/prerequisites_functions.bash

# Check if kubectl is installed
execute_task "get_otelcontribcol_binary" "getting otelcontribcol binary"

# Check if Kubernetes cluster can connect to Logz.io logs (port 8071)
execute_task "can_localhost_connect_to_logzio_logs" "checking if localhost can connect to Logz.io logs"

# Check if Kubernetes cluster can connect to Logz.io metrics (port 8053)
execute_task "can_localhost_connect_to_logzio_metrics" "checking if localhost can connect to Logz.io metrics"
