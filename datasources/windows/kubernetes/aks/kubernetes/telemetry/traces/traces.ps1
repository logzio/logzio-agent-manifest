#################################################################################################################################
#################################################### WINDOWS Traces Script ######################################################
#################################################################################################################################

$local:TracesFunctionsScript = "$script:LogzioTempDir\$script:Platform\$script:SubType\$($script:CurrentDataSource.ToLower())\$script:TracesFunctionsFile"

# Print headline
Write-Host
Write-Host '##############'
Write-Host '### ' -NoNewline
Write-Host 'Traces' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '##############'

# Get Logz.io traces token
Invoke-Task 'Get-LogzioTracesToken' @{} 'Getting Logz.io traces token' @($TracesFunctionsScript)
# Build enable traces Helm set
Invoke-Task 'Build-EnableTracesHelmSet' @{} 'Building enable traces Helm set' @($TracesFunctionsScript)
# Build Logz.io traces token Helm set
Invoke-Task 'Build-LogzioTracesTokenHelmSet' @{TracesToken = $script:TracesToken} 'Building Logz.io traces token Helm set' @($TracesFunctionsScript)
# Build Logz.io region Helm set
Invoke-Task 'Build-LogzioRegionHelmSet' @{ListenerUrl = $script:ListenerUrl} 'Building Logz.io region Helm set' @($TracesFunctionsScript)
# Get Logz.io SPM token
Invoke-Task 'Get-LogzioSpmToken' @{} 'Getting Logz.io SPM token' @($TracesFunctionsScript)
# Build enable SPM Helm set
Invoke-Task 'Build-EnableSpmHelmSet' @{} 'Building enable SPM Helm set' @($TracesFunctionsScript)
# Build Logz.io SPM token Helm set
Invoke-Task 'Build-LogzioSpmTokenHelmSet' @{SpmToken = $script:SpmToken} 'Building Logz.io SPM token Helm set' @($TracesFunctionsScript)
# Get if service graph option was selected
Invoke-Task 'Get-IsServiceGraphWasSelected' @{MetricsParams = $script:MetricsParams} 'Getting if service graph was selected' @($MetricsFunctionsScript)
if ($script:IsServiceGraph) {
    # Build enable metrics filter Helm set
    Invoke-Task 'Build-EnableServiceGraphHelmSet' @{} 'Building enable service graph Helm set' @($MetricsFunctionsScript)
}
# Finished successfully
Exit 0
