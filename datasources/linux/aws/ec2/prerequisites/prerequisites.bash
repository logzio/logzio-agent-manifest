#!/bin/bash

#################################################################################################################################
############################################## LINUX Subtype Prerequisites Script ###############################################
#################################################################################################################################

# Print title
echo
echo -e '#####################'
echo -e "###$PURPLE_COLOR Prerequisites $WHITE_COLOR###"
echo -e '#####################'

load_prerequisites_utils

MACHINE_NAME='EC2'
# Check if localhost can connect to Logz.io logs (port 8071)
execute_task 'can_machine_connect_to_logzio_logs' 'Checking if localhost can connect to Logz.io logs'
# Check if localhost can connect to Logz.io metrics (port 8053)
execute_task 'can_machine_connect_to_logzio_metrics' 'Checking if localhost can connect to Logz.io metrics'
