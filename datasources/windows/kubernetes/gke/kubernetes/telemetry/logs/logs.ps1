#################################################################################################################################
##################################################### WINDOWS Logs Script #######################################################
#################################################################################################################################

$local:LogsFunctionsScript = "$script:LogzioTempDir\$script:Platform\$script:SubType\$($script:CurrentDataSource.ToLower())\$script:LogsFunctionsFile"

# Print headline
Write-Host
Write-Host '############'
Write-Host '### ' -NoNewline
Write-Host 'Logs' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '############'

# Get Logz.io logs token
Invoke-Task 'Get-LogzioLogsToken' @{} 'Getting Logz.io logs token' @($LogsFunctionsScript)
# Build enable logs Helm set
Invoke-Task 'Build-EnableLogsHelmSet' @{} 'Building enable logs Helm set' @($LogsFunctionsScript)
# Build enable opentelemetry log collection Helm set
Invoke-Task 'Build-EnableOtelLogCollectionHelmSet' @{} 'Building enable opentelemetry log collection Helm set' @($LogsFunctionsScript)
# Build disable fluentd log collection Helm set
Invoke-Task 'Build-DisableFluentdHelmSet' @{} 'Building disable fluentd log collection Helm set' @($LogsFunctionsScript)
# Build Logz.io logs token Helm set
Invoke-Task 'Build-LogzioLogsTokenHelmSet' @{LogsToken = $script:LogsToken} 'Building Logz.io logs token Helm set' @($LogsFunctionsScript)

# Finished successfully
Exit 0
