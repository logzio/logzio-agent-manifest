#################################################################################################################################
##################################################### WINDOWS Consts Script #####################################################
#################################################################################################################################

# Static Consts

## Directories
# Logz.io temp directory
$script:LogzioTempDir = "$env:TEMP\Logzio"
# Logz.io AppData directory
$script:LogzioAppDataDir = "$env:APPDATA\LogzioAgent"
# Logz.io OTEL collector AppData subdirectory
$script:LogzioOtelCollectorDir = "$script:LogzioAppDataDir\LogzioOTELCollector"
# Resources directory
$script:LogzioResourcesDir = "$script:LogzioTempDir\resources"
# Resources OTEL directory
$script:OtelResourcesDir = "$script:LogzioResourcesDir\otel"
# OTEL receivers directory
$script:OtelReceiversDir = "$script:OtelResourcesDir\receivers"
# OTEL processors directory
$script:OtelProcessorsDir = "$script:OtelResourcesDir\processors"
# OTEL exporters directory
$script:OtelExportersDir = "$script:OtelResourcesDir\exporters"

## Agent files
# Log file path
$script:AgentLogFile = "$script:LogzioAppDataDir\logzio_agent.log"
# Task post run script file path
$script:TaskPostRunFile = "$script:LogzioTempDir\task_post_run.ps1"
# Task error file path
$script:TaskErrorFile = "$script:LogzioTempDir\task_error.txt"
# Agent json file path
$script:AgentJson = "$script:LogzioTempDir\agent.json"
# OTEL function file
$script:OtelFunctionFile = "$script:LogzioTempDir\otel_function.ps1"

## Urls
# Url for downloading jq exe
$script:JqUrlDownload = 'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe'
# Url for downloading yq exe
$script:YqUrlDownload = 'https://github.com/mikefarah/yq/releases/download/v4.27.5/yq_windows_amd64.exe'
# Url for downloading OTEL collector tar.gz
$script:OtelCollectorUrlDownload = 'https://github.com/logzio/otel-collector-distro/releases/download/v0.56.1/otelcol-logzio-windows_amd64.tar.gz'
# Url for AWS SQS
$script:SqsUrl = 'https://sqs.us-east-1.amazonaws.com/486140753397/LogzioAgentQueue'

## Exe files
# Jq exe file path
$script:JqExe = "$script:LogzioTempDir\jq.exe"
# Yq exe file path
$script:YqExe = "$script:LogzioTempDir\yq.exe"
# OTEL collector exe file name
$script:OtelCollectorExeName = 'otelcol-logzio-windows_amd64.exe'
# OTEL collector exe file path
$script:OtelCollectorExe = "$script:LogzioOtelCollectorDir\$script:OtelCollectorExeName"

## Service names
# Logz.io OTEL collector service name
$script:LogzioOtelCollectorServiceName = 'LogzioOTELCollector'

## Datasource names
$script:DataSourceSystem = 'System'

## Script files
$script:AgentFunctionsFile = "$LogzioTempDir\functions.ps1"
$script:ConstsFile = "$LogzioTempDir\consts.ps1"
$script:PrerequisitesFile = 'prerequisites\prerequisites.ps1'
$script:PrerequisitesFunctionsFile = 'prerequisites\functions.ps1'
$script:InstallerFile = 'installer\installer.ps1'
$script:AgentInfoFile = 'installer\agent_info.ps1'
$script:InstallerFunctionsFile = 'installer\functions.ps1'
$script:LogsFile = 'telemetry\logs\logs.ps1'
$script:LogsFunctionsFile = 'telemetry\logs\functions.ps1'
$script:MetricsFile = 'telemetry\metrics\metrics.ps1'
$script:MetricsFunctionsFile = 'telemetry\metrics\functions.ps1'
$script:TracesFile = 'telemetry\traces\traces.ps1'
$script:TracesFunctionsFile = 'telemetry\traces\functions.ps1'

## Log levels
$script:LogLevelDebug = 'DEBUG'
$script:LogLevelInfo = 'INFO'
$script:LogLevelError = 'ERROR'
$script:LogLevelWarn = 'WARN'

## Log steps
$script:LogStepPreInit = 'Pre-Init'
$script:LogStepDownloads = 'Downloads'
$script:LogStepInit = 'Init'
$script:LogStepPrerequisites = 'Prerequisites'
$script:LogStepPreInstallation = 'Pre-Installation'
$script:LogStepInstallation = 'Installation'
$script:LogStepLogs = 'Logs'
$script:LogStepMetrics = 'Metrics'
$script:LogStepTraces = 'Traces'
$script:LogStepFinal = 'Final'

## Log script names
$script:LogScriptAgent = 'agent.ps1'
$script:LogScriptUtilsFunctions = 'utils_functions.ps1'
$script:LogScriptPrerequisites = 'prerequisites.ps1'
$script:LogScriptInstaller = 'installer.ps1'
$script:LogScriptLogs = 'logs.ps1'
$script:LogScriptMetrics = 'metrics.ps1'
$script:LogsScriptTraces = 'traces.ps1'

# Dynamic Consts (Will be added while the agent running)
