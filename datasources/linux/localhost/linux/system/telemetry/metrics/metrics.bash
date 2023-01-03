#!/bin/bash

#################################################################################################################################
##################################################### LINUX Metrics Script ######################################################
#################################################################################################################################

# Print headline
echo
echo -e '###############'
echo -e "###$PURPLE_COLOR Metrics $WHITE_COLOR###"
echo -e '###############'

# Get Logz.io metrics token
execute_task 'get_logzio_metrics_token' 'Getting Logz.io metrics token'
# Add metrics pipeline to OTEL confing
execute_task 'add_metrics_pipline_to_otel_config' 'Adding metrics pipeline to OTEL confing'
# Get metrics OTEL receivers
execute_task 'get_metrics_otel_receivers' 'Getting metrics OTEL receivers'
# Add metrics receivers to OTEL config
execute_task 'add_metrics_receivers_to_otel_config' 'Adding metrics receivers to OTEL config'
# Gets metrics OTEL processors
execute_task 'get_metrics_otel_processors' 'Getting metrics OTEL processors'
# Add metrics processors to OTEL config
execute_task 'add_metrics_processors_to_otel_config' 'Adding metrics processors to OTEL config'
# Add metrics exporter to OTEL config
execute_task 'add_metrics_exporter_to_otel_config' 'Adding metrics exporter to OTEL config'
# Set metrics address to OTEL config
execute_task 'set_metrics_address_to_otel_config' 'Setting metrics address to OTEL config'
