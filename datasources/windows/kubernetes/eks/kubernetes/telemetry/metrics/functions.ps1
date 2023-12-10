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

# Builds enable metrics Helm set
# Input:
#   ---
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   HelmSets - Contains all the Helm sets
function Build-EnableMetricsHelmSet {
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building enable metrics Helm set ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:HelmSet = " --set logzio-k8s-telemetry.metrics.enabled=true"

    $local:Message = "Enable metrics Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}

# Builds Logz.io metrics listener URL Helm set
# Input:
#   FuncArgs - Hashtable {ListenerUrl = $script:ListenerUrl}
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   HelmSets - Contains all the Helm sets
function Build-LogzioMetricsListenerUrlHelmSet {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building Logz.io metrics listener url Helm set ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('ListenerUrl')
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:ListenerUrl = $FuncArgs.ListenerUrl
    $ListenerUrl = "https://$ListenerUrl`:8053"

    $local:HelmSet = " --set logzio-k8s-telemetry.secrets.ListenerHost=$ListenerUrl"

    $local:Message = "Logz.io metrics listener url Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}

# Builds Logz.io metrics token Helm set
# Input:
#   FuncArgs - Hashtabla {MetricsToken = $script:MetricsToken}
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   HelmSets - Contains all the Helm sets
function Build-LogzioMetricsTokenHelmSet {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building Logz.io metrics token Helm set ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('MetricsToken')
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:MetricsToken = $FuncArgs.MetricsToken
    
    $local:HelmSet = " --set logzio-k8s-telemetry.secrets.MetricsToken=$MetricsToken"

    $local:Message = "Logz.io metrics token Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}

# Gets is metrics filter was selected
# Input:
#   FuncArgs - Hashtable {MetricsParams = $script:MetricsParams}
# Output:
#   IsFilter - Tells if metrics filter was selected (true/false)
function Get-IsMetricsFilterWasSelected {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 4
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting if metrics filter option was selected ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('MetricsParams')
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:MetricsParams = $FuncArgs.MetricsParams

    $Err = Get-ParamValue $MetricsParams 'isFilter'
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:IsFilter = $script:ParamValue

    if ($IsFilter) {
        $Message = 'Metrics filter option was selected'
    }
    else {
        $Message = 'Metrics filter option was not selected'
    }
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:IsFilter = `$$IsFilter"
}

# Builds enable metrics filter Helm set
# Input:
#   ---
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   HelmSets - Contains all the Helm sets
function Build-EnableMetricsFilterHelmSet {
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building enable metrics filter Helm set ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message
    
    $local:HelmSet = " --set logzio-k8s-telemetry.enableMetricsFilter.eks=true"

    $local:Message = "Enable metrics filter Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}

# Builds Fargate collector mode standalone Helm set
# Input:
#   ---
# Output:
#   LogHelmSets - Contains all the Helm sets for logging
#   helmSets - Contains all the Helm sets
function Build-FargateCollectorModeStandaloneHelmSet {    
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building Fargate collector mode standalone Helm set ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:HelmSet = " --set logzio-k8s-telemetry.collector.mode=standalone"

    $Message = "Fargate collector mode standalone Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}