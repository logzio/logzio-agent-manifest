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

# Build enable security report Helm set
Invoke-Task 'Build-EnableSecurityReportHelmSet' @{} 'Building enable security report Helm set' @($LogsFunctionsScript)
# Build Logz.io Trivy logs token Helm set
. ..\..\..\kubernetes\telemetry\logs\functions.ps1
Invoke-Task 'Get-LogzioLogsToken' @{} 'Getting Logz.io logs token' @($LogsFunctionsScript)
Invoke-Task 'Build-LogzioLogsTokenHelmSet' @{LogsToken = $script:LogsToken} 'Building Logz.io Trivy logs token Helm set' @($LogsFunctionsScript)

# Finished successfully
Exit 0
