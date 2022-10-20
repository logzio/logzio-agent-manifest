#################################################################################################################################
##################################################### WINDOWS Logs Script #######################################################
#################################################################################################################################

$local:LogsFunctionsScript = "$LogzioTempDir\$Platform\$SubType\$DataSourceSystem\$LogsFunctionsFile"

# Print headline
Write-Host
Write-Host '############'
Write-Host '### ' -NoNewline
Write-Host 'Logs' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '############'

# Get Logz.io logs token
Invoke-Task 'Get-LogzioLogsToken' @{} 'Getting Logz.io logs token' @($LogsFunctionsScript)
# Get log sources
Invoke-Task 'Get-LogSources' @{LogsParams = $LogsParams} 'Getting log sources' @($LogsFunctionsScript)
# Get selected logs
#Invoke-Task "Get-SelectedLogs" "getting selected logs"
# Add logs receivers to OTEL config
#Invoke-Task "Add-LogsReceiversToOTELConfig" "adding logs receivers to OTEL config"
# Add logs exporter to OTEL config
#Invoke-Task "Add-LogsExporterToOTELConfig" "adding logs exporter to OTEL config"
# Add logs service pipeline to OTEL config
#Invoke-Task "Add-LogsServicePipelineToOTELConfig" "adding logs service pipeline to OTEL config"

# Finished successfully
Exit 0
