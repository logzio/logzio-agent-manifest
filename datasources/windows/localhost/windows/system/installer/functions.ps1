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
