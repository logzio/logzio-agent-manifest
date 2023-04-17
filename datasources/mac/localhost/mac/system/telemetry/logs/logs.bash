#!/bin/bash

#################################################################################################################################
################################################# MAC Datasource Logs Script ####################################################
#################################################################################################################################

# Print title
echo
echo -e '############'
echo -e "###$PURPLE_COLOR Logs $WHITE_COLOR###"
echo -e '############'

EXIT_CODE=1

# Load datasource logs utils functions
load_logs_utils

# Get Logz.io logs token
execute_task 'get_logzio_logs_token' 'Getting Logz.io logs token'
# Get log sources
execute_task 'get_log_sources' 'Getting log sources'
# Add logs pipeline to OTEL config
execute_task 'add_logs_pipline_to_otel_config' 'Adding logs pipeline to OTEL config'
# Get logs OTEL receivers
execute_task 'get_logs_otel_receivers' 'Getting logs OTEL receivers'
# Add logs receivers to OTEL config
execute_task 'add_logs_receivers_to_otel_config' 'Adding logs receivers to OTEL config'
# Get logs OTEL processors
execute_task 'get_logs_otel_processors' 'Getting logs OTEL processors'
# Add logs processors to OTEL config
execute_task 'add_logs_processors_to_otel_config' 'Adding logs processors to OTEL config'
# Add logs exporter to OTEL config
execute_task 'add_logs_exporter_to_otel_config' 'Adding logs exporter to OTEL config'
