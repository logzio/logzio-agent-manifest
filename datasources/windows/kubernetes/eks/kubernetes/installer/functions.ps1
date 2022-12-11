#################################################################################################################################
################################################# WINDOWS Installer Functions ###################################################
#################################################################################################################################

# Gets the selected products (logs/metrics/traces)
# Input:
#   ---
# Output:
#   IsLogsOptionSelected - Tells if logs option was selected (true/false)
#   LogsTelemetry - The logs telemetry if logs option was selected
#   LogsParams - The logs params if logs option was selected
#   IsMetricsOptionSelected - Tells if metrics option was selected (true/false)
#   MetricsTelemetry - The metrics telemetry if metrics option was selected
#   MetricsParams - The metrics params if metrics option was selected
#   IsTracesOptionSelected - Tells if traces option was selected (true/false)
#   TracesTelemetry - The traces telemetry if traces option was selected
#   TracesParams - The traces params if traces option was selected
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
    $local:IsTracesOptionSelected = $false
    
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

# Gets is Taints and Tolerations option was selected
# Input:
#   FuncArgs - Hashtable {GeneralParams = $script:GeneralParams}
# Output:
#   IsTaint - Tells if Taints and Tolerations option was selected (true/false)
function Get-IsTaintsAndTolerationWasSelected {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting is Taints and Toleration was selected ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('GeneralParams')
    if ($Err.Count -ne 0) {
        $Message = "installer.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:GeneralParams = $FuncArgs.GeneralParams

    $Err = Get-ParamValue $GeneralParams 'isTaint'
    if ($Err.Count -ne 0) {
        $Message = "installer.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:IsTaint = $script:ParamValue

    if ($IsTaint) {
        $Message = "Taints and Tolerations option was selected"
    }
    else {
        $Message = "Taints and Tolerations option was not selected"
    }
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:IsTaint = `$$IsTaint"
}

# Gets environment id
# Input:
#   FuncArgs - Hashtable {GeneralParams = $script:GeneralParams}
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

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('GeneralParams')
    if ($Err.Count -ne 0) {
        $Message = "installer.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:GeneralParams = $FuncArgs.GeneralParams

    $Err = Get-ParamValue $GeneralParams 'envID'
    if ($Err.Count -ne 0) {
        $Message = "installer.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:EnvId = $script:ParamValue

    $Message = "Environment id is '$EnvId'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message
    
    Write-TaskPostRun "`$script:EnvId = '$EnvId'"
}

# Builds tolerations Helm sets
# Input:
#   FuncArgs - Hashtable {GeneralParams = $script:GeneralParams; IsLogsOptionSelected = $script:IsLogsOptionSelected;
#                        IsMetricsOptionSelected = $script:IsMetricsOptionSelected; IsTracesOptionSelected = $script:IsTracesOptionSelected}
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   HelmSets - Contains all the Helm sets
function Build-TolerationsHelmSets {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 5
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building tolerations Helm sets ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('GeneralParams', 'IsLogsOptionSelected', 'IsMetricsOptionSelected', 'IsTracesOptionSelected')
    if ($Err.Count -ne 0) {
        $Message = "installer.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:GeneralParams = $FuncArgs.GeneralParams
    $local:IsLogsOptionSelected = $FuncArgs.IsLogsOptionSelected
    $local:IsMetricsOptionSelected = $FuncArgs.IsMetricsOptionSelected
    $local:IsTracesOptionSelected = $FuncArgs.IsTracesOptionSelected

    $local:Nodes = kubectl get nodes -o json 2>$script:TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        $Message = "installer.ps1 ($ExitCode): error getting nodes: $(Get-TaskErrorMessage)"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    
    $local:Err = Get-JsonStrFieldValueList $Nodes '.items[].spec | select(.taints!=null) | .taints[]'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        $Message = "installer.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -ne 0) {
        $Message = 'No taints found'
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-Log $script:LogLevelDebug $Message

        return
    }

    $local:Taints = $script:JsonValue

    $local:TolerationHelmSets = ''
    $local:TolerationIndex = 0
    foreach ($Taint in $Taints) {
        $Err = Get-JsonStrFieldValue $Taint '.key'
        if ($Err.Count -ne 0) {
            $Message = "installer.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""
    
            return $ExitCode
        }

        $local:Key = $script:JsonValue

        $Err = Get-JsonStrFieldValue $Taint '.effect'
        if ($Err.Count -ne 0) {
            $Message = "installer.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""
    
            return $ExitCode
        }

        $local:Effect = $script:JsonValue

        $local:Operator = 'Exists'
        $local:Value = $null
        $Err = Get-JsonFileFieldValue $Taint '.value'
        if ($Err.Count -ne 0 -and $Err[1] -ne 3) {
            $Message = "installer.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
            Write-TaskPostRun "Write-Error `"$Message`""
    
            return $ExitCode
        }
        if ($Err.Count -ne 0) {
            $Value = ''
        }
        else {
            $Value = $script:JsonValue
        }

        if (-Not [string]::IsNullOrEmpty($Value)) {
            $Operator = 'Equal'

            if ($script:IsLogsOptionSelected) {
                $TolerationHelmSets += " --set-string logzio-fluentd.daemonset.tolerations[$TolerationIndex].value=$Value"
            }
            if ($script:IsMetricsOptionSelected -or $script:IsTracesOptionSelected) {
                $TolerationHelmSets += " --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$TolerationIndex].value=$Value"
                $TolerationHelmSets += " --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$TolerationIndex].value=$Value"
                $TolerationHelmSets += " --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$TolerationIndex].value=$Value"
                $TolerationHelmSets += " --set-string logzio-k8s-telemetry.tolerations[$TolerationIndex].value=$Value"
            }
        }
        
        if ($script:IsLogsOptionSelected) {
            $TolerationHelmSets += " --set-string logzio-fluentd.daemonset.tolerations[$TolerationIndex].key=$Key"
            $TolerationHelmSets += " --set-string logzio-fluentd.daemonset.tolerations[$TolerationIndex].operator=$Operator"
            $TolerationHelmSets += " --set-string logzio-fluentd.daemonset.tolerations[$TolerationIndex].effect=$Effect"
        }
        if ($script:IsMetricsOptionSelected -or $script:IsTracesOptionSelected) {
            $TolerationHelmSets += " --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$TolerationIndex].key=$Key"
            $TolerationHelmSets += " --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$TolerationIndex].operator=$Operator"
            $TolerationHelmSets += " --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$TolerationIndex].effect=$Effect"
            $TolerationHelmSets += " --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$TolerationIndex].key=$Key"
            $TolerationHelmSets += " --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$TolerationIndex].operator=$Operator"
            $TolerationHelmSets += " --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$TolerationIndex].effect=$Effect"
            $TolerationHelmSets += " --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$TolerationIndex].key=$Key"
            $TolerationHelmSets += " --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$TolerationIndex].operator=$Operator"
            $TolerationHelmSets += " --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$TolerationIndex].effect=$Effect"
            $TolerationHelmSets += " --set-string logzio-k8s-telemetry.tolerations[$TolerationIndex].key=$Key"
            $TolerationHelmSets += " --set-string logzio-k8s-telemetry.tolerations[$TolerationIndex].operator=$Operator"
            $TolerationHelmSets += " --set-string logzio-k8s-telemetry.tolerations[$TolerationIndex].effect=$Effect"
        }

        $TolerationIndex++        
    }

    $Message = "Toleration Helm sets are '$TolerationHelmSets'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$TolerationsHelmSets'"
    Write-TaskPostRun "`$script:HelmSets += '$TolerationsHelmSets'"
}

# Builds enable metrics or traces Helm set
# Input:
#   ---
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   helmSets - Contains all the Helm sets
function Build-EnableMetricsOrTracesHelmSet {
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building enable metrics or traces Helm set ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:HelmSet = " --set metricsOrTraces.enabled=true"
    
    $Message = "Enable metrics or traces Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}

# Builds metrics/traces environment tag Helm set
# Input:
#   FuncArgs - Hashtable {EnvId = $script:EnvId}
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   HelmSets - Contains all the Helm sets
function Build-EnvironmentTagHelmSet {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 6
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building environment tag Helm set ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('EnvId')
    if ($Err.Count -ne 0) {
        $Message = "installer.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:EnvId = $FuncArgs.EnvId

    $local:HelmSet = " --set logzio-k8s-telemetry.secrets.p8s_logzio_name=$EnvId"
    
    $Message = "Environment tag Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}

# Builds metrics/traces environment id helm set
# Input:
#   FuncArgs - Hashtable {EnvId = $script:EnvId}
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   HelmSets - Contains all the Helm sets
function Build-EnvironmentIdHelmSet {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 7
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building environment id Helm set ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('EnvId')
    if ($Err.Count -ne 0) {
        $Message = "installer.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:EnvId = $FuncArgs.EnvId

    if ([string]::IsNullOrEmpty($EnvId)) {
        $Message = 'Environment id is empty. Default value will be used'
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-Log $script:LogLevelDebug $Message

        return
    }

    $local:HelmSet = " --set logzio-k8s-telemetry.secrets.env_id=$EnvId"

    $Message = "Environment id Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}
