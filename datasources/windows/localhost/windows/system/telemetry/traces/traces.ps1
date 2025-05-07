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
# Configure span metrics connector
Invoke-Task 'Set-SpanMetricsConnector' @{} 'Configuring span metrics connector' @($TracesFunctionsScript)
# Add traces exporter to OTEL config
Invoke-Task 'Add-TracesExporterToOtelConfig' @{TracesToken = $script:TracesToken; ListenerUrl = $script:ListenerUrl} 'Adding traces exporter to OTEL config' @($TracesFunctionsScript)
# Add span metrics exporter
Invoke-Task 'Add-SpanMetricsExporter' @{MetricsToken = $script:MetricsToken; ListenerUrl = $script:ListenerUrl} 'Adding span metrics exporter to OTEL config' @($TracesFunctionsScript)

# Finished successfully
Exit 0