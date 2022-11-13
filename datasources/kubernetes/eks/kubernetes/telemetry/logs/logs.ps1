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
# Build Logz.io logs listener url Helm set
Invoke-Task 'Build-LogzioLogsListenerUrlHelmSet' @{ListenerUrl = $script:ListenerUrl} 'Building Logz.io logs listener url Helm set' @($LogsFunctionsScript)
# Build Logz.io logs token Helm set
Invoke-Task 'Build-LogzioLogsTokenHelmSet' @{LogsToken = $script:LogsToken} 'Building Logz.io logs token Helm set' @($LogsFunctionsScript)
# Build environment id Helm set
Invoke-Task 'Build-EnvironmentIdHelmSet' @{EnvId = $script:EnvId} 'Building environment id Helm set' @($LogsFunctionsScript)

# Finished successfully
Exit 0
