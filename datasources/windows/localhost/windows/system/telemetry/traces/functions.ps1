#################################################################################################################################
################################################## WINDOWS Traces Functions ####################################################
#################################################################################################################################

# Gets Logz.io traces token
# Input:
#   ---
# Output:
#   TracesToken - Logz.io traces token
function Get-LogzioTracesToken {
    $local:ExitCode = 1
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting Logz.io traces token ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Get-JsonFileFieldValue $script:AgentJson '.shippingTokens.TRACING'
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    
    $local:ShippingToken = $script:JsonValue

    $Message = "Logz.io traces token is '$ShippingToken'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:TracesToken = '$ShippingToken'"
}

# Adds traces pipeline to OTEL config
# Input:
#   ---
# Output:
#   ---
function Add-TracesPipelineToOtelConfig {
    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding traces pipeline to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelResourcesDir\traces_pipeline.yaml" "$script:OtelResourcesDir\otel_config.yaml" '' '.service.pipelines'
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $Message = 'Added traces pipeline to OTEL config'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message
}

# Gets traces OTEL receivers
# Input:
#   FuncArgs - Hashtable {TracesTelemetry = $script:TracesTelemetry}
# Ouput:
#   TracesOtelReceivers - List of Traces OTEL receiver names
function Get-TracesOtelReceivers {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting traces OTEL receivers ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('TracesTelemetry')
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    # OTLP receiver is always used for traces
    $local:TracesOtelReceivers = @("otlp")

    $Message = "Traces OTEL receivers are '$TracesOtelReceivers'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:TracesOtelReceiversStr = Convert-ListToStr $TracesOtelReceivers
    Write-TaskPostRun "`$script:TracesOtelReceivers = $TracesOtelReceiversStr"
}

# Adds traces receivers to OTEL config
# Input:
#   FuncArgs - Hashtable {TracesOtelReceivers = $script:TracesOtelReceivers}
# Output:
#   ---
function Add-TracesReceiversToOtelConfig {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 4
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding traces receivers to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('TracesOtelReceivers')
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:TracesOtelReceivers = $FuncArgs.TracesOtelReceivers

    # Add receivers section if not exists
    $local:ExistReceivers = $null
    $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.receivers'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        # Add receivers section if not exists
        Add-Content -Path "$script:OtelResourcesDir\$script:OtelConfigName" -Value "receivers:"
    }

    # Add OTLP receiver if not exists
    $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.receivers.otlp'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        Add-Content -Path "$script:OtelResourcesDir\$script:OtelConfigName" -Value @"
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
"@
    }

    # Update service.pipelines.traces.receivers with the receivers list
    $local:ReceiversList = $TracesOtelReceivers -join ','
    $ReceiversList = "[$ReceiversList]"
    $Err = Set-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.service.pipelines.traces.receivers' $ReceiversList
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    # Update service.pipelines.traces/metrics.receivers with the receivers list
    $Err = Set-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.service.pipelines."traces/metrics".receivers' $ReceiversList
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $Message = 'Added traces receivers to OTEL config'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message
}

# Gets traces OTEL processors
# Input:
#   FuncArgs - Hashtable {TracesTelemetry = $script:TracesTelemetry}
# Ouput:
#   TracesOtelProcessors - List of traces OTEL processor names
function Get-TracesOtelProcessors {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 5
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting traces OTEL processors ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('TracesTelemetry')
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    # Standard processors for traces
    $local:TracesOtelProcessors = @('batch', 'resource', 'attributes')

    $Message = "Traces OTEL processors are '$TracesOtelProcessors'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:TracesOtelProcessorsStr = Convert-ListToStr $TracesOtelProcessors
    Write-TaskPostRun "`$script:TracesOtelProcessors = $TracesOtelProcessorsStr"
}

# Adds traces processors to OTEL config
# Input:
#   FuncArgs - Hashtable {TracesOtelProcessors = $script:TracesOtelProcessors}
# Output:
#   ---
function Add-TracesProcessorsToOtelConfig {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 6
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding traces processors to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('TracesOtelProcessors')
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:TracesOtelProcessors = $FuncArgs.TracesOtelProcessors

    $local:ExistProcessors = $null
    $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.processors'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        # Add processors section if not exists
        Add-Content -Path "$script:OtelResourcesDir\$script:OtelConfigName" -Value "processors:"
    }

    # Add batch processor if not exists
    $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.processors.batch'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        Add-Content -Path "$script:OtelResourcesDir\$script:OtelConfigName" -Value @"
  batch:
    send_batch_size: 10000
    timeout: 1s
