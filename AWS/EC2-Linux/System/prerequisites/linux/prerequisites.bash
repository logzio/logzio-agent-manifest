#!/bin/bash

#################################################################################################################################
################################################## Prerequisites Linux Script ###################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading prerequisites functions ..."
source ./logzio-temp/prerequisites_functions.bash

# Install yq
execute_task "install_yq" "installing yq"

# Check if EC2 server can connect to Logz.io logs (port 8071)
execute_task "can_ec2_server_connect_to_logzio_logs" "checking if EC2 server can connect to Logz.io logs"

# Check if EC2 server can connect to Logz.io metrics (port 8053)
execute_task "can_ec2_server_connect_to_logzio_metrics" "checking if EC2 server can connect to Logz.io metrics"
