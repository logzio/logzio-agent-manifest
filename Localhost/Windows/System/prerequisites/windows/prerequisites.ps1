#################################################################################################################################
################################################# Prerequisites Windows Script ##################################################
#################################################################################################################################

# Load functions
Write-Log "INFO" "Loading prerequisites functions ..."
. $logzioTempDir\prerequisites_functions.ps1

# Install yq
Invoke-Task "Install-YQ" "installing yq"

# Check if localhost can connect to Logz.io logs (port 8071)
Invoke-Task "Test-CanLocalhostConnectToLogzioLogs" "checking if localhost can connect to Logz.io logs"

# Check if localhost can connect to Logz.io metrics (port 8053)
Invoke-Task "Test-CanLocalhostConnectToLogzioMetrics" "checking if localhost can connect to Logz.io metrics"

# Finished successfully
Exit 0
