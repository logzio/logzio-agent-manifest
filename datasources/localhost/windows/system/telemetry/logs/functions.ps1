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

    $local:Message = "Getting Logz.io logs token ..."
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    $local:Err = Get-JsonFileFieldValue $AgentJson '.shippingTokens.LOG_ANALYTICS'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    
    $local:ShippingToken = $JsonValue

    $Message = "Logz.io logs token is '$ShippingToken'"
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogsToken = '$ShippingToken'"
}

# Gets log sources
# Input:
#   ---
# Output:
#   LogSources - List of log sources
function Get-LogSources {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = "Getting log sources ..."
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    if ($FuncArgs.Count -eq 0) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('LogsParams')) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument does not contain 'LogsParams' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:LogsParams = $FuncArgs.LogsParams

    $local:Err = Get-ParamValueList $LogsParams 'logSources'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:LogSources = $ParamValue
    
    $local:Message = "Log sources are '$LogSources'"
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    $LogSourcesStr = Convert-ListToStr $LogSources
    Write-TaskPostRun "`$script:LogSources = $LogSourcesStr"
}

# Gets if application log option was selected
# Input:
#   ---
# Output:
#   IsApplicationLog - Tells if application log option was selected (true/false)
function Get-IsApplicationLogSelected {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = "Getting is application log selected ..."
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    if ($FuncArgs.Count -eq 0) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('LogsParams')) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument does not contain 'LogsParams' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:LogsParams = $FuncArgs.LogsParams

    $local:Err = Get-ParamValue $LogsParams 'isApplicationLog'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:IsApplicationLog = $ParamValue
    if ($IsApplicationLog.Equals('true')) {
        $Message = "Application log option was selected"
    }
    else {
        $Message = "Application log option was not selected"
    }
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    Write-TaskPostRun "`$script:IsApplicationLog = `$$IsApplicationLog"
}

# Gets if security log option was selected
# Input:
#   ---
# Output:
#   IsSecurityLog - Tells if security logs option was selected (true/false)
function Get-IsSecurityLogSelected {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 4
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = "Getting is security log selected ..."
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    if ($FuncArgs.Count -eq 0) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('LogsParams')) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument does not contain 'LogsParams' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:LogsParams = $FuncArgs.LogsParams

    $local:Err = Get-ParamValue $LogsParams 'isSecurityLog'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:IsSecurityLog = $ParamValue
    if ($IsSecurityLog.Equals('true')) {
        $Message = "Security log option was selected"
    }
    else {
        $Message = "Security log option was not selected"
    }
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    Write-TaskPostRun "`$script:IsSecurityLog = `$$IsSecurityLog"
}

# Gets if system log option was selected
# Input:
#   ---
# Output:
#   IsSystemLog - Tells if security logs option was selected (true/false)
function Get-IsSystemLogSelected {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 5
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = "Getting is system log selected ..."
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    if ($FuncArgs.Count -eq 0) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('LogsParams')) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument does not contain 'LogsParams' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:LogsParams = $FuncArgs.LogsParams

    $local:Err = Get-ParamValue $LogsParams 'isSystemLog'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:IsSystemLog = $ParamValue
    if ($IsSystemLog.Equals('true')) {
        $Message = "System log option was selected"
    }
    else {
        $Message = "System log option was not selected"
    }
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    Write-TaskPostRun "`$script:IsSystemLog = `$$IsSystemLog"
}

function Add-LogsPiplineToOtelConfig {
    $local:ExitCode = 6
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding logs pipeline to OTEL config ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    $local:Err = Add-YamlFileFieldObject "$LogzioTempDir\resources\otel\logs_pipeline.yaml" "$LogzioTempDir\resources\otel\otel_config.yaml" '' '.service.pipelines'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Gets logs OTEL receivers
# Input:
#   FuncArgs - Hashtable {LogsTelemetry = $LogsTelemetry}
# Ouput:
#   LogsOtelReceivers - List of Logs OTEL receiver names
function Get-LogsOtelReceivers {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 7
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = "Getting is system log selected ..."
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    if ($FuncArgs.Count -eq 0) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('LogsTelemetry')) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument does not contain 'LogsTelemetry' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsTelemetry = $FuncArgs.LogsTelemetry

    $local:Err = Get-JsonStrFieldValueList $LogsTelemetry '.otel.receivers[]'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsOtelReceivers = $JsonValue

    $Message = "OTEL receivers are '$LogsOtelReceivers'"
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    $local:LogsOtelReceiversStr = Convert-ListToStr $LogsOtelReceivers
    Write-TaskPostRun "`$script:LogsOtelReceivers = $LogsOtelReceiversStr"
}

