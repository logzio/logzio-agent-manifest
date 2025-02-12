#################################################################################################################################
#################################################### WINDOWS Metrics Script #####################################################
#################################################################################################################################

$local:MetricsFunctionsScript = "$script:LogzioTempDir\$script:Platform\$script:SubType\$($script:CurrentDataSource.ToLower())\$script:MetricsFunctionsFile"

# Print headline
Write-Host
Write-Host '###############'
Write-Host '### ' -NoNewline
Write-Host 'Metrics' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '###############'

# Get Logz.io metrics token
Invoke-Task 'Get-LogzioMetricsToken' @{} 'Getting Logz.io metrics token' @($MetricsFunctionsScript)
# Build enable metrics Helm set
Invoke-Task 'Build-EnableMetricsHelmSet' @{} 'Building enable metrics Helm set' @($MetricsFunctionsScript)
# Build Logz.io metrics token Helm set
Invoke-Task 'Build-LogzioMetricsTokenHelmSet' @{MetricsToken = $script:MetricsToken} 'Building Logz.io metrics token Helm set' @($MetricsFunctionsScript)
# Get if metrics filter option was selected
Invoke-Task 'Get-IsMetricsFilterWasSelected' @{MetricsParams = $script:MetricsParams} 'Getting if metrics filter was selected' @($MetricsFunctionsScript)
if ($script:IsFilter) {
    # Build enable metrics filter Helm set
    Invoke-Task 'Build-EnableMetricsFilterHelmSet' @{} 'Building enable metrics filter Helm set' @($MetricsFunctionsScript)
}
# Get if Kubernetes object logs option was selected
Invoke-Task 'Get-IsObjectLogsWasSelected' @{MetricsParams = $script:MetricsParams} 'Getting if Kubernetes object logs was selected' @($MetricsFunctionsScript)
if ($script:IsObjectLogs) {
    # Build enable Kubernetes object logs Helm set
    Invoke-Task 'Build-EnableObjectLogsHelmSet' @{} 'Building enable Kubernetes object logs Helm set' @($MetricsFunctionsScript)
    # Get Logz.io Kubernetes object logs token
    . ..\logs\functions.ps1
    Invoke-Task 'Get-LogzioLogsToken' @{} 'Getting Logz.io Kubernetes object logs token' @($MetricsFunctionsScript)
    Invoke-Task 'Get-LogzioLogsTokenHelmSet' @{} 'Building Logz.io Kubernetes object logs token Helm set' @($MetricsFunctionsScript)
}
# Finished successfully
Exit 0
