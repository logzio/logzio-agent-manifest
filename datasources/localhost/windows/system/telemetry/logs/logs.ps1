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
# Get if application log option was selected
Invoke-Task 'Get-IsApplicationLogSelected' @{LogsParams = $LogsParams} 'Getting if application log option was selected' @($LogsFunctionsScript)
# Get if security log option was selected
Invoke-Task 'Get-IsSecurityLogSelected' @{LogsParams = $LogsParams} 'Getting if security log option was selected' @($LogsFunctionsScript)
# Get if system log option was selected
Invoke-Task 'Get-IsSystemLogSelected' @{LogsParams = $LogsParams} 'Getting if system log option was selected' @($LogsFunctionsScript)
# Get logs OTEL receivers
Invoke-Task 'Get-LogsOtelReceivers' @{LogsTelemetry = $LogsTelemetry} 'Getting logs OTEL receivers' @($LogsFunctionsScript)
# Add logs receivers to OTEL config
Invoke-Task 'Add-LogsReceiversToOtelConfig' @{LogsOtelReceivers = $LogsOtelReceivers; LogSources = $LogSources; IsApplicationLog = $IsApplicationLog; IsSecurityLog = $IsSecurityLog; IsSystemLog = $IsSystemLog} 'Adding logs receivers to OTEL config' @($LogsFunctionsScript)
# Add logs exporter to OTEL config
#Invoke-Task "Add-LogsExporterToOTELConfig" "adding logs exporter to OTEL config"
# Add logs service pipeline to OTEL config
#Invoke-Task "Add-LogsServicePipelineToOTELConfig" "adding logs service pipeline to OTEL config"

# Finished successfully
Exit 0
