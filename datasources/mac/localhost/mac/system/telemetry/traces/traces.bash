#!/bin/bash

#################################################################################################################################
################################################ MAC Datasource Traces Script ###################################################
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
TRACES_TYPE='agent-localhost-mac'
execute_task 'add_traces_receivers_to_otel_config' 'Adding traces receivers to OTEL config'
# Get traces OTEL processors
execute_task 'get_traces_otel_processors' 'Getting traces OTEL processors'
# Add traces processors to OTEL config
execute_task 'add_traces_processors_to_otel_config' 'Adding traces processors to OTEL config'
# Add traces exporter to OTEL config (Logz.io)
execute_task 'add_traces_exporter_to_otel_config' 'Adding traces exporter to OTEL config'

# Print span metrics title
echo
echo -e '##############'
echo -e "###$PURPLE_COLOR Span Metrics $WHITE_COLOR###"
echo -e '##############'

# Get Logz.io metrics token
execute_task 'get_logzio_metrics_token' 'Getting Logz.io metrics token'
# Add spanmetrics pipeline to OTEL config
execute_task 'add_spanmetrics_pipeline_to_otel_config' 'Adding span metrics pipeline to OTEL config'
# Add spanmetrics connector to OTEL config
execute_task 'add_spanmetrics_connector_to_otel_config' 'Adding span metrics connector to OTEL config'
# Add spanmetrics processors to OTEL config
execute_task 'add_spanmetrics_processors_to_otel_config' 'Adding span metrics processors to OTEL config'
# Add spanmetrics exporter to OTEL config
execute_task 'add_spanmetrics_exporter_to_otel_config' 'Adding span metrics exporter to OTEL config'