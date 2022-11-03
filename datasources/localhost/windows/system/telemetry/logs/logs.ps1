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
Invoke-Task 'Get-LogSources' @{LogsParams = $script:LogsParams} 'Getting log sources' @($LogsFunctionsScript)
# Get if application log option was selected
Invoke-Task 'Get-IsApplicationLogSelected' @{LogsParams = $script:LogsParams} 'Getting if application log option was selected' @($LogsFunctionsScript)
# Get if security log option was selected
Invoke-Task 'Get-IsSecurityLogSelected' @{LogsParams = $script:LogsParams} 'Getting if security log option was selected' @($LogsFunctionsScript)
# Get if system log option was selected
Invoke-Task 'Get-IsSystemLogSelected' @{LogsParams = $script:LogsParams} 'Getting if system log option was selected' @($LogsFunctionsScript)
# Add logs pipeline to OTEL config
Invoke-Task 'Add-LogsPiplineToOtelConfig' @{} 'Adding logs pipeline to OTEL config' @($LogsFunctionsScript)
# Get logs OTEL receivers
Invoke-Task 'Get-LogsOtelReceivers' @{LogsTelemetry = $script:LogsTelemetry} 'Getting logs OTEL receivers' @($LogsFunctionsScript)
# Add logs receivers to OTEL config
Invoke-Task 'Add-LogsReceiversToOtelConfig' @{LogsOtelReceivers = $script:LogsOtelReceivers; LogSources = $script:LogSources; IsApplicationLog = $script:IsApplicationLog; IsSecurityLog = $IsSecurityLog; IsSystemLog = $IsSystemLog} 'Adding logs receivers to OTEL config' @($LogsFunctionsScript)
# Get logs OTEL processors
Invoke-Task 'Get-LogsOtelProcessors' @{LogsTelemetry = $script:LogsTelemetry} 'Getting logs OTEL processors' @($LogsFunctionsScript)
# Add logs processors to OTEL config
Invoke-Task 'Add-LogsProcessorsToOtelConfig' @{LogsOtelProcessors = $script:LogsOtelProcessors} 'Adding logs processors to OTEL config' @($LogsFunctionsScript)
# Add logs exporter to OTEL config
Invoke-Task 'Add-LogsExporterToOtelConfig' @{LogsToken = $script:LogsToken; ListenerUrl = $script:ListenerUrl} 'Adding logs exporter to OTEL config' @($LogsFunctionsScript)

# Finished successfully
Exit 0
