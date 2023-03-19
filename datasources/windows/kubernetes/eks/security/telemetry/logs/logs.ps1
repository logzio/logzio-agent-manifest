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
# Build enable security report Helm set
Invoke-Task 'Build-EnableSecurityReportHelmSet' @{} 'Building enable security report Helm set' @($LogsFunctionsScript)
# Build Logz.io Trivy logs listener url Helm set
Invoke-Task 'Build-LogzioTrivyLogsListenerUrlHelmSet' @{ListenerUrl = $script:ListenerUrl} 'Building Logz.io Trivy logs listener url Helm set' @($LogsFunctionsScript)
# Build Logz.io Trivy logs token Helm set
Invoke-Task 'Build-LogzioTrivyLogsTokenHelmSet' @{LogsToken = $script:LogsToken} 'Building Logz.io Trivy logs token Helm set' @($LogsFunctionsScript)
# Build Trivy environment id Helm set
Invoke-Task 'Build-TrivyEnvironmentIdHelmSet' @{EnvId = $script:EnvId} 'Building Trivy environment id Helm set' @($LogsFunctionsScript)

# Finished successfully
Exit 0
