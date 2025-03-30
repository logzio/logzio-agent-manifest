#################################################################################################################################
################################################### WINDOWS Logs Functions ######################################################
#################################################################################################################################

# Gets Logz.io logs token
# Input:
#   ---
# Output:
#   LogsToken - Logz.io logs token
function Get-LogzioLogsToken {
    $local:ExitCode = 1
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting Logz.io logs token ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Get-JsonFileFieldValue $script:AgentJson '.shippingTokens.LOG_ANALYTICS'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    
    $local:ShippingToken = $script:JsonValue

    $Message = "Logz.io logs token is '$ShippingToken'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogsToken = '$ShippingToken'"
}

# Gets log sources
# Input:
#   FuncArgs - Hashtable {LogsParams = $script:LogsParams}
# Output:
#   LogSources - List of log sources
function Get-LogSources {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting log sources ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('LogsParams')
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsParams = $FuncArgs.LogsParams

    $Err = Get-ParamValueList $LogsParams 'logSources'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogSources = $script:ParamValue
    
    $local:Message = "Log sources are '$LogSources'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $LogSourcesStr = Convert-ListToStr $LogSources
    Write-TaskPostRun "`$script:LogSources = $LogSourcesStr"
}

# Gets if application log option was selected
# Input:
#   FuncArgs - Hashtable {LogsParams = $script:LogsParams}
# Output:
#   IsApplicationLog - Tells if application log option was selected (true/false)
function Get-IsApplicationLogSelected {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting if application log option was selected ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('LogsParams')
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsParams = $FuncArgs.LogsParams

    $Err = Get-ParamValue $LogsParams 'isApplicationLog'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:IsApplicationLog = $script:ParamValue
    if ($IsApplicationLog.Equals('true')) {
        $Message = "Application log option was selected"
    }
    else {
        $Message = "Application log option was not selected"
    }
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:IsApplicationLog = `$$IsApplicationLog"
}

# Gets if security log option was selected
# Input:
#   FuncArgs - Hashtable {LogsParams = $script:LogsParams}
# Output:
#   IsSecurityLog - Tells if security logs option was selected (true/false)
function Get-IsSecurityLogSelected {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 4
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting if security log option was selected ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('LogsParams')
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsParams = $FuncArgs.LogsParams

    $Err = Get-ParamValue $LogsParams 'isSecurityLog'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:IsSecurityLog = $script:ParamValue
    if ($IsSecurityLog.Equals('true')) {
        $Message = 'Security log option was selected'
    }
    else {
        $Message = 'Security log option was not selected'
    }
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:IsSecurityLog = `$$IsSecurityLog"
}

# Gets if system log option was selected
# Input:
#   FuncArgs - Hashtable {LogsParams = $script:LogsParams}
# Output:
#   IsSystemLog - Tells if security logs option was selected (true/false)
function Get-IsSystemLogSelected {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 5
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting if system log option was selected ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('LogsParams')
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsParams = $FuncArgs.LogsParams

    $Err = Get-ParamValue $LogsParams 'isSystemLog'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:IsSystemLog = $script:ParamValue
    if ($IsSystemLog.Equals('true')) {
        $Message = 'System log option was selected'
    }
    else {
        $Message = 'System log option was not selected'
    }
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:IsSystemLog = `$$IsSystemLog"
}

# Adds logs pipeline to OTEL confing
# Input:
#   ---
# Output:
#   ---
function Add-LogsPiplineToOtelConfig {
    $local:ExitCode = 6
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding logs pipeline to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelResourcesDir\logs_pipeline.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '' '.service.pipelines'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Gets logs OTEL receivers
# Input:
#   FuncArgs - Hashtable {LogsTelemetry = $script:LogsTelemetry}
# Ouput:
#   LogsOtelReceivers - List of Logs OTEL receiver names
function Get-LogsOtelReceivers {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 7
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting logs OTEL receivers ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('LogsTelemetry')
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsTelemetry = $FuncArgs.LogsTelemetry

    $Err = Get-JsonStrFieldValueList $LogsTelemetry '.otel.receivers[]'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsOtelReceivers = $script:JsonValue

    $Message = "Logs OTEL receivers are '$LogsOtelReceivers'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $LogLevelDebug $Message

    $local:LogsOtelReceiversStr = Convert-ListToStr $LogsOtelReceivers
    Write-TaskPostRun "`$script:LogsOtelReceivers = $LogsOtelReceiversStr"
}