# Adds logs receivers to OTEL config
function Add-LogsReceiversToOtelConfig {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 8
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = "Adding logs receivers to OTEL config ..."
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    if ($FuncArgs.Count -eq 0) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('LogsOtelReceivers')) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument does not contain 'LogsOtelReceivers' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('LogSources')) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument does not contain 'LogSources' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('IsApplicationLog')) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument does not contain 'IsApplicationLog' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('IsSecurityLog')) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument does not contain 'IsSecurityLog' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('IsSystemLog')) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument does not contain 'IsSystemLog' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsOtelReceivers = $FuncArgs.LogsOtelReceivers
    $local:LogSources = $FuncArgs.LogSources
    $local:IsApplicationLog = $FuncArgs.IsApplicationLog
    $local:IsSecurityLog = $FuncArgs.IsSecurityLog
    $local:IsSystemLog = $FuncArgs.IsSystemLog

    foreach ($LogsOtelReceiver in $LogsOtelReceivers) {
        $local:Err = Get-YamlFileFieldValue "$LogzioTempDir\resources\otel\receivers\$LogsOtelReceiver.yaml" '.windows_run'
        if ($Err.Count -ne 0) {
            $Message = "logs.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
            Write-TaskPostRun "Write-Error `"$Message`""
    
            return $ExitCode
        }

        $local:ScriptBlock = $YamlValue

        $ScriptBlock | Out-File -FilePath $LogzioTempDir\otel_function.ps1 -Encoding utf8
        . $LogzioTempDir\otel_function.ps1
        if ($LASTEXITCODE -ne 0) {
            return $ExitCode
        }

        $Err = New-OtelReceiver $LogSources 'agent-windows'
        if ($Err.Count -ne 0 -and $Err[1] -ne 1) {
            $Message = "logs.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }
        if ($Err.Count -ne 0) {
            $Message = $Err[0]
            Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-Log $LogLevelDebug $Message

            continue
        }

        $Err = Add-YamlFileFieldObject "$LogzioTempDir\resources\otel\receivers\$LogsOtelReceiver.yaml" "$LogzioTempDir\resources\otel\otel_config.yaml" '.receiver' '.receivers'
        if ($Err.Count -ne 0) {
            $Message = "logs.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        $Err = Add-YamlFileFieldValue "$LogzioTempDir\resources\otel\otel_config.yaml" '.service.pipelines.logs.receivers' "$LogsOtelReceiver\NAME"
        if ($Err.Count -ne 0) {
            $Message = "logs.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }
    }

    (Get-Content -Path "$LogzioTempDir\resources\otel\otel_config.yaml").Replace('NAME', "$Platform`_$SubType`_system") | Set-Content -Path "$LogzioTempDir\resources\otel\otel_config.yaml"
}

# Gets logs OTEL processors
# Input:
#   FuncArgs - Hashtable {LogsTelemetry = $LogsTelemetry}
# Ouput:
#   LogsOtelProcessors - List of Logs OTEL processor names
function Get-LogsOtelProcessors {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 9
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = "Getting is system log selected ..."
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    if ($FuncArgs.Count -eq 0) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('LogsTelemetry')) {
        $Message = "logs.ps1 ($ExitCode): function hashtable argument does not contain 'LogsTelemetry' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platform $SubType $DataSourceSystem
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsTelemetry = $FuncArgs.LogsTelemetry

    $local:Err = Get-JsonStrFieldValueList $LogsTelemetry '.otel.processors[]'
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsOtelProcessors = $JsonValue

    $Message = "OTEL processors are '$LogsOtelProcessors'"
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    $local:LogsOtelProcessorssStr = Convert-ListToStr $LogsOtelProcessors
    Write-TaskPostRun "`$script:LogsOtelReceivers = $LogsOtelProcessorssStr"
}


function Add-LogsProcessorsToOtelConfig {
    $local:ExitCode = 9
    $local:FuncName = $MyInvocation.MyCommand.Name


}



# Adds logs exporter to OTEL config
# Error:
#   Exit Code 6
function Add-LogsExporterToOTELConfig {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile
    $local:taskErrorFile = $using:taskErrorFile

    Write-Log "INFO" "Adding logs exporter to OTEL config ..."

    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/logs/logs_otel_exporter.yaml -OutFile $using:logzioTempDir\logs_otel_exporter.yaml | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"logs.ps1 (6): failed to get logs_otel_exporter yaml file from logzio-agent-manifest repo.`n  $_`""
        return 6
    }

    yq e -i ".logzio/logs.account_token = ""`"$using:logsToken`"""" $using:logzioTempDir\logs_otel_exporter.yaml 2>$using:taskErrorFile
    if (-Not $?) {
        $local:err = Get-TaskError
        Write-Run "Write-Error `"logs.ps1 (6): failed to insert Logz.io logs token into logs_otel_exporter yaml file.`n  $err`""
        return 6
    }

    yq e -i ".logzio/logs.region = ""`"$using:logzioRegion`"""" $using:logzioTempDir\logs_otel_exporter.yaml 2>$using:taskErrorFile
    if (-Not $?) {
        $local:err = Get-TaskError
        Write-Run "Write-Error `"logs.ps1 (6): failed to insert Logz.io region into logs_otel_exporter yaml file.`n  $err`""
        return 6
    }

    yq eval-all -i 'select(fileIndex==0).exporters += select(fileIndex==1) | select(fileIndex==0)' $using:otelConfig $using:logzioTempDir\logs_otel_exporter.yaml 2>$using:taskErrorFile
    if (-Not $?) {
        $local:err = Get-TaskError
        Write-Run "Write-Error `"logs.ps1 (6): failed to add logs exporter to OTEL config file.`n  $err`""
        return 6
    }
}

