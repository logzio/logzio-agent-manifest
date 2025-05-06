#!/bin/bash

#################################################################################################################################
############################################### LINUX Datasource Traces Script ##################################################
#################################################################################################################################

# Print title
echo
echo -e '##############'
echo -e "###$PURPLE_COLOR Traces $WHITE_COLOR###"
echo -e '##############'

EXIT_CODE=1

# Load datasource traces utils functions
load_traces_utils

# Get Logz.io traces token
execute_task 'get_logzio_traces_token' 'Getting Logz.io traces token'
# Add traces pipeline to OTEL config
execute_task 'add_traces_pipeline_to_otel_config' 'Adding traces pipeline to OTEL config'
# Get traces OTEL receivers (OTLP)
execute_task 'get_traces_otel_receivers' 'Getting traces OTEL receivers'
# Add traces receivers to OTEL config
TRACES_TYPE='agent-localhost-linux'
execute_task 'add_traces_receivers_to_otel_config' 'Adding traces receivers to OTEL config'
# Get traces OTEL processors
execute_task 'get_traces_otel_processors' 'Getting traces OTEL processors'
# Add traces processors to OTEL config
execute_task 'add_traces_processors_to_otel_config' 'Adding traces processors to OTEL config'
# Configure span metrics connector
execute_task 'configure_span_metrics_connector' 'Configuring span metrics connector'
# Add traces exporter to OTEL config (Logz.io)
execute_task 'add_traces_exporter_to_otel_config' 'Adding traces exporter to OTEL config'
# Add metrics exporter for span metrics (Prometheus Remote Write)
execute_task 'add_span_metrics_exporter' 'Adding span metrics exporter to OTEL config'