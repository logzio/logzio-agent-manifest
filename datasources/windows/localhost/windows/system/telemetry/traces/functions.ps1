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

    $local:TracesTelemetry = $FuncArgs.TracesTelemetry

    $Err = Get-JsonStrFieldValueList $TracesTelemetry '.otel.receivers[]'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:TracesLogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:TracesOtelReceivers = $script:JsonValue

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

    foreach ($TracesOtelReceiver in $TracesOtelReceivers) {
      $Err = Get-YamlFileFieldValue "$script:OtelReceiversDir\$TracesOtelReceiver.yaml" '.windows_run'
      if ($Err.Count -ne 0) {
          $Message = "traces.ps1 ($ExitCode): $($Err[0])"
          Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
          Write-TaskPostRun "Write-Error `"$Message`""
  
          return $ExitCode
      }

      $local:ScriptBlock = $script:YamlValue

      $ScriptBlock | Out-File -FilePath $script:OtelFunctionFile -Encoding utf8
      try {
          . $script:OtelFunctionFile -ErrorAction Stop
          if ($LASTEXITCODE -ne 0) {
              return $ExitCode
          }
      }
      catch {
          $Message = "traces.ps1 ($ExitCode): error loading '$TracesOtelReceiver' OTEL function script: $_"
          Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
          Write-TaskPostRun "Write-Error `"$Message`""
  
          return $ExitCode
      }

      $Err = New-OtelReceiver @{LogSources = $LogSources; IsApplicationLog = $IsApplicationLog; IsSecurityLog = $IsSecurityLog; IsSystemLog = $IsSystemLog; LogsType = 'agent-windows'}
      if ($Err.Count -ne 0 -and $Err[1] -ne 1) {
          $Message = "traces.ps1 ($ExitCode): $($Err[0])"
          Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
          Write-TaskPostRun "Write-Error `"$Message`""

          return $ExitCode
      }
      if ($Err.Count -ne 0) {
          $Message = $Err[0]
          Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
          Write-Log $script:LogLevelDebug $Message

          continue
      }

      $Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelReceiversDir\$TracesOtelReceiver.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '.receiver' '.receivers'
      if ($Err.Count -ne 0) {
          $Message = "traces.ps1 ($ExitCode): $($Err[0])"
          Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
          Write-TaskPostRun "Write-Error `"$Message`""

          return $ExitCode
      }

      $local:ReceiverName = $TracesOtelReceiver.Replace('_', '/')

      $Err = Add-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.service.pipelines.traces.receivers' "$ReceiverName/NAME"
      if ($Err.Count -ne 0) {
          $Message = "traces.ps1 ($ExitCode): $($Err[0])"
          Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
          Write-TaskPostRun "Write-Error `"$Message`""

          return $ExitCode
      }
  }
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

    $local:TracesTelemetry = $FuncArgs.TracesTelemetry

    $Err = Get-JsonStrFieldValueList $TracesTelemetry '.otel.processors[]'
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsOtelProcessors = $script:JsonValue

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
        $ExistProcessors = @()
    }
    if ($null -eq $ExistProcessors) {
      $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.processors | keys'
      if ($Err.Count -ne 0) {
          $Message = "traces.ps1 ($ExitCode): $($Err[0])"
          Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
          Write-TaskPostRun "Write-Error `"$Message`""

          return $ExitCode
      }

      $ExistProcessors = $script:YamlValue
  }

  foreach ($TracesOtelProcessor in $TracesOtelProcessors)     {
    $local:ProcessorName = $TracesOtelProcessor.Replace('_', '/')

    $Err = Add-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.service.pipelines.traces.processors' $ProcessorName
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:TracesLogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:IsProcessorExist = $false

    foreach ($ExistProcessor in $ExistProcessors) {
        $ExistProcessor = $ExistProcessor.Replace('/', '_')

        if ($TracesOtelProcessor.Equals("- $ExistProcessor")) {
            $IsProcessorExist = $true
            break
        }
    }

    if ($IsProcessorExist) {
        continue
    }

    $Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelProcessorsDir\$TracesOtelProcessor.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '' '.processors'
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:TracesLogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    if ($ProcessorName -eq 'resource/agent') {
        $local:AgentVersion = Get-Content "$env:TEMP\Logzio\version"
        $Err = Add-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.processors.resource/agent.attributes[0].value' $AgentVersion
    }
  }
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

    $Err = Set-YamlFileFieldValue "$script:OtelExportersDir\logzio_traces.yaml" '.logzio/traces.account_token' $LogsToken
    if ($Err.Count -ne 0) {
      $Message = "traces.ps1 ($ExitCode): $($Err[0])"
      Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
      Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $Err = Set-YamlFileFieldValue "$script:OtelExportersDir\logzio_traces.yaml" '.logzio/traces.headers.user-agent' $script:UserAgentTraces
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""
        return $ExitCode
    }

    $local:LogzioRegion = Get-LogzioRegion $ListenerUrl
    
    $Message = "Logz.io region is '$LogzioRegion'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $Err = Set-YamlFileFieldValue "$script:OtelExportersDir\logzio_traces.yaml" '.logzio/traces.region' $LogzioRegion
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelExportersDir\logzio_traces.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '' '.exporters'
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

}
# Gets Logz.io metrics token for span metrics
# Input:
#   ---
# Output:
#   MetricsToken - Logz.io metrics token
function Get-LogzioMetricsToken {
  $local:ExitCode = 10
  $local:FuncName = $MyInvocation.MyCommand.Name

  $local:Message = 'Getting Logz.io metrics token for span metrics ...'
  Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
  Write-Log $script:LogLevelDebug $Message

  $local:Err = Get-JsonFileFieldValue $script:AgentJson '.shippingTokens.METRICS'
  if ($Err.Count -ne 0) {
      $Message = "traces.ps1 ($ExitCode): $($Err[0])"
      Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
      Write-TaskPostRun "Write-Error `"$Message`""

      return $ExitCode
  }
  
  $local:ShippingToken = $script:JsonValue

  $Message = "Logz.io metrics token for span metrics is '$ShippingToken'"
  Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
  Write-Log $script:LogLevelDebug $Message

  Write-TaskPostRun "`$script:MetricsToken = '$ShippingToken'"
}

# Adds spanmetrics pipeline to OTEL confing
# Input:
#   ---
# Output:
#   ---
function Add-SpanMetircsPipelineToOtelConfig {
    $local:ExitCode = 11
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding span metrics pipeline to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    # Add traces/spanmetrics pipeline
    $local:Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelResourcesDir\spanmetricstraces_pipeline.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '' '.service.pipelines'
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    # Add metrics/spanmetrics pipeline
    $Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelResourcesDir\spanmetrics_pipeline.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '' '.service.pipelines'
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Adds spanmetrics connector to OTEL config
# Input:
#   ---
# Output:
#   ---
function Add-SpanMetricsConnectorToOtelConfig {
    $local:ExitCode = 12
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding span metrics connector to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelResourcesDir\connectors\spanmetrics.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '' '.connectors'
    if ($Err.Count -ne 0) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Adds spanmetrics processors to OTEL config
# Input:
#   ---
# Output:
#   ---
function Add-SpanMetricsProcessorsToOtelConfig {
    $local:ExitCode = 13
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding span metrics processors to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:ExistProcessors = $null
    $local:Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.processors'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        $ExistProcessors = @()
    }
    if ($null -eq $ExistProcessors) {
        $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.processors | keys'
        if ($Err.Count -ne 0) {
            $Message = "traces.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        $ExistProcessors = $script:YamlValue
    }

    # Add batch processor
    $local:IsProcessorExist = $false
    foreach ($ExistProcessor in $ExistProcessors) {
        if ($ExistProcessor -eq 'batch') {
            $IsProcessorExist = $true
            break
        }
    }

    if (-not $IsProcessorExist) {
        $Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelProcessorsDir\batch.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '' '.processors'
        if ($Err.Count -ne 0) {
            $Message = "traces.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }
    }

    # Add metricstransform/metrics-rename processor
    $IsProcessorExist = $false
    foreach ($ExistProcessor in $ExistProcessors) {
        if ($ExistProcessor -eq 'metricstransform/metrics-rename') {
            $IsProcessorExist = $true
            break
        }
    }

    if (-not $IsProcessorExist) {
        $Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelProcessorsDir\metricstransform_metrics-rename.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '' '.processors'
        if ($Err.Count -ne 0) {
            $Message = "traces.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }
    }

    # Add metricstransform/labels-rename processor
    $IsProcessorExist = $false
    foreach ($ExistProcessor in $ExistProcessors) {
        if ($ExistProcessor -eq 'metricstransform/labels-rename') {
            $IsProcessorExist = $true
            break
        }
    }

    if (-not $IsProcessorExist) {
        $Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelProcessorsDir\metricstransform_labels-rename.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '' '.processors'
        if ($Err.Count -ne 0) {
            $Message = "traces.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }
    }
}

# Adds spanmetrics exporter to OTEL config
# Input:
#   FuncArgs - Hashtable {MetricsToken = $script:MetricsToken; ListenerUrl = $script:ListenerUrl}
# Output:
#   ---
function Add-SpanMetricsExporterToOtelConfig {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 14
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

    # Check if prometheusremotewrite exporter already exists
    $local:ExistExporters = $null
    $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.exporters'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "traces.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        $ExistExporters = @()
    }

    if ($null -eq $ExistExporters) {
        $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.exporters | keys'
        if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
            $Message = "traces.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        $ExistExporters = $script:YamlValue
    }

    $local:IsExporterExist = $false
    foreach ($ExistExporter in $ExistExporters) {
        if ($ExistExporter -eq 'prometheusremotewrite') {
            $IsExporterExist = $true
            break
        }
    }

    if (-not $IsExporterExist) {
        # Configure Prometheusremotewrite exporter
        $local:ListenerHost = ($ListenerUrl -replace "https?://" -replace "/.*").Trim()
        $local:Endpoint = "https://$ListenerHost:8053"
        
        $Err = Set-YamlFileFieldValue "$script:OtelExportersDir\prometheusremotewrite.yaml" '.prometheusremotewrite.endpoint' $Endpoint
        if ($Err.Count -ne 0) {
            $Message = "traces.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        $local:AuthHeader = "Bearer $MetricsToken"
        $Err = Set-YamlFileFieldValue "$script:OtelExportersDir\prometheusremotewrite.yaml" '.prometheusremotewrite.headers.Authorization' $AuthHeader
        if ($Err.Count -ne 0) {
            $Message = "traces.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        $Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelExportersDir\prometheusremotewrite.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '' '.exporters'
        if ($Err.Count -ne 0) {
            $Message = "traces.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepTraces $script:LogScriptTraces $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }
    }
}
