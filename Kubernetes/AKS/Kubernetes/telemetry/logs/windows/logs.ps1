#################################################################################################################################
##################################################### Logs Windows Script #######################################################
#################################################################################################################################

# Load functions
Write-Log "INFO" "Loading logs functions ..."
. $logzioTempDir\logs_functions.ps1

# Build enable logs Helm set
Invoke-Task "Build-EnableLogsHelmSet" "building enable logs Helm set"

# Build Logz.io logs listener URL Helm set
Invoke-Task "Build-LogzioLogsListenerUrlHelmSet" "building Logz.io logs listener URL Helm set"

# Build Logz.io logs token Helm set
Invoke-Task "Build-LogzioLogsTokenHelmSet" "building Logz.io logs token Helm set"

# Build multiline Helm sets
#Invoke-Task "Build-MultilineHelmSets" "building multiline Helm sets"

# Finished successfully
Exit 0
