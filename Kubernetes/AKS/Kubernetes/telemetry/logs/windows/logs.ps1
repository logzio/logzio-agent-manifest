#################################################################################################################################
##################################################### Logs Windows Script #######################################################
#################################################################################################################################

# Load functions
Write-Log "INFO" "Loading logs functions ..."
. $logzio_temp_dir\logs_functions.ps1

# Build enable logs Helm set
Invoke-Task "build_enable_logs_helm_set" "building enable logs Helm set"

# Build Logz.io logs listener URL Helm set
Invoke-Task "Build-LogzioLogsListenerUrlHelmSet" "building Logz.io logs listener URL Helm set"

# Build Logz.io logs token Helm set
Invoke-Task "Build-LogzioLogsTokenHelmSet" "building Logz.io logs token Helm set"

# Build multiline Helm sets
#Invoke-Task "Build-MultilineHelmSets" "building multiline Helm sets"
