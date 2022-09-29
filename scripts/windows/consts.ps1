#################################################################################################################################
##################################################### WINDOWS Consts Script #####################################################
#################################################################################################################################

# Consts
$script:repoURL = "https://raw.githubusercontent.com/logzio/logzio-agent-manifest/"          # Logz.io repo URL
$script:LogzioTempDir = "$env:TEMP\logzio"                                                   # Logz.io temp directory
$script:LogzioAppDataDir = "$env:APPDATA\LogzioAgent"                                        # Logz.io AppData directory
$script:LogFile = "$LogzioAppDataDir\logzio_agent.log"                                       # Log file path
$script:TaskPostRunFile = "$logzioTempDir\task_post_run.ps1"                                 # Task post run script file path
$script:TaskErrorFile = "$logzioTempDir\task_error.txt"                                      # Task error file path
$script:AppJson = "$logzioTempDir\app.json"                                                  # App json file path
