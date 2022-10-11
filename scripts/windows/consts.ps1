#################################################################################################################################
##################################################### WINDOWS Consts Script #####################################################
#################################################################################################################################

# Static Consts
$script:LogzioTempDir = "$env:TEMP\Logzio"                                                  # Logz.io temp directory
$script:LogzioAppDataDir = "$env:APPDATA\LogzioAgent"                                       # Logz.io AppData directory
$script:LogFile = "$LogzioAppDataDir\logzio_agent.log"                                      # Log file path
$script:TaskPostRunFile = "$LogzioTempDir\task_post_run.ps1"                                # Task post run script file path
$script:TaskErrorFile = "$LogzioTempDir\task_error.txt"                                     # Task error file path
$script:AppJson = "$LogzioTempDir\app.json"                                                 # App json file path
$script:JqExe = "$LogzioTempDir\jq.exe"                                                     # Jq exe file path
$script:YqExe = "$LogzioTempDir\yq.exe"                                                     # Yq exe file path

$script:LogLevelDebug = 'DEBUG'
$script:LogLevelInfo = 'INFO'
$script:LogLevelError = 'ERROR'
$script:LogLevelWarn = 'WARN'

$script:LogStepPreInit = 'Pre-Init'
$script:LogStepDownloads = 'Downloads'
$script:LogStepInit = 'Init'

$script:LogScriptAgent = 'agent.ps1'

# Dynamic Consts
