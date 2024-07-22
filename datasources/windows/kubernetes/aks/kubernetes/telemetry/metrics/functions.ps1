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

# Gets if Kubernetes runs on Windows OS option was selected
# Input:
#   FuncArgs - Hashtable {MetricsParams = $script:MetricsParams}
# Output:
#   IsWindows - Tells if Kubernetes runs on Windows OS (true/false)
function Get-IsKubernetesRunOnWindowsOsSelected {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 4
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting if Kubernetes runs on Windows OS option was selected ...'
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

    $Err = Get-ParamValue $MetricsParams 'isWindows'
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:IsWindows = $script:ParamValue

    if ($IsWindows) {
        $Message = 'Kubernetes runs on Windows OS option was selected'
    }
    else {
        $Message = 'Kubernetes runs on Windows OS option was not selected'
    }
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:IsWindows = `$$IsWindows"
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

    $local:ExitCode = 5
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
    
    $local:HelmSet = " --set logzio-k8s-telemetry.enableMetricsFilter.aks=true"

    $local:Message = "Enable metrics filter Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}

# Gets Logz.io Kubernetes object logs token
# Input:
#   ---
# Output:
#   ObjectLogsToken - Logz.io Kubernetes object logs token
function Get-LogzioObjectLogsToken {
    $local:ExitCode = 1
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting Logz.io Kubernetes object logs token ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Get-JsonFileFieldValue $script:AgentJson '.shippingTokens.LOG_ANALYTICS'
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    
    $local:ShippingToken = $script:JsonValue

    $Message = "Logz.io Kubernetes object logs token is '$ShippingToken'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:ObjectLogsToken = '$ShippingToken'"
}

# Builds Logz.io Kubernetes object logs token Helm set
# Input:
#   FuncArgs - Hashtabla {ObjectLogsToken = $script:ObjectLogsToken}
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   HelmSets - Contains all the Helm sets
function Build-LogzioObjectLogsTokenHelmSet {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building Logz.io Kubernetes object logs token Helm set ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('ObjectLogsToken')
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:ObjectLogsToken = $FuncArgs.ObjectLogsToken
    
    $local:HelmSet = " --set logzio-k8s-telemetry.secrets.k8sObjectsLogsToken=$ObjectLogsToken"

    $local:Message = "Logz.io Kubernetes object logs token Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}

# Gets is Kubernetes object logs was selected
# Input:
#   FuncArgs - Hashtable {MetricsParams = $script:MetricsParams}
# Output:
#   isObjectLogs - Tells if Kubernetes object logs was selected (true/false)
function Get-IsObjectLogsWasSelected {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 5
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting if Kubernetes object logs option was selected ...'
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

    $Err = Get-ParamValue $MetricsParams 'isObjectLogs'
    if ($Err.Count -ne 0) {
        $Message = "metrics.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:IsObjectLogs = $script:ParamValue

    if ($IsObjectLogs) {
        $Message = 'Kubernetes object logs option was selected'
    }
    else {
        $Message = 'Kubernetes object logs option was not selected'
    }
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:IsObjectLogs = `$$IsObjectLogs"
}

# Builds enable Kubernetes object logs Helm set
# Input:
#   ---
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   HelmSets - Contains all the Helm sets
function Build-EnableObjectLogsHelmSet {
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building enable Kubernetes object logs Helm set ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message
    
    $local:HelmSet = " --set logzio-k8s-telemetry.k8sObjectsConfig.enabled=true"

    $local:Message = "Enable Kubernetes object logs Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}

# Builds Logz.io region Helm set
# Input:
#   FuncArgs - Hashtable {ListenerUrl = $script:ListenerUrl}
# Output:
#   HelmSets - Contains all the Helm sets
function Build-LogzioRegionHelmSet {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name
    
    # Check if LogzioRegion already exists in HelmSets
    if ($script:LogHelmSets -match "logzio-k8s-telemetry\.secrets\.LogzioRegion=[^ ]+") {
        return
    }

    $local:Message = 'Building Logz.io region Helm set ...'
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

    $local:Region = Get-LogzioRegion $ListenerUrl

    $Message = "Logz.io region is '$LogzioRegion'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:HelmSet = " --set logzio-k8s-telemetry.secrets.LogzioRegion=$Region"

    $local:Message = "Logz.io region Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}