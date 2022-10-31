#################################################################################################################################
############################################# WINDOWS Subtype Prerequisites Script ##############################################
#################################################################################################################################

# Checks if localhost can connect to Logz.io logs (port 8071)
# Input:
#   FuncArgs- Hashtable {ListenerUrl = $script:ListenerUrl}
# Output:
#   ---
function Test-CanLocalhostConnectToLogzioLogs {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 1
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if localhost can connect to Logz.io logs (port 8071) ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('ListenerUrl')
    if ($Err.Count -ne 0) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platform $script:SubType
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:ListenerUrl = $FuncArgs.ListenerUrl

    try {
        $local:Result = Test-NetConnection -ComputerName $ListenerUrl -Port 8071 -InformationLevel Quiet -ErrorAction Stop
        if ($Result) {
            return
        }

        $Message = "prerequisites.ps1 ($ExitCode): localhost cannot connect to '$ListenerUrl`:8071'. please check your network for port 8071"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    catch {
        $Message = "prerequisites.ps1 ($ExitCode): error testing network connection to '$ListenerUrl`:8071': $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Checks if localhost can connect to Logz.io metrics (port 8053)
# Input:
#   FuncArgs- Hashtable {ListenerUrl = $script:ListenerUrl}
# Ouput:
#   ---
function Test-CanLocalhostConnectToLogzioMetrics {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if localhost can connect to Logz.io metrics (port 8053) ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('ListenerUrl')
    if ($Err.Count -ne 0) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platform $script:SubType
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:ListenerUrl = $FuncArgs.ListenerUrl

    try {
        $local:Result = Test-NetConnection -ComputerName $ListenerUrl -Port 8053 -InformationLevel Quiet -ErrorAction Stop
        if ($Result) {
            return
        }

        $Message = "prerequisites.ps1 ($ExitCode): localhost cannot connect to '$ListenerUrl`:8053'. please check your network for port 8053"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptAgent $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    catch {
        $Message = "prerequisites.ps1 ($ExitCode): error testing network connection to '$ListenerUrl`:8053': $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptAgent $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}
