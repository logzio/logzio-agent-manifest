#################################################################################################################################
#################################################### WINDOWS Metrics Script #####################################################
#################################################################################################################################

$local:MetricsFunctionsScript = "$LogzioTempDir\$Platform\$SubType\$DataSourceSystem\$MetricsFunctionsFile"

# Print headline
Write-Host
Write-Host '###############'
Write-Host '### ' -NoNewline
Write-Host 'Metrics' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '###############'

# Get Logz.io metrics token
Invoke-Task 'Get-LogzioMetricsToken' @{} 'Getting Logz.io metrics token' @($MetricsFunctionsScript)
# Add metrics pipeline to OTEL confing
Invoke-Task 'Add-MetricsPiplineToOtelConfig' @{} 'Adding metrics pipeline to OTEL confing' @($MetricsFunctionsScript)
# Get metrics OTEL receivers
Invoke-Task 'Get-MetricsOtelReceivers' @{MetricsTelemetry = $script:MetricsTelemetry} 'Getting metrics OTEL receivers' @($MetricsFunctionsScript)
# Add metrics receivers to OTEL config
Invoke-Task 'Add-MetricsReceiversToOtelConfig' @{MetricsOtelReceivers = $script:MetricsOtelReceivers} 'Adding metrics receivers to OTEL config' @($MetricsFunctionsScript)
# Gets metrics OTEL processors
Invoke-Task 'Get-MetricsOtelProcessors' @{MetricsTelemetry = $script:MetricsTelemetry} 'Getting metrics OTEL processors' @($MetricsFunctionsScript)
# Add metrics processors to OTEL config
Invoke-Task 'Add-MetricsProcessorsToOtelConfig' @{MetricsOtelProcessors = $script:MetricsOtelProcessors} 'Adding metrics processors to OTEL config' @($MetricsFunctionsScript)
# Add metrics exporter to OTEL config
Invoke-Task 'Add-MetricsExporterToOtelConfig' @{MetricsToken = $script:MetricsToken; ListenerUrl = $script:ListenerUrl} 'Adding metrics exporter to OTEL config' @($MetricsFunctionsScript)
# Set metrics address to OTEL config
Invoke-Task 'Set-MetricsAddressToOTELConfig' @{} 'Setting metrics address to OTEL config' @($MetricsFunctionsScript)

# Finished successfully
Exit 0
