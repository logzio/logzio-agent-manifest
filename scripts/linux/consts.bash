#!/bin/bash

#################################################################################################################################
####################################################### LINUX Consts Script #####################################################
#################################################################################################################################

## Agent Directories
# Logz.io temp directory
LOGZIO_TEMP_DIR='/tmp/logzio'
# Logz.io opt directory
LOGZIO_OPT_DIR='/opt/logzio-agent'

## Resources Directory
# Resources directory
LOGZIO_RESOURCES_DIR="$LOGZIO_TEMP_DIR/resources"

## OTEL Directories
# Logz.io OTEL collector opt subdirectory
LOGZIO_OTEL_COLLECTOR_DIR="$LOGZIO_OPT_DIR/Logzio-otel-collector"
# Resources OTEL directory
OTEL_RESOURCES_DIR="$LOGZIO_RESOURCES_DIR/otel"
# OTEL receivers directory
OTEL_RECEIVERS_DIR="$OTEL_RESOURCES_DIR/receivers"
# OTEL processors directory
OTEL_PROCESSORS_DIR="$OTEL_RESOURCES_DIR/processors"
# OTEL exporters directory
OTEL_EXPORTERS_DIR="$OTEL_RESOURCES_DIR/exporters"

## Kubernetes Directories
# Logz.io Kubernetes AppData subdirectory
LOGZIO_KUBERNETES_DIR="$LOGZIO_OPT_DIR/logzio-kubernetes"
# Resources Kubernetes directory
KUBERNETES_RESOURCES_DIR="$LOGZIO_RESOURCES_DIR/k8s"

## Agent files
# Log file path
AGENT_LOG_FILE="$LOGZIO_OPT_DIR/logzio_agent.log"
# Task post run script file path
TASK_POST_RUN_FILE="$LOGZIO_TEMP_DIR/task_post_run.bash"
# Task error file path
TASK_ERROR_FILE="$LOGZIO_TEMP_DIR/task_error.txt"
# Agent json file path
AGENT_JSON="$LOGZIO_TEMP_DIR/agent.json"

## Urls
# Url for downloading jq exe
JQ_URL_DOWNLOAD='https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64'
# Url for downloading yq exe
YQ_URL_DOWNLOAD='https://github.com/mikefarah/yq/releases/download/v4.27.2/yq_linux_amd64.tar.gz'
# Url for downloading OTEL collector tar.gz
OTEL_COLLECTOR_URL_DOWNLOAD='https://github.com/logzio/otel-collector-distro/releases/download/v0.56.1/otelcol-logzio-linux_amd64.tar.gz'
# Url for AWS SQS
SQS_URL='https://sqs.us-east-1.amazonaws.com/486140753397/LogzioAgentQueue'

## Exe files
# Jq binary file path
JQ_BIN="$LOGZIO_TEMP_DIR/jq"
# Yq binary file path
YQ_BIN="$LOGZIO_TEMP_DIR/yq_linux_amd64"

## OTEL files
# OTEL function file
OTEL_FUNCTION_FILE="$LOGZIO_TEMP_DIR/otel_function.bash"
# OTEL collector binary file name
OTEL_COLLECTOR_BIN_NAME='otelcol-logzio-windows_amd64.exe'
# OTEL collector binary file path
OTEL_COLLECTOR_BIN="$LOGZIO_OTEL_COLLECTOR_DIR/$OTEL_COLLECTOR_BIN_NAME"
# OTEL config file name
OTEL_CONFIG_NAME='otel_config.yaml'
# OTEL config file path
OTEL_CONFIG="$LOGZIO_OTEL_COLLECTOR_DIR/OTEL_CONFIG_NAME"

## Kubernetes files
# Logz.io Helm file path
LOGZIO_HELM_FILE="$LOGZIO_KUBERNETES_DIR/logzio_helm.txt"

## Service names
# Logz.io OTEL collector service name
LOGZIO_OTEL_COLLECTOR_SERVICE_NAME='LogzioOTELCollector'

## Script files
AGENT_FUNCTIONS_FILE="$LOGZIO_TEMP_DIR/functions.bash"
CONSTS_FILE="$LOGZIO_TEMP_DIR/consts.bash"
PREREQUISITES_FILE='prerequisites\prerequisites.bash'
PREREQUISITES_FUNCTIONS_FILE='prerequisites\functions.bash'
INSTALLER_FILE='installer\installer.bash'
AGENT_INFO_FILE='installer\agent_info.bash'
INSTALLER_FUNCTIONS_FILE='installer\functions.bash'
LOGS_FILE='telemetry\logs\logs.bash'
LOGS_FUNCTIONS_FILE='telemetry\logs\functions.bash'
METRICS_FILE='telemetry\metrics\metrics.bash'
METRICS_FUNCTIONS_FILE='telemetry\metrics\functions.bash'
TRACES_FILE='telemetry\traces\traces.bash'
TRACES_FUNCTIONS_FILE='telemetry\traces\functions.bash'
POSTREQUISITES_FILE='postrequisites\postrequisites.bash'
POSTREQUISITES_FUNCTIONS_FILE='postrequisites\functions.bash'

## Log levels
LOG_LEVEL_DEBUG='DEBUG'
LOG_LEVEL_INFO='INFO'
LOG_LEVEL_ERROR='ERROR'
LOG_LEVEL_WARN='WARN'

## Log steps
LOG_STEP_PRE_INIT='Pre-Init'
LOG_STEP_DOWNLOADS='Downloads'
LOG_STEP_INIT='Init'
LOG_STEP_PREREQUISITES='Prerequisites'
LOG_STEP_PRE_INSTALLATION='Pre-Installation'
LOG_STEP_INSTALLATION='Installation'
LOG_STEP_LOGS='Logs'
LOG_STEP_METRICS='Metrics'
LOG_STEP_TRACES='Traces'
LOG_STEP_POSTREQUISITES='Post-Requisites'
LOG_STEP_FINAL='Final'

## Log script names
LOG_SCRIPT_AGENT='agent.bash'
LOG_SCRIPT_UTILS_FUNCTIONS='utils_functions.bash'
LOG_SCRIPT_PREREQUISITES='prerequisites.bash'
LOG_SCRIPT_INSTALLER='installer.bash'
LOG_SCRIPT_LOGS='logs.bash'
LOG_SCRIPT_METRICS='metrics.bash'
LOG_SCRIPT_TRACES='traces.bash'
LOG_SCRIPT_POSTREQUISITES='postrequisites.bash'

## Colors
RED_COLOR='\033[0;31m'
YELLOW_COLOR='\033[0;33m'
PURPLE_COLOR='\033[0;35m'
WHITE_COLOR='\033[0;37m'
RED_COLOR_BOLD='\033[1;31m'
GREEN_COLOR_BOLD='\033[0;32m'