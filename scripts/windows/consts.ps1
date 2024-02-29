#################################################################################################################################
##################################################### WINDOWS Consts Script #####################################################
#################################################################################################################################

# Static Consts

## Agent Directories
# Logz.io temp directory
$script:LogzioTempDir = "$env:TEMP\Logzio"
# Logz.io AppData directory
$script:LogzioAppDataDir = "$env:APPDATA\LogzioAgent"

## Resources Directory
# Resources directory
$script:LogzioResourcesDir = "$script:LogzioTempDir\resources"

## OTEL Directories
# Logz.io OTEL collector AppData subdirectory
$script:LogzioOtelCollectorDir = "$script:LogzioAppDataDir\LogzioOTELCollector"
# Resources OTEL directory
$script:OtelResourcesDir = "$script:LogzioResourcesDir\otel"
# OTEL receivers directory
$script:OtelReceiversDir = "$script:OtelResourcesDir\receivers"
# OTEL processors directory
$script:OtelProcessorsDir = "$script:OtelResourcesDir\processors"
# OTEL exporters directory
$script:OtelExportersDir = "$script:OtelResourcesDir\exporters"

## Kubernetes Directories
# Logz.io Kubernetes AppData subdirectory
$script:LogzioKubernetesDir = "$script:LogzioAppDataDir\LogzioKubernetes"
# Resources Kubernetes directory
$script:KubernetesResourcesDir = "$script:LogzioResourcesDir\k8s"

## Agent files
# Log file path
$script:AgentLogFile = "$script:LogzioAppDataDir\logzio_agent$script:AgentLogFileTimestamp.log"
# Task post run script file path
$script:TaskPostRunFile = "$script:LogzioTempDir\task_post_run.ps1"
# Task error file path
$script:TaskErrorFile = "$script:LogzioTempDir\task_error.txt"
# Agent json file path
$script:AgentJson = "$script:LogzioTempDir\agent.json"

## Urls
# Url for downloading jq exe
$script:JqUrlDownload = 'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe'
# Url for downloading yq exe
$script:YqUrlDownload = 'https://github.com/mikefarah/yq/releases/download/v4.27.5/yq_windows_amd64.exe'
# Url for downloading OTEL collector zip
$script:OtelCollectorUrlDownload = 'https://github.com/logzio/otel-collector-distro/releases/download/v0.95.0/otelcol-logzio-windows_amd64.zip'
# Url for downloading eksctl zip
$script:EksctlUrlDownload = 'https://github.com/weaveworks/eksctl/releases/download/v0.133.0/eksctl_Windows_amd64.zip'
# Url for AWS SQS
$script:SqsUrl = 'https://sqs.us-east-1.amazonaws.com/486140753397/LogzioAgentQueue'

## Exe files
# Jq exe file path
$script:JqExe = "$script:LogzioTempDir\jq.exe"
# Yq exe file path
$script:YqExe = "$script:LogzioTempDir\yq.exe"
# Eksctl exe file path
$script:EksctlExe = "$script:LogzioTempDir\eksctl.exe"

## OTEL files
# OTEL function file
$script:OtelFunctionFile = "$script:LogzioTempDir\otel_function.ps1"
# OTEL collector exe file name
$script:OtelCollectorExeName = 'otelcol-logzio-windows_amd64.exe'
# OTEL collector exe file path
$script:OtelCollectorExe = "$script:LogzioOtelCollectorDir\$script:OtelCollectorExeName"
# OTEL config file name
$script:OtelConfigName = 'otel_config.yaml'
# OTEL config file path
$script:OtelConfig = "$script:LogzioOtelCollectorDir\$script:OtelConfigName"

## Kubernetes files
# Logz.io Helm file path
$script:LogzioHelmFile = "$script:LogzioKubernetesDir\logzio_helm.txt"

## Service names
# Logz.io OTEL collector service name
$script:LogzioOtelCollectorServiceName = 'LogzioOTELCollector'

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
$script:PostrequisitesFile = 'postrequisites\postrequisites.ps1'
$script:PostrequisitesFunctionsFile = 'postrequisites\functions.ps1'

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
$script:LogStepPostrequisites = 'Post-Requisites'
$script:LogStepFinal = 'Final'

## Log script names
$script:LogScriptAgent = 'agent.ps1'
$script:LogScriptUtilsFunctions = 'utils_functions.ps1'
$script:LogScriptPrerequisites = 'prerequisites.ps1'
$script:LogScriptInstaller = 'installer.ps1'
$script:LogScriptLogs = 'logs.ps1'
$script:LogScriptMetrics = 'metrics.ps1'
$script:LogsScriptTraces = 'traces.ps1'
$script:LogScriptPostrequisites = 'postrequisites.ps1'

# Dynamic Consts (Will be added while the agent running)
