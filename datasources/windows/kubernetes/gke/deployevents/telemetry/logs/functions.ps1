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

# Builds enable deploy events Helm set
# Input:
#   ---
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   helmSets - Contains all the Helm sets
function Build-EnableDeployEventsHelmSet {
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building enable deploy events Helm set ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message
    
    $local:HelmSet = " --set deployEvents.enabled=true"

    $Message = "Enable deploy events Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}

# Builds Logz.io deploy events logs listener url Helm set
# Input:
#   FuncArgs - Hashtable {ListenerUrl = $script:ListenerUrl}
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   HelmSets - Contains all the Helm sets
function Build-LogzioDeployEventsLogsListenerUrlHelmSet {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 6
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building Logz.io deploy events logs listener URL Helm set ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('ListenerUrl')
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:ListenerUrl = $FuncArgs.ListenerUrl

    $local:HelmSet = " --set logzio-k8s-events.secrets.logzioListener=$ListenerUrl"

    $Message = "Logz.io deploy events logs listener url Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}

# Builds Logz.io deploy events logs token Helm set
# Input:
#   FuncArgs - Hashtable {LogsToken = $script:LogsToken}
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   helmSets - Contains all the Helm sets
function Build-LogzioDeployEventsLogsTokenHelmSet {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 7
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building Logz.io deploy events logs token Helm set ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('LogsToken')
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:LogsToken = $FuncArgs.LogsToken

    $local:HelmSet = " --set logzio-k8s-events.secrets.logzioShippingToken=$LogsToken"
    
    $Message = "Logz.io deploy events logs token Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}

# Builds Deploy events environment id Helm set
# Input:
#   FuncArgs - Hashtable {EnvId = $script:EnvId}
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   helmSets - Contains all the Helm sets
function Build-DeployEventsEnvironmentIdHelmSet {
    param (
        [hashtable]$FuncArgs
    )
    
    $local:ExitCode = 8
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building deploy events environment id Helm set ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('EnvId')
    if ($Err.Count -ne 0) {
        $Message = "logs.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:EnvId = $FuncArgs.EnvId

    if ([string]::IsNullOrEmpty($EnvId)) {
        $Message = 'Environment id is empty. Default value will be used'
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-Log $script:LogLevelDebug $Message
        
        return
    }

    $local:HelmSet = " --set logzio-k8s-events.secrets.env_id=$EnvId"

    $Message = "Deploy events Environment id Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}
