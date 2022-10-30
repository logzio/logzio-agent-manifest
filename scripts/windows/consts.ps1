#################################################################################################################################
##################################################### WINDOWS Consts Script #####################################################
#################################################################################################################################

# Static Consts

## Directories
$script:LogzioTempDir = "$env:TEMP\Logzio"                                                                  # Logz.io temp directory
$script:LogzioAppDataDir = "$env:APPDATA\LogzioAgent"                                                       # Logz.io AppData directory
$script:LogzioOtelCollectorDir = "$LogzioAppDataDir\LogzioOTELCollector"                                    # Logz.io OTEL collector AppData subdirectory

## Agent files
$script:AgentLogFile = "$LogzioAppDataDir\logzio_agent.log"                                                 # Log file path
$script:TaskPostRunFile = "$LogzioTempDir\task_post_run.ps1"                                                # Task post run script file path
$script:TaskErrorFile = "$LogzioTempDir\task_error.txt"                                                     # Task error file path
$script:AgentJson = "$LogzioTempDir\agent.json"                                                             # Agent json file path

## Urls
$script:JqUrlDownload = 'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe'              # Url for downloading jq exe
$script:YqUrlDownload = 'https://github.com/mikefarah/yq/releases/download/v4.27.5/yq_windows_amd64.exe'    # Url for downloading yq exe
$script:OtelCollectorUrlDownload = 

## Exe files
$script:JqExe = "$LogzioTempDir\jq.exe"                                                                     # Jq exe file path
$script:YqExe = "$LogzioTempDir\yq.exe"                                                                     # Yq exe file path
$script:OtelCollectorExe = "$LogzioOtelCollectorDir\otelcol-logzio-windows_amd64.exe"                       # OTEL collector exe file path

## Service names
$script:LogzioOtelCollectorServiceName = 'LogzioOTELCollector'

$script:DataSourceSystem = 'System'

## Script files
$script:AgentFunctionsFile = "$LogzioTempDir\functions.ps1"
$script:ConstsFile = "$LogzioTempDir\consts.ps1"
$script:PrerequisitesFile = 'prerequisites\prerequisites.ps1'
$script:PrerequisitesFunctionsFile = 'prerequisites\functions.ps1'
$script:InstallerFile = 'installer\installer.ps1'
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

# Dynamic Consts
