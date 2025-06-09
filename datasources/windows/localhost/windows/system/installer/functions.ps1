#################################################################################################################################
################################################# WINDOWS Installer Functions ###################################################
#################################################################################################################################

# Gets the selected products (logs/metrics)
# Input:
#   ---
# Output:
#   IsLogsOptionSelected - Tells if logs option was selected (true/false)
#   LogsTelemetry - The logs telemetry if logs option was selected
#   LogsParams - The logs params if logs option was selected
#   IsMetricsOptionSelected - Tells if metrics option was selected (true/false)
#   MetricsTelemetry - The metrics telemetry if metrics option was selected
#   MetricsParams - The metrics params if metrics option was selected
#   IsTracesOptionSelected - Tells if Traces option was selected (true/false)
#   TracesTelemetry - The Traces telemetry if logs option was selected
#   TracesParams - The Traces params if logs option was selected
function Get-SelectedProducts {
    $local:ExitCode = 1
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting the selected products ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:DataSourceIndex = 0
    foreach ($DataSource in $script:DataSources) {
        if ($Datasource.Equals($script:CurrentDataSource)) {
            break
        }

        $DataSourceIndex++
    }

    $local:Err = Get-JsonFileFieldValueList $script:AgentJson ".configuration.subtypes[0].datasources[$DataSourceIndex].telemetries[]"
    if ($Err.Count -ne 0) {
        $Message = "installer.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:Telemetries = $script:JsonValue
    
    $local:IsLogsOptionSelected = $false
    $local:IsMetricsOptionSelected = $false
    
    $local:TelemetryIndex = 0
    foreach ($Telemetry in $Telemetries) {
        $Err = Get-JsonStrFieldValue $Telemetry '.type'
        if ($Err.Count -ne 0) {
            $Message = "installer.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""
    
            return $ExitCode
        }

        $local:Type = $script:JsonValue
        $local:Params = $null

        $Err = Get-JsonStrFieldValueList $Telemetry '.params[]'
        if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
            $Message = "installer.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""
    
            return $ExitCode
        }
        if ($Err.Count -ne 0) {
            $Params = ''
        }
        else {
            $Params = $script:JsonValue
        }

        $local:ParamsStr = Convert-ListToStr $Params

        if ($Type.Equals('LOG_ANALYTICS')) {
            $Message = 'Logs option was selected'
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-Log $script:LogLevelDebug $Message
            $Message = "Logs telemetry is '$Telemetry'"
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-Log $script:LogLevelDebug $Message
            $Message = "Logs params are '$Params'"
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-Log $script:LogLevelDebug $Message

            $IsLogsOptionSelected = $true
            Write-TaskPostRun "`$script:LogsTelemetry = '$Telemetry'"
            Write-TaskPostRun "`$script:LogsParams = $ParamsStr"
        } 
        elseif ($Type.Equals('METRICS')) {
            $Message = 'Metrics option was selected'
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-Log $script:LogLevelDebug $Message
            $Message = "Metrics telemetry is '$Telemetry'"
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-Log $script:LogLevelDebug $Message
            $Message = "Metrics params are '$Params'"
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-Log $script:LogLevelDebug $Message

            $IsMetricsOptionSelected = $true
            Write-TaskPostRun "`$script:MetricsTelemetry = '$Telemetry'"
            Write-TaskPostRun "`$script:MetricsParams = $ParamsStr"
        }
        elseif ($Type.Equals('TRACING')) {
          $Message = 'Traces option was selected'
          Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
          Write-Log $script:LogLevelDebug $Message
          $Message = "Traces telemetry is '$Telemetry'"
          Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
          Write-Log $script:LogLevelDebug $Message
          $Message = "Traces params are '$Params'"
          Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
          Write-Log $script:LogLevelDebug $Message

          $IsTracesOptionSelected = $true
          Write-TaskPostRun "`$script:TracesTelemetry = '$Telemetry'"
          Write-TaskPostRun "`$script:TracesParams = $ParamsStr"
      }

        $TelemetryIndex++
    }

    Write-TaskPostRun "`$script:IsLogsOptionSelected = `$$IsLogsOptionSelected"
    Write-TaskPostRun "`$script:IsMetricsOptionSelected = `$$IsMetricsOptionSelected"
    Write-TaskPostRun "`$script:IsTracesOptionSelected = `$$IsTracesOptionSelected"
}

# Gets general params (params under datasource)
# Input:
#   ---
# Output:
#   GeneralParams - The params under datasource
function Get-GeneralParams {
    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting general params ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:DataSourceIndex = 0
    foreach ($DataSource in $script:DataSources) {
        if ($Datasource.Equals($script:CurrentDataSource)) {
            break
        }

        $DataSourceIndex++
    }

    $local:Err = Get-JsonFileFieldValueList $script:AgentJson ".configuration.subtypes[0].datasources[$DataSourceIndex].params[]"
    if ($Err.Count -ne 0) {
        $Message = "installer.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:Params = $script:JsonValue

    $Message = "General params are '$Params'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:ParamsStr = Convert-ListToStr $Params

    Write-TaskPostRun "`$script:GeneralParams = $ParamsStr"
}

# Gets environment id
# Input:
#   FuncArgs - Hashtable {GeneralParams = $script:GeneralParams; DefaultEnvId = $script:DefaultEnvId}
# Output:
#   EnvId - The environment id
function Get-EnvironmentID {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 4
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting environment id ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('GeneralParams', 'DefaultEnvId')
    if ($Err.Count -ne 0) {
        $Message = "installer.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:GeneralParams = $FuncArgs.GeneralParams
    $local:DefaultEnvId = $FuncArgs.DefaultEnvId

    $Err = Get-ParamValue $GeneralParams 'envID'
    if ($Err.Count -ne 0) {
        $Message = "installer.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:EnvId = $script:ParamValue

    if ([string]::IsNullOrEmpty($EnvId)) {
        $EnvId = kubectl config current-context 2>$Null
        if ($LASTEXITCODE -ne 0) {
            $EnvId = $DefaultEnvId
        }
    }

    $Message = "Environment id is '$EnvId'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message
    [System.Environment]::SetEnvironmentVariable('ENV_ID', $EnvId, 'User')
    Write-TaskPostRun "`$script:ENV_ID = '$EnvId'"
}
