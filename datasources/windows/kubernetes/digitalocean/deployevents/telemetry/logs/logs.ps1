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
# Build enable deploy events Helm set
Invoke-Task 'Build-EnableDeployEventsHelmSet' @{} 'Building enable deploy events Helm set' @($LogsFunctionsScript)
# Build Logz.io Deploy events logs listener url Helm set
Invoke-Task 'Build-LogzioDeployEventsLogsListenerUrlHelmSet' @{ListenerUrl = $script:ListenerUrl} 'Building Logz.io deploy events logs listener url Helm set' @($LogsFunctionsScript)
# Build Logz.io Deploy events logs token Helm set
Invoke-Task 'Build-LogzioDeployEventsLogsTokenHelmSet' @{LogsToken = $script:LogsToken} 'Building Logz.io deploy events logs token Helm set' @($LogsFunctionsScript)
# Build Deploy events environment id Helm set
Invoke-Task 'Build-DeployEventsEnvironmentIdHelmSet' @{EnvId = $script:EnvId} 'Building Deploy events environment id Helm set' @($LogsFunctionsScript)

# Finished successfully
Exit 0
