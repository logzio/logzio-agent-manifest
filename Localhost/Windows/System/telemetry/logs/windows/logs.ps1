#################################################################################################################################
##################################################### Logs Windows Script #######################################################
#################################################################################################################################

# Load functions
Write-Log "INFO" "Loading logs functions ..."
. $logzioTempDir\logs_functions.ps1

# `get Logz.io region
Invoke-Task "Get-LogzioRegion" "getting Logz.io region"

# Get Logz.io logs token
Invoke-Task "Get-LogzioLogsToken" "getting Logz.io logs token"

# Get log sources
Invoke-Task "Get-LogSources" "getting log sources"

# Get selected logs
Invoke-Task "Get-SelectedLogs" "getting selected logs"

# Add logs receivers to OTEL config
Invoke-Task "Add-LogsReceiversToOTELConfig" "adding logs receivers to OTEL config"

# Add logs exporter to OTEL config
Invoke-Task "Add-LogsExporterToOTELConfig" "adding logs exporter to OTEL config"

# Finished successfully
Exit 0
