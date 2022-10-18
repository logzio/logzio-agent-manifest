#################################################################################################################################
################################################# WINDOWS Installer Functions ###################################################
#################################################################################################################################

# Gets the selected products (logs/metrics)
# Input:
#   ---
# Output:
#   IsLogsOptionSelected - Tells if logs option was selected (true/false)
#   LogsParams - The logs params if logs option was selected
#   IsMetricsOptionSelected - Tells if metrics option was selected (true/false)
#   MetricsParams - The metrics params if metrics option was selected
function Get-SelectedProducts {
    $local:ExitCode = 1
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting the selected products ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepSubTypeInstaller $LogScriptSubTypeInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    $local:DataSourceIndex = 0
    foreach ($DataSource in $DataSource) {
        if ($Datasource.Equals($DataSourceSystem)) {
            break
        }

        $DataSourceIndex++
    }

    $local:Telemetries = &$JqExe -c ".configuration.subtypes[0].datasources[$DataSourceIndex].telemetries[]" $AgentJson 2>$TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        $Message = "installer.ps1 ($ExitCode): error getting telemetries from agent json: $(Get-Content -Path $TaskErrorFile)"
        Send-LogToLogzio $LogLevelError $Message $LogStepSubTypeInstaller $LogScriptSubTypeInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if ($Telemetries.Count -eq 0) {
        $Message = "agent.ps1 ($ExitCode): '.configuration.subtypes[0].datasources[$DataSourceIndex].telemetries[]' in agent json is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:IsLogsOptionSelected = $false
    $local:IsMetricsOptionSelected = $false
    
    $local:Index = 0
    foreach ($Telemetry in $Telemetries) {
        $local:Type = $Telemetry | &$JqExe -r '.type' 2>$TaskErrorFile
        if ($LASTEXITCODE -ne 0) {
            $Message = "installer.ps1 ($ExitCode): error getting telemetry type from agent json: $(Get-Content -Path $TaskErrorFile)"
            Send-LogToLogzio $LogLevelError $Message $LogStepSubTypeInstaller $LogScriptSubTypeInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-TaskPostRun "Write-Error '$Message'"
    
            return $ExitCode
        }
        if ([string]::IsNullOrEmpty($Type) -or $Type.Equals('null')) {
            $Message = "installer.ps1 ($ExitCode): '.configuration.subtypes[0].datasources[$DataSourceIndex].telemetries[$Index].type' in agent json does not exist or is empty"
            Send-LogToLogzio $LogLevelError $Message $LogStepSubTypeInstaller $LogScriptSubTypeInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-TaskPostRun "Write-Error '$Message'"

            return $ExitCode
        }

        $local:Params = $Telemetry | &$JqExe -r '.params[]' 2>$TaskErrorFile
        if ($LASTEXITCODE -ne 0) {
            $Message = "installer.ps1 ($ExitCode): error getting telemetry params from agent json: $(Get-Content -Path $TaskErrorFile)"
            Send-LogToLogzio $LogLevelError $Message $LogStepSubTypeInstaller $LogScriptSubTypeInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-TaskPostRun "Write-Error '$Message'"
    
            return $ExitCode
        }
        if ([string]::IsNullOrEmpty($Params)) {
            $params = ''
        }
        if ($Params.Equals('null')) {
            $Message = "installer.ps1 ($ExitCode): '.configuration.subtypes[0].datasources[$DataSourceIndex].telemetries[$Index].type' in agent json does not exist"
            Send-LogToLogzio $LogLevelError $Message $LogStepSubTypeInstaller $LogScriptSubTypeInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-TaskPostRun "Write-Error '$Message'"
    
            return $ExitCode
        }

        if ($type.Equals('LOG_ANALYTICS')) {
            $Message = 'Logs option was selected'
            Send-LogToLogzio $LogLevelDebug $Message $LogStepSubTypeInstaller $LogScriptSubTypeInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-Log $LogLevelDebug $Message
            $Message = "Logs params are $Params"
            Send-LogToLogzio $LogLevelDebug $Message $LogStepSubTypeInstaller $LogScriptSubTypeInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-Log $LogLevelDebug $Message

            $IsLogsOptionSelected = $true
            Write-TaskPostRun "`$script:LogsParams = '$Params'"
        } elseif ($Type.Equals('METRICS')) {
            $Message = 'Metrics option was selected'
            Send-LogToLogzio $LogLevelDebug $Message $LogStepSubTypeInstaller $LogScriptSubTypeInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-Log $LogLevelDebug $Message
            $Message = "Metrics params are $Params"
            Send-LogToLogzio $LogLevelDebug $Message $LogStepSubTypeInstaller $LogScriptSubTypeInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
            Write-Log $LogLevelDebug $Message

            $IsMetricsOptionSelected = $true
            Write-TaskPostRun "`$script:MetricsParams = '$Params'"
        }

        $Index++
    }

    Write-TaskPostRun "`$script:IsLogsOptionSelected = `$$IsLogsOptionSelected"
    Write-TaskPostRun "`$script:IsMetricsOptionSelected = `$$IsMetricsOptionSelected"
}