# Adds logs receivers to OTEL config
# Input:
#   FuncArgs - Hashtable {LogsOtelReceivers = $script:LogsOtelReceivers; LogSources = $script:LogSources; IsApplicationLog = $script:IsApplicationLog;
#                        IsSecurityLog = $script:IsSecurityLog; IsSystemLog = $script:IsSystemLog}
# Output:
#   ---
function Add-LogsReceiversToOtelConfig {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 8
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding logs receivers to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('LogsOtelReceivers', 'LogSources', 'IsApplicationLog', 'IsSecurityLog', 'IsSystemLog')
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsOtelReceivers = $FuncArgs.LogsOtelReceivers
    $local:LogSources = $FuncArgs.LogSources
    $local:IsApplicationLog = $FuncArgs.IsApplicationLog
    $local:IsSecurityLog = $FuncArgs.IsSecurityLog
    $local:IsSystemLog = $FuncArgs.IsSystemLog

    foreach ($LogsOtelReceiver in $LogsOtelReceivers) {
        $Err = Get-YamlFileFieldValue "$script:OtelReceiversDir\$LogsOtelReceiver.yaml" '.windows_run'
        if ($Err.Count -ne 0) {
            $Message = "logs.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
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
            $Message = "logs.ps1 ($ExitCode): error loading '$LogsOtelReceiver' OTEL function script: $_"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""
    
            return $ExitCode
        }

        $Err = New-OtelReceiver @{LogSources = $LogSources; IsApplicationLog = $IsApplicationLog; IsSecurityLog = $IsSecurityLog; IsSystemLog = $IsSystemLog; LogsType = 'agent-windows'}
        if ($Err.Count -ne 0 -and $Err[1] -ne 1) {
            $Message = "logs.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }
        if ($Err.Count -ne 0) {
            $Message = $Err[0]
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-Log $script:LogLevelDebug $Message

            continue
        }

        $Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelReceiversDir\$LogsOtelReceiver.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '.receiver' '.receivers'
        if ($Err.Count -ne 0) {
            $Message = "logs.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        $local:ReceiverName = $LogsOtelReceiver.Replace('_', '/')

        $Err = Add-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.service.pipelines.logs.receivers' "$ReceiverName/NAME"
        if ($Err.Count -ne 0) {
            $Message = "logs.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }
    }

    (Get-Content -Path "$script:OtelResourcesDir\$script:OtelConfigName").Replace('NAME', "$($script:Platform.ToLower())_$($script:SubType.ToLower())_$($script:CurrentDataSource.ToLower())") | Set-Content -Path "$script:OtelResourcesDir\$script:OtelConfigName"
}

# Gets logs OTEL processors
# Input:
#   FuncArgs - Hashtable {LogsTelemetry = $script:LogsTelemetry}
# Ouput:
#   LogsOtelProcessors - List of logs OTEL processor names
function Get-LogsOtelProcessors {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 9
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting logs OTEL processors ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('LogsTelemetry')
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsTelemetry = $FuncArgs.LogsTelemetry

    $Err = Get-JsonStrFieldValueList $LogsTelemetry '.otel.processors[]'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsOtelProcessors = $script:JsonValue

    $Message = "Logs OTEL processors are '$LogsOtelProcessors'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:LogsOtelProcessorssStr = Convert-ListToStr $LogsOtelProcessors
    Write-TaskPostRun "`$script:LogsOtelProcessors = $LogsOtelProcessorssStr"
}

# Adds logs processors to OTEL config
# Input:
#   FuncArgs - Hashtable {LogsOtelProcessors = $script:LogsOtelProcessors}
# Output:
#   ---
function Add-LogsProcessorsToOtelConfig {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 10
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding logs processors to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('LogsOtelProcessors')
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsOtelProcessors = $FuncArgs.LogsOtelProcessors

    $local:ExistProcessors = $null
    $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.processors'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        $ExistProcessors = @()
    }

    if ($null -eq $ExistProcessors) {
        $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.processors | keys'
        if ($Err.Count -ne 0) {
            $Message = "logs.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        $ExistProcessors = $script:YamlValue
    }

    foreach ($LogsOtelProcessor in $LogsOtelProcessors) {
        $local:ProcessorName = $LogsOtelProcessor.Replace('_', '/')

        $Err = Add-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.service.pipelines.logs.processors' $ProcessorName
        if ($Err.Count -ne 0) {
            $Message = "logs.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        $local:IsProcessorExist = $false

        foreach ($ExistProcessor in $ExistProcessors) {
            $ExistProcessor = $ExistProcessor.Replace('/', '_')

            if ($LogsOtelProcessor.Equals("- $ExistProcessor")) {
                $IsProcessorExist = $true
                break
            }
        }

        if ($IsProcessorExist) {
            continue
        }

        $Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelProcessorsDir\$LogsOtelProcessor.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '' '.processors'
        if ($Err.Count -ne 0) {
            $Message = "logs.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        if ($ProcessorName -eq 'resource/agent') {
            $local:AgentVersion = Get-Content "$env:TEMP\Logzio\version"
            $Err = Add-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.processors.resource/agent.attributes[0].value' $AgentVersion
        }
    }
}

# Adds logs exporter to OTEL config
# Input:
#   FuncArgs - Hashtable {LogsToken = $script:LogsToken; ListenerUrl = $script:ListenerUrl}
# Output:
#   ---
function Add-LogsExporterToOtelConfig {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 11
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding logs exporter to OTEL config ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('LogsToken', 'ListenerUrl')
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsToken = $FuncArgs.LogsToken
    $local:ListenerUrl = $FuncArgs.ListenerUrl

    $local:ExistExporters = $null
    $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.exporters'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        $ExistExporters = @()
    }

    if ($null -eq $ExistExporers) {
        $Err = Get-YamlFileFieldValue "$script:OtelResourcesDir\$script:OtelConfigName" '.exporters | keys'
        if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
            $Message = "logs.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        $ExistExporters = $script:YamlValue
    }

    foreach ($ExistExporter in $ExistExporers) {
        if ($ExistExporter.Equals('- logzio/logs')) {
            return
        }
    }

    $Err = Set-YamlFileFieldValue "$script:OtelExportersDir\logzio_logs.yaml" '.logzio/logs.account_token' $LogsToken
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0]))"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $Err = Set-YamlFileFieldValue "$script:OtelExportersDir\logzio_logs.yaml" '.logzio/logs.headers.user-agent' $script:UserAgentLogs
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0]))"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""
        return $ExitCode
    }

    $local:LogzioRegion = Get-LogzioRegion $ListenerUrl
    
    $Message = "Logz.io region is '$LogzioRegion'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $Err = Set-YamlFileFieldValue "$script:OtelExportersDir\logzio_logs.yaml" '.logzio/logs.region' $LogzioRegion
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0]))"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $Err = Add-YamlFileFieldValueToAnotherYamlFileField "$script:OtelExportersDir\logzio_logs.yaml" "$script:OtelResourcesDir\$script:OtelConfigName" '' '.exporters'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0]))"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:SubType $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}
