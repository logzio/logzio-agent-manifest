#################################################################################################################################
############################################# WINDOWS Subtype Prerequisites Script ##############################################
#################################################################################################################################

# Checks if localhost can connect to Logz.io logs (port 8071)
# Input:
#   ---
# Output:
#   ---
function Test-CanLocalhostConnectToLogzioLogs {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 1
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if localhost can connect to Logz.io logs (port 8071) ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPrerequisites $LogScriptPrerequisites $FuncName $AgentId $Platfrom $Subtype
    Write-Log $LogLevelDebug $Message

    if ($FuncArgs.Count -eq 0) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platform $SubType
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('ListenerUrl')) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument does not contain 'ListenerUrl' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platform $SubType
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:ListenerUrl = $FuncArgs.ListenerUrl

    try {
        $local:Result = Test-NetConnection -ComputerName $ListenerUrl -Port 8071 -InformationLevel Quiet -ErrorAction Stop
        if ($Result) {
            return
        }

        $Message = "prerequisites.ps1 ($ExitCode): localhost cannot connect to '$ListenerUrl`:8071'. please check your network for port 8071"
        Send-LogToLogzio $LogLevelError $Message $LogStepPrerequisites $LogScriptPrerequisites $FuncName $AgentId $Platfrom $Subtype
        Write-TaskPostRun "Write-Error '$Message'"

    }
    catch {
        $Message = "prerequisites.ps1 ($ExitCode): error testing network connection to '$ListenerUrl`:8071': $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepPrerequisites $LogScriptPrerequisites $FuncName $AgentId $Platfrom $Subtype
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
}

# Checks if localhost can connect to Logz.io metrics (port 8053)
# Input:
#   ---
# Ouput:
#   ---
function Test-CanLocalhostConnectToLogzioMetrics {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if localhost can connect to Logz.io metrics (port 8053) ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPrerequisites $LogScriptPrerequisites $FuncName $AgentId $Platfrom $Subtype
    Write-Log $LogLevelDebug $Message

    if ($FuncArgs.Count -eq 0) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platform $SubType
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('ListenerUrl')) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument does not contain 'ListenerUrl' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platform $SubType
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:ListenerUrl = $FuncArgs.ListenerUrl

    try {
        $local:Result = Test-NetConnection -ComputerName $ListenerUrl -Port 8053 -InformationLevel Quiet -ErrorAction Stop
        if ($Result) {
            return
        }

        $Message = "prerequisites.ps1 ($ExitCode): localhost cannot connect to '$ListenerUrl`:8053'. please check your network for port 8053"
        Send-LogToLogzio $LogLevelError $Message $LogStepPrerequisites $LogScriptAgent $FuncName $AgentId $Platfrom $Subtype
        Write-TaskPostRun "Write-Error '$Message'"

    }
    catch {
        $Message = "prerequisites.ps1 ($ExitCode): error testing network connection to '$ListenerUrl`:8053': $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepPrerequisites $LogScriptAgent $FuncName $AgentId $Platfrom $Subtype
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
}
