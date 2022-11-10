#################################################################################################################################
############################################ WINDOWS Subtype Post-Requisites Script #############################################
#################################################################################################################################

# Checks if all pods are running or completed
# Input:
#   ---
# Output:
#   AreAllPodsRunningOrCompleted - Tells if all pods are running or completed (true/false)
function Test-AreAllPodsRunningOrCompleted {
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if all pods are running or completed ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPostrequisites $script:LogScriptPostrequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    $local:Retries = 3
    while ($Retries -ne 0) {
        $local:PodStatuses = kubectl get pods -n monitoring --no-headers -o custom-columns=":.status.phase"
        $local:BadStatuses = $PodStatuses | Select-String -Pattern "Running|Completed|Succeeded" -NotMatch

        if ([string]::IsNullOrEmpty($BadStatuses)) {
            $Message = 'All pods are running or completed'
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPostrequisites $script:LogScriptPostrequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
            Write-Log $script:LogLevelDebug $Message

            Write-TaskPostRun "`$script:AreAllPodsRunningOrCompleted = `$true"
            return
        }

        Start-Sleep -Seconds 10
        $retries--
    }

    $Message = 'Not all pods are running or completed'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPostrequisites $script:LogScriptPostrequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:AreAllPodsRunningOrCompleted = `$false"
}

# Checks if any pod is pending
# Input:
#   ---
# Output:
#   ---
function Test-IsAnyPodPending {
    $local:ExitCode = 1
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if any pod is pending ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPostrequisites $script:LogScriptPostrequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    $local:Err = ''
    $local:Pods = kubectl get pods -n monitoring --no-headers -o custom-columns=":.metadata.name,:.status.phase" | ForEach-Object {$_ -replace '\s+', ' '}
    foreach ($Pod in $Pods) {
        $local:PodSplitted = ForEach-Object {$Pod -split ' '}
        $local:PodName = $PodSplitted[0]
        $local:PodStatus = $PodSplitted[1]

        if (-Not $PodStatus.Equals("Pending")) {
            continue
        }

        $local:EventReason = kubectl get event -n monitoring --field-selector involvedObject.name=$PodName --no-headers -o custom-columns=":.reason" | Select-Object -last 1 
        $local:EventMessage = kubectl get event -n monitoring --field-selector involvedObject.name=$PodName --no-headers -o custom-columns=":.message" | Select-Object -last 1 
        $Err += "`n'$PodName' pod status is 'Pending'. reason: $EventReason, message: $EventMessage"
    }

    if ([string]::IsNullOrEmpty($Err)) {
        $Message = 'No pod is pending'
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPostrequisites $script:LogScriptPostrequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-Log $script:LogLevelDebug $Message

        return
    }

    $script:IsPostrequisitesFailed = $true

    $Message = "postrequisites.ps1 ($ExitCode): found pending pods:$Err"
    Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPostrequisites $script:LogScriptPostrequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelError $Message

    Write-TaskPostRun "Write-Error `"$Message`""
    return $ExitCode
}

# Checks if any pod is failed
# Input:
#   ---
# Output:
#   ---
function Test-IsAnyPodFailed {
    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if any pod is failed ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPostrequisites $script:LogScriptPostrequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    $local:Err = ''
    $local:Pods = kubectl get pods -n monitoring --no-headers -o custom-columns=':.metadata.name,:.status.phase' | ForEach-Object {$_ -replace '\s+', ' '}
    foreach ($Pod in $Pods) {
        $local:PodSplitted = ForEach-Object {$Pod -split ' '}
        $local:PodName = $PodSplitted[0]
        $local:PodStatus = $PodSplitted[1]

        if (-Not $PodStatus.Equals('Running') -or -Not $PodStatus.Equals('Completed') -or -Not $PodStatus.Equals('Succeeded') -or -Not $PodStatus.Equals('Pending')) {
            continue
        }

        $Err += "'$PodName' pod status is '$PodStatus'"
    }

    if ([string]::IsNullOrEmpty($Err)) {
        $Message = 'No pod is failed'
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPostrequisites $script:LogScriptPostrequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-Log $script:LogLevelDebug $Message

        return
    }

    $script:IsPostrequisitesFailed = $true

    $Message = "postrequisites.ps1 ($ExitCode): found failed pods:$Err"
    Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPostrequisites $script:LogScriptPostrequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelError $Message

    Write-TaskPostRun "Write-Error `"$Message`""
    return $ExitCode
}
