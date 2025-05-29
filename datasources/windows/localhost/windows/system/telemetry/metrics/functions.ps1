#################################################################################################################################
################################################## WINDOWS Metrics Functions ####################################################
#################################################################################################################################

# Gets Logz.io metrics token
# Input:
#   ---
# Output:
#   MetricsToken - Logz.io metrics token
function Get-LogzioMetricsToken {
    $local:ExitCode = 1
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting Logz.io metrics token ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Get-JsonFileFieldValue $script:AgentJson '.shippingTokens.METRICS'
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    
    $local:ShippingToken = $script:JsonValue

    $Message = "Logz.io metrics token is '$ShippingToken'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:MetricsToken = '$ShippingToken'"
}

# Adds metrics pipeline to OTEL confing
# Input:
#   ---
# Output:
#   ---
function Add-MetricsPiplineToOtelConfig {
    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding metrics pipeline to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelResourcesDir\metrics_pipeline.yaml" "$script:OtelResourcesDir\otel_config.yaml" '' '.service.pipelines'
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Gets metrics OTEL receivers
# Input:
#   FuncArgs - Hashtable {MetricsTelemetry = $script:MetricsTelemetry}
# Ouput:
#   MetricsOtelReceivers - List of Metrics OTEL receiver names
function Get-MetricsOtelReceivers {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting metrics OTEL receivers ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('MetricsTelemetry')
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $Lscript:ogScriptMetrics $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:MetricsTelemetry = $FuncArgs.MetricsTelemetry

    $Err = Get-JsonStrFieldValueList $MetricsTelemetry '.otel.receivers[]'
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $Lscript:ogScriptMetrics $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:MetricsOtelReceivers = $script:JsonValue

    $Message = "Metrics OTEL receivers are '$MetricsOtelReceivers'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:MetricsOtelReceiversStr = Convert-ListToStr $MetricsOtelReceivers
    Write-TaskPostRun "`$script:MetricsOtelReceivers = $MetricsOtelReceiversStr"
}

# Adds metrics receivers to OTEL config
# Input:
#   FuncArgs - Hashtable {MetricsOtelReceivers = $script:MetricsOtelReceivers}
# Output:
#   ---
function Add-MetricsReceiversToOtelConfig {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 4
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding metrics receivers to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('MetricsOtelReceivers')
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $Lscript:ogScriptMetrics $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:MetricsOtelReceivers = $FuncArgs.MetricsOtelReceivers

    foreach ($MetricsOtelReceiver in $MetricsOtelReceivers) {
        $Err = Get-YamlFileFieldValue "$script:OtelReceiversDir\$MetricsOtelReceiver.yaml" '.windows_run'
        if ($Err.Count -ne 0) {
            $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $Lscript:ogScriptMetrics $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
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
            $Message = "metrics.ps1 ($ExitCode): error loading '$MetricsOtelReceiver' OTEL function script: $_"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $Lscript:ogScriptMetrics $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""
    
            return $ExitCode
        }

        $Err = New-OtelReceiver @{}
        if ($Err.Count -ne 0 -and $Err[1] -ne 1) {
            $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $Lscript:ogScriptMetrics $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }
        if ($Err.Count -ne 0) {
            $Message = $Err[0]
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-Log $script:LogLevelDebug $Message

            continue
        }

        $Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelReceiversDir\$MetricsOtelReceiver.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '.receiver' '.receivers'
        if ($Err.Count -ne 0) {
            $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        $local:ReceiverName = $MetricsOtelReceiver.Replace('_', '/')
        
        if ($ReceiverName -eq 'otlp') {
            $Err = Add-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.service.pipelines.metrics.receivers' "$ReceiverName"
            if ($Err.Count -ne 0) {
                $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
                Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
                Write-TaskPostRun "Write-Error `"$Message`""

                return $ExitCode
            }
            continue
        }

        $Err = Add-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.service.pipelines.metrics.receivers' "$ReceiverName/NAME"
        if ($Err.Count -ne 0) {
            $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }
    }

    (Get-Content -Path "$script:OtelResourcesDir\$script:OtelConfigName").Replace('NAME', "$($script:Platform.ToLower())_$($script:SubType.ToLower())_$($script:CurrentDataSource.ToLower())") | Set-Content -Path "$script:OtelResourcesDir\$script:OtelConfigName"
}

# Gets metrics OTEL processors
# Input:
#   FuncArgs - Hashtable {MetricsTelemetry = $script:MetricsTelemetry}
# Ouput:
#   MetricsOtelProcessors - List of metrics OTEL processor names
function Get-MetricsOtelProcessors {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 5
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting metrics OTEL processors ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('MetricsTelemetry')
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:MetricsTelemetry = $FuncArgs.MetricsTelemetry

    $Err = Get-JsonStrFieldValueList $MetricsTelemetry '.otel.processors[]'
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:MetricsOtelProcessors = $script:JsonValue

    $Message = "Metrics OTEL processors are '$MetricsOtelProcessors'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:MetricsOtelProcessorssStr = Convert-ListToStr $MetricsOtelProcessors
    Write-TaskPostRun "`$script:MetricsOtelProcessors = $MetricsOtelProcessorssStr"
}

# Adds metrics processors to OTEL config
# Input:
#   FuncArgs - Hashtable {MetricsOtelProcessors = $script:MetricsOtelProcessors}
# Output:
#   ---
function Add-MetricsProcessorsToOtelConfig {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 6
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding metrics processors to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('MetricsOtelProcessors')
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:MetricsOtelProcessors = $FuncArgs.MetricsOtelProcessors

    $local:ExistProcessors = $null
    $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.processors'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        $ExistProcessors = @()
    }

    if ($null -eq $ExistProcessors) {
        $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.processors | keys'
        if ($Err.Count -ne 0) {
            $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        $ExistProcessors = $script:YamlValue
    }

    foreach ($MetricsOtelProcessor in $MetricsOtelProcessors) {
        $local:ProcessorName = $MetricsOtelProcessor.Replace('_', '/')

        $Err = Add-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.service.pipelines.metrics.processors' $ProcessorName
        if ($Err.Count -ne 0) {
            $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        $local:IsProcessorExist = $false

        foreach ($ExistProcessor in $ExistProcessors) {
            $ExistProcessor = $ExistProcessor.Replace('/', '_')

            if ($MetricsOtelProcessor.Equals("- $ExistProcessor")) {
                $IsProcessorExist = $true
                break
            }
        }

        if ($IsProcessorExist) {
            continue
        }

        $Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelProcessorsDir\$MetricsOtelProcessor.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '' '.processors'
        if ($Err.Count -ne 0) {
            $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }
        
        if ($ProcessorName -eq 'resource/agent') {
            $local:AgentVersion = Get-Content "$env:TEMP\Logzio\version"
            $Err = Add-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.processors.resource/agent.attributes[0].value' $AgentVersion
        }
    }
}

# Adds metrics exporter to OTEL config
# Input:
#   FuncArgs - Hashtable {MetricsToken = $script:MetricsToken; ListenerUrl = $script:ListenerUrl}
# Output:
#   ---
function Add-MetricsExporterToOtelConfig {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 7
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding metrics exporter to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('MetricsToken', 'ListenerUrl')
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:MetricsToken = $FuncArgs.MetricsToken
    $local:ListenerUrl = $FuncArgs.ListenerUrl

    $local:ExistExporters = $null
    $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.exporters'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        $ExistExporters = @()
    }

    if ($null -eq $ExistExporters) {
        $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.exporters | keys'
        if ($Err.Count -ne 0) {
            $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
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
        $local:Endpoint = "$ListenerUrl`:8053"
        
        $Message = "Prometheus Remote Write endpoint set to '$Endpoint'"
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-Log $script:LogLevelDebug $Message
        
        $Err = Set-YamlFileFieldValue "$script:OtelExportersDir\prometheusremotewrite.yaml" '.prometheusremotewrite.endpoint' $Endpoint
        if ($Err.Count -ne 0) {
            $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        $local:AuthHeader = "Bearer $MetricsToken"
        $Err = Set-YamlFileFieldValue "$script:OtelExportersDir\prometheusremotewrite.yaml" '.prometheusremotewrite.headers.Authorization' $AuthHeader
        if ($Err.Count -ne 0) {
            $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        $Err = Set-YamlFileFieldValue "$script:OtelExportersDir\prometheusremotewrite.yaml" '.prometheusremotewrite.headers.user-agent' $script:UserAgentMetrics
        if ($Err.Count -ne 0) {
            $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""
            return $ExitCode
        }

        $Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelExportersDir\prometheusremotewrite.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '' '.exporters'
        if ($Err.Count -ne 0) {
            $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }
    }
}

# Sets metrics address to OTEL config
# Input:
#   ---
# Output:
#   ---
function Set-MetricsAddressToOTELConfig {
    $local:ExitCode = 8
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Setting metrics address to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Port = 8888
    $local:Result = netstat -vanp TCP | Select-String -Pattern LISTENING | Select-String -Pattern 127.0.0.1:$Port
    if (-Not [string]::IsNullOrEmpty($Result)) {
        while ($true) {
            $Port++
            $Result = netstat -vanp TCP | Select-String -Pattern LISTENING | Select-String -Pattern 127.0.0.1:$Port

            if ([string]::IsNullOrEmpty($Result)) {
                break
            }
        }
    }

    $local:Address = "localhost:$Port"

    $Err = Set-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.service.telemetry.metrics.address' $Address
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0]))"
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}
