#################################################################################################################################
##################################################### WINDOWS Logs Script #######################################################
#################################################################################################################################

# Print headline
Write-Host
Write-Host '      ############'
Write-Host '      ### ' -NoNewline
Write-Host 'Logs' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '      ############'

# Get Logz.io region
Invoke-Task 'Get-LogzioRegion' @{} 'Getting Logz.io region' @("$LogzioTempDir\$Platform\$SubType\$DataSource\telemetry\logs\functions.ps1") 6
# Get Logz.io logs token
#Invoke-Task "Get-LogzioLogsToken" "getting Logz.io logs token"
# Get log sources
#Invoke-Task "Get-LogSources" "getting log sources"
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
