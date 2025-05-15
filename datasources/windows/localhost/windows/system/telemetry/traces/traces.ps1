#################################################################################################################################
#################################################### WINDOWS Traces Script ######################################################
#################################################################################################################################

$local:TracesFunctionsScript = "$script:LogzioTempDir\$script:Platform\$script:SubType\$($script:CurrentDataSource.ToLower())\$script:TracesFunctionsFile"

# Print headline
Write-Host
Write-Host '############'
Write-Host '### ' -NoNewline
Write-Host 'Traces' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '############'

# Get Logz.io traces token
Invoke-Task 'Get-LogzioTracesToken' @{} 'Getting Logz.io traces token' @($TracesFunctionsScript)
# Add traces pipeline to OTEL config
Invoke-Task 'Add-TracesPipelineToOtelConfig' @{} 'Adding traces pipeline to OTEL config' @($TracesFunctionsScript)
# Get traces OTEL receivers
Invoke-Task 'Get-TracesOtelReceivers' @{TracesTelemetry = $script:TracesTelemetry} 'Getting traces OTEL receivers' @($TracesFunctionsScript)
# Add traces receivers to OTEL config
Invoke-Task 'Add-TracesReceiversToOtelConfig' @{TracesOtelReceivers = $script:TracesOtelReceivers} 'Adding traces receivers to OTEL config' @($TracesFunctionsScript)
# Get traces OTEL processors
Invoke-Task 'Get-TracesOtelProcessors' @{TracesTelemetry = $script:TracesTelemetry} 'Getting traces OTEL processors' @($TracesFunctionsScript)
# Add traces processors to OTEL config
Invoke-Task 'Add-TracesProcessorsToOtelConfig' @{TracesOtelProcessors = $script:TracesOtelProcessors} 'Adding traces processors to OTEL config' @($TracesFunctionsScript)
# Add traces exporter to OTEL config
Invoke-Task 'Add-TracesExporterToOtelConfig' @{TracesToken = $script:TracesToken; ListenerUrl = $script:ListenerUrl} 'Adding traces exporter to OTEL config' @($TracesFunctionsScript)
# Print headline
Write-Host
Write-Host '############'
Write-Host '### ' -NoNewline
Write-Host 'Span Metrics' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '############'
# Get Logz.io metrics token
Invoke-Task 'Get-LogzioMetricsToken' @{} 'Getting Logz.io metrics token' @($MetricsFunctionsScript)
# Configure spanmetrics pipeline to OTEL config
Invoke-Task 'Add-SpanMetircsPipelineToOtelConfig' @{} 'Adding span metrics pipeline to OTEL config' @($TracesFunctionsScript)
# Add spanmetrics connector to OTEL config
Invoke-Task 'Add-SpanMetricsConnectorToOtelConfig' @{} 'Adding span metrics connector to OTEL config' @($TracesFunctionsScript)
# Add spanmetrics proccesors to OTEL config
Invoke-Task 'Add-SpanMetricsProcessorsToOtelConfig' @{} 'Adding span metrics processors to OTEL config' @($TracesFunctionsScript)
# Add spanmetrics exporter to OTEL config
Invoke-Task 'Add-SpanMetricsExporterToOtelConfig' @{MetricsToken = $script:MetricsToken; ListenerUrl = $script:ListenerUrl} 'Adding span metrics exporter to OTEL config' @($TracesFunctionsScript)

# Finished successfully
Exit 0