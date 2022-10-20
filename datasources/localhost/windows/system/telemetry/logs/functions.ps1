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

    $local:Err = Get-ParamValue $LogsParams 'logSources' $true
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $LogLevelError $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:LogSources = $ParamValue
    
    $local:Message = "log sources are '$LogSources'"
    Send-LogToLogzio $LogLevelDebug $Message $LogStepLogs $LogScriptLogs $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogSources = '$LogSources'"
}

# Gets the selected logs
# Output:
#   isApplicationLog - Tells if application logs option was selected (true/false)
#   isSecurityLog - Tells if security logs option was selected (true/false)
#   isSystemLog - Tells if system logs option was selected (true/false)
# Error:
#   Exit Code 4
function Get-SelectedLogs {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting selected logs ..."

    $local:isApplicationLogParam = Find-Param "$using:logsParams" "isApplicationLog"
    if ([string]::IsNullOrEmpty($isApplicationLogParam)) {
        Write-Run "Write-Error `"logs.ps1 (4): isApplicationLog param was not found`""
        return 4
    }

    $local:isApplicationLogValue = Write-Output "$isApplicationLogParam" | jq -r '.value'
    if ($isApplicationLogValue.Equals("null")) {
        Write-Run "Write-Error `"logs.ps1 (4): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=isApplicationLog}].value' was not found in application JSON`""
        return 4
    }

    $local:isSecurityLogParam = Find-Param "$using:logsParams" "isSecurityLog"
    if ([string]::IsNullOrEmpty($isSecurityLogParam)) {
        Write-Run "Write-Error `"logs.ps1 (4): isSecurityLog param was not found`""
        return 4
    }

    $local:isSecurityLogValue = Write-Output "$isSecurityLogParam" | jq -r '.value'
    if ($isSecurityLogValue.Equals("null")) {
        Write-Run "Write-Error `"logs.ps1 (4): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=isSecurityLog}].value' was not found in application JSON`""
        return 4
    }

    $local:isSystemLogParam = Find-Param "$using:logsParams" "isSystemLog"
    if ([string]::IsNullOrEmpty($isSystemLogParam)) {
        Write-Run "Write-Error `"logs.ps1 (4): isSystemLog param was not found`""
        return 4
    }

    $local:isSystemLogValue = Write-Output "$isSystemLogParam" | jq -r '.value'
    if ($isSystemLogValue.Equals("null")) {
        Write-Run "Write-Error `"logs.ps1 (4): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=isSystemLog}].value' was not found in application JSON`""
        return 4
    }
    
    Write-Log "INFO" "isApplicationLog = $isApplicationLogValue"
    Write-Log "INFO" "isSecurityLog = $isSecurityLogValue"
    Write-Log "INFO" "isSystemLog = $isSystemLogValue"
    Write-Run "`$script:isApplicationLog = '$isApplicationLogValue'"
    Write-Run "`$script:isSecurityLog = '$isSecurityLogValue'"
    Write-Run "`$script:isSystemLog = '$isSystemLogValue'"
}

# Adds logs receivers to OTEL config
# Error:
#   Exit Code 5
function Add-LogsReceiversToOTELConfig {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile
    $local:taskErrorFile = $using:taskErrorFile

    Write-Log "INFO" "Adding logs receivers to OTEL config ..."

    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/logs/logs_otel_receivers.yaml -OutFile $using:logzioTempDir\logs_otel_receivers.yaml | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"logs.ps1 (5): failed to get logs_otel_receivers yaml file from logzio-agent-manifest repo.`n  $_`""
        return 5
    }

    if (-Not [string]::IsNullOrEmpty($using:logSources)) {
        foreach ($logSource in $using:logSources) {
            yq e -i ".filelog.include += `"$logSource`"" $using:logzioTempDir\logs_otel_receivers.yaml 2>$using:taskErrorFile
            if (-Not $?) {
                $local:err = Get-TaskError
                Write-Run "Write-Error `"logs.ps1 (5): failed to insert log sources into logs_otel_receivers yaml file.`n  $err`""
                return 5
            }
        }
    }

    yq eval-all -i 'select(fileIndex==0).receivers += select(fileIndex==1) | select(fileIndex==0)' $using:otelConfig $using:logzioTempDir\logs_otel_receivers.yaml 2>$using:taskErrorFile
    if (-Not $?) {
        $local:err = Get-TaskError
        Write-Run "Write-Error `"logs.ps1 (5): failed to add logs receivers to OTEL config file.`n  $err`""
        return 5
    }
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
