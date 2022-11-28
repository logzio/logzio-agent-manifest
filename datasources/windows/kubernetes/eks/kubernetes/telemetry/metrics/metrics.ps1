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
# Build Logz.io metrics listener URL Helm set
Invoke-Task 'Build-LogzioMetricsListenerUrlHelmSet' @{ListenerUrl = $script:ListenerUrl} 'Building Logz.io metrics listener URL Helm set' @($MetricsFunctionsScript)
# Build Logz.io metrics token Helm set
Invoke-Task 'Build-LogzioMetricsTokenHelmSet' @{MetricsToken = $script:MetricsToken} 'Building Logz.io metrics token Helm set' @($MetricsFunctionsScript)
# Get if metrics filter option was selected
Invoke-Task 'Get-IsFilterWasSelected' @{MetricsParams = $script:MetricsParams} 'Getting if metrics filter was selected' @($MetricsFunctionsScript)
if ($script:IsFilter) {
    # Build enable metrics filter Helm set
    Invoke-Task 'Build-EnableMetricsFilterHelmSet' @{} 'Building enable metrics filter Helm set' @($MetricsFunctionsScript)
}

# Finished successfully
Exit 0