# Adds logs service pipeline to OTEL config
# Error:
#   Exit Code 7
function Add-LogsServicePipelineToOTELConfig {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile
    $local:taskErrorFile = $using:taskErrorFile

    Write-Log "INFO" "Adding logs service pipeline to OTEL config ..."

    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/logs/logs_otel_service_pipeline.yaml -OutFile $using:logzioTempDir\logs_otel_service_pipeline.yaml | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"logs.ps1 (7): failed to get logs_otel_service_pipeline yaml file from logzio-agent-manifest repo.`n  $_`""
        return 7
    }

    if (-Not [string]::IsNullOrEmpty($using:logSources)) {
        yq e -i '.logs.receivers += ""filelog""' $using:logzioTempDir\logs_otel_service_pipeline.yaml 2>$using:taskErrorFile
        if (-Not $?) {
            $local:err = Get-TaskError
            Write-Run "Write-Error `"logs.ps1 (7): failed to add service pipeline logs receiver into logs_otel_service_pipeline yaml file (filelog).`n  $err`""
            return 7
        }
    }

    if ($using:isApplicationLog) {
        yq e -i '.logs.receivers += ""windowseventlog/application""' $using:logzioTempDir\logs_otel_service_pipeline.yaml 2>$using:taskErrorFile
        if (-Not $?) {
            $local:err = Get-TaskError
            Write-Run "Write-Error `"logs.ps1 (7): failed to add service pipeline logs receiver into logs_otel_service_pipeline yaml file (windowseventlog/application).`n  $err`""
            return 7
        }
    }

    if ($using:isSecurityLog) {
        yq e -i '.logs.receivers += ""windowseventlog/security""' $using:logzioTempDir\logs_otel_service_pipeline.yaml 2>$using:taskErrorFile
        if (-Not $?) {
            $local:err = Get-TaskError
            Write-Run "Write-Error `"logs.ps1 (7): failed to add service pipeline logs receiver into logs_otel_service_pipeline yaml file (windowseventlog/security).`n  $err`""
            return 7
        }
    }

    if ($using:isSystemLog) {
        yq e -i '.logs.receivers += ""windowseventlog/system""' $using:logzioTempDir\logs_otel_service_pipeline.yaml 2>$using:taskErrorFile
        if (-Not $?) {
            $local:err = Get-TaskError
            Write-Run "Write-Error `"logs.ps1 (7): failed to add service pipeline logs receiver into logs_otel_service_pipeline yaml file (windowseventlog/system).`n  $err`""
            return 7
        }
    }

    yq e -i '.logs.exporters += ""logzio/logs""' $using:logzioTempDir\logs_otel_service_pipeline.yaml 2>$using:taskErrorFile
    if (-Not $?) {
        $local:err = Get-TaskError
        Write-Run "Write-Error `"logs.ps1 (7): failed to add service pipeline logs exporter into logs_otel_service_pipeline yaml file.`n  $err`""
        return 7
    }

    yq eval-all -i 'select(fileIndex==0).service.pipelines += select(fileIndex==1) | select(fileIndex==0)' $using:otelConfig $using:logzioTempDir\logs_otel_service_pipeline.yaml 2>$using:taskErrorFile
    if (-Not $?) {
        $local:err = Get-TaskError
        Write-Run "Write-Error `"logs.ps1 (7): failed to add logs service pipeline to OTEL config file.`n  $err`""
        return 7
    }
}
