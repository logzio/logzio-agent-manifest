#################################################################################################################################
############################################# WINDOWS Subtype Prerequisites Script ##############################################
#################################################################################################################################

# Checks if localhost can connect to Logz.io logs (port 8071)
# Input:
#   ---
# Output:
#   ---
function Test-CanLocalhostConnectToLogzioLogs {
    $local:ExitCode = 1
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if localhost can connect to Logz.io logs (port 8071) ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPrerequisites $LogScriptPrerequisites $FuncName $AgentId $Platfrom $Subtype
    Write-Log $LogLevelDebug $Message

    $local:LogzioListenerUrl = &$JqExe -r .listenerUrl $AppJson 2>$TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        $Message = "prerequisites.ps1 ($ExitCode): error getting listener url from application json: $(Get-Content -Path $TaskErrorFile)"
        Send-LogToLogzio $LogLevelError $Message $LogStepPrerequisites $LogScriptPrerequisites $FuncName $AgentId $Platfrom $Subtype
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    try {
        $local:Result = Test-NetConnection -ComputerName $LogzioListenerUrl -Port 8071 -InformationLevel Quiet -ErrorAction Stop
        if ($Result) {
            return
        }

        $Message = "prerequisites.ps1 ($ExitCode): localhost cannot connect to '$LogzioListenerUrl`:8071'. please check your network for port 8071"
        Send-LogToLogzio $LogLevelError $Message $LogStepPrerequisites $LogScriptPrerequisites $FuncName $AgentId $Platfrom $Subtype
        Write-TaskPostRun "Write-Error '$Message'"

    }
    catch {
        $Message = "prerequisites.ps1 ($ExitCode): error testing network connection to '$LogzioListenerUrl`:8071': $_"
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
    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if localhost can connect to Logz.io metrics (port 8053) ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPrerequisites $LogScriptPrerequisites $FuncName $AgentId $Platfrom $Subtype
    Write-Log $LogLevelDebug $Message

    $local:LogzioListenerUrl = &$JqExe -r .listenerUrl $AppJson 2>$TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        $Message = "prerequisites.ps1 ($ExitCode): error getting listener url from application json: $(Get-Content -Path $TaskErrorFile)"
        Send-LogToLogzio $LogLevelError $Message $LogStepPrerequisites $LogScriptPrerequisites $FuncName $AgentId $Platfrom $Subtype
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    try {
        $local:Result = Test-NetConnection -ComputerName $LogzioListenerUrl -Port 8053 -InformationLevel Quiet -ErrorAction Stop
        if ($Result) {
            return
        }

        $Message = "prerequisites.ps1 ($ExitCode): localhost cannot connect to '$LogzioListenerUrl`:8053'. please check your network for port 8053"
        Send-LogToLogzio $LogLevelError $Message $LogStepPrerequisites $LogScriptAgent $FuncName $AgentId $Platfrom $Subtype
        Write-TaskPostRun "Write-Error '$Message'"

    }
    catch {
        $Message = "prerequisites.ps1 ($ExitCode): error testing network connection to '$LogzioListenerUrl`:8053': $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepPrerequisites $LogScriptAgent $FuncName $AgentId $Platfrom $Subtype
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
}
