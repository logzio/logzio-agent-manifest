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
function Get-SelectedProducts {
    $local:ExitCode = 1
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting the selected products ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    $local:DataSourceIndex = 0
    foreach ($DataSource in $DataSources) {
        if ($Datasource.Equals($DataSourceSystem.ToLower())) {
            break
        }

        $DataSourceIndex++
    }

    $local:Err = Get-JsonFileFieldValueList $AgentJson ".configuration.subtypes[0].datasources[$DataSourceIndex].telemetries[]"
    if ($Err.Count -ne 0) {
        $Message = "installer.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $LogLevelError $Message $LogStepInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:Telemetries = $JsonValue
    $local:IsLogsOptionSelected = $false
    $local:IsMetricsOptionSelected = $false
    
    $local:TelemetryIndex = 0
    foreach ($Telemetry in $Telemetries) {
        $Err = Get-JsonStrFieldValue $Telemetry '.type'
        if ($Err.Count -ne 0) {
            $Message = "installer.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $LogLevelError $Message $LogStepInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-TaskPostRun "Write-Error `"$Message`""
    
            return $ExitCode
        }

        $local:Type = $JsonValue
        $local:Params = $null

        $Err = Get-JsonStrFieldValueList $Telemetry '.params[]'
        if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
            $Message = "installer.ps1 ($ExitCode): $($Result[0])"
            Send-LogToLogzio $LogLevelError $Message $LogStepInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-TaskPostRun "Write-Error `"$Message`""
    
            return $ExitCode
        }
        if ($Err.Count -ne 0) {
            $Params = ''
        }
        else {
            $Params = $JsonValue
        }

        $local:ParamsStr = Convert-ListToStr $Params

        if ($type.Equals('LOG_ANALYTICS')) {
            $Message = 'Logs option was selected'
            Send-LogToLogzio $LogLevelDebug $Message $LogStepInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-Log $LogLevelDebug $Message
            $Message = "Logs telemetry is '$Telemetry'"
            Send-LogToLogzio $LogLevelDebug $Message $LogStepInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-Log $LogLevelDebug $Message
            $Message = "Logs params are '$Params'"
            Send-LogToLogzio $LogLevelDebug $Message $LogStepInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-Log $LogLevelDebug $Message

            $IsLogsOptionSelected = $true
            Write-TaskPostRun "`$script:LogsTelemetry = '$Telemetry'"
            Write-TaskPostRun "`$script:LogsParams = $ParamsStr"
        } elseif ($Type.Equals('METRICS')) {
            $Message = 'Metrics option was selected'
            Send-LogToLogzio $LogLevelDebug $Message $LogStepInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-Log $LogLevelDebug $Message
            $Message = "Metrics telemetry is '$Telemetry'"
            Send-LogToLogzio $LogLevelDebug $Message $LogStepInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-Log $LogLevelDebug $Message
            $Message = "Metrics params are '$Params'"
            Send-LogToLogzio $LogLevelDebug $Message $LogStepInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-Log $LogLevelDebug $Message

            $IsMetricsOptionSelected = $true
            Write-TaskPostRun "`$script:MetricsTelemetry = '$Telemetry'"
            Write-TaskPostRun "`$script:MetricsParams = $ParamsStr"
        }

        $TelemetryIndex++
    }

    Write-TaskPostRun "`$script:IsLogsOptionSelected = `$$IsLogsOptionSelected"
    Write-TaskPostRun "`$script:IsMetricsOptionSelected = `$$IsMetricsOptionSelected"
}