"@
    }

    # Add resource processor if not exists
    $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.processors.resource'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        Add-Content -Path "$script:OtelResourcesDir\$script:OtelConfigName" -Value @"
  resource:
    attributes:
      - key: service.name
        value: ${env:COMPUTERNAME}
      - key: service.version
        value: 1.0.0
"@
    }

    # Add attributes processor if not exists
    $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.processors.attributes'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        Add-Content -Path "$script:OtelResourcesDir\$script:OtelConfigName" -Value @"
  attributes:
    actions:
      - key: environment
        value: production
        action: insert
"@
    }

    # Update service.pipelines.traces.processors with the processors list
    $local:ProcessorsList = $TracesOtelProcessors -join ','
    $ProcessorsList = "[$ProcessorsList]"
    $Err = Set-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.service.pipelines.traces.processors' $ProcessorsList
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $Message = 'Added traces processors to OTEL config'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message
}

# Configures the span metrics connector
# Input:
#   ---
# Output:
#   ---
function Set-SpanMetricsConnector {
    $local:ExitCode = 7
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Configuring span metrics connector ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    # Add spanmetrics processor if not exists
    $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.processors.spanmetrics'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        Add-Content -Path "$script:OtelResourcesDir\$script:OtelConfigName" -Value @"
  spanmetrics:
    metrics_exporter: prometheusremotewrite
    dimensions:
      - name: service.name
      - name: operation
        default: unknown-operation
    dimensions_cache_size: 1000
    aggregation_temporality: AGGREGATION_TEMPORALITY_CUMULATIVE
"@
    }

    # Update service.pipelines.traces/metrics.processors with spanmetrics
    $Err = Set-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.service.pipelines."traces/metrics".processors' "[batch,spanmetrics]"
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $Message = 'Configured span metrics connector'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message
}

# Adds traces exporter to OTEL config
# Input:
#   FuncArgs - Hashtable {TracesToken = $script:TracesToken; ListenerUrl = $script:ListenerUrl}
# Output:
#   ---
function Add-TracesExporterToOtelConfig {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 8
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding traces exporter to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('TracesToken', 'ListenerUrl')
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:TracesToken = $FuncArgs.TracesToken
    $local:ListenerUrl = $FuncArgs.ListenerUrl

    $local:ExistExporters = $null
    $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.exporters'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        Add-Content -Path "$script:OtelResourcesDir\$script:OtelConfigName" -Value "exporters:"
    }

    # Add Logz.io traces exporter if not exists
    $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.exporters.logzio_traces'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    if ($Err.Count -ne 0) {
        $local:LogzioRegion = Get-LogzioRegion $ListenerUrl
        
        Add-Content -Path "$script:OtelResourcesDir\$script:OtelConfigName" -Value @"
  logzio_traces:
    account_token: ${TracesToken}
    region: ${LogzioRegion}
"@
    }

    # Update service.pipelines.traces.exporters with logzio_traces
    $Err = Set-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.service.pipelines.traces.exporters' "[logzio_traces]"
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $Message = 'Added traces exporter to OTEL config'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message
}

# Adds span metrics exporter to OTEL config
# Input:
#   FuncArgs - Hashtable {MetricsToken = $script:MetricsToken; ListenerUrl = $script:ListenerUrl}
# Output:
#   ---
function Add-SpanMetricsExporter {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 9
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding span metrics exporter to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('MetricsToken', 'ListenerUrl')
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:MetricsToken = $FuncArgs.MetricsToken
    $local:ListenerUrl = $FuncArgs.ListenerUrl

    # Add Prometheus Remote Write exporter if not exists
    $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.exporters.prometheusremotewrite'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        Add-Content -Path "$script:OtelResourcesDir\$script:OtelConfigName" -Value @"
  prometheusremotewrite:
    endpoint: https://$ListenerUrl:8053
    headers:
      Authorization: Bearer ${MetricsToken}
    resource_to_telemetry_conversion:
      enabled: true
"@
    }

    # Update service.pipelines.traces/metrics.exporters with prometheusremotewrite
    $Err = Set-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.service.pipelines."traces/metrics".exporters' "[prometheusremotewrite]"
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $Message = 'Added span metrics exporter to OTEL config'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message
}