#################################################################################################################################
############################################## Postrequisites Windows Functions #################################################
#################################################################################################################################

# Checks if all pods are running or completed 
# Output:
#   areAllPodsRunningOrCompleted - Tells if all pods are running or completed (true/false)
function Test-AreAllPodsRunningOrCompleted {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    $local:retries = 0
    while ($retries -lt 3) {
        $retries++
        $local:isAnyPodWithBadStatus = $false
        $local:podStatuses = kubectl -n monitoring get pods --no-headers -o custom-columns=":.status.phase"
        $local:isAnyPodWithBadStatus = $podStatuses | Select-String -Pattern "Running|Completed|Succeeded" -NotMatch
        if ([string]::IsNullOrEmpty($isAnyPodWithBadStatus)) {
            Write-Log "INFO" "areAllPodsRunningOrCompleted = true"
            Write-Run "`$script:areAllPodsRunningOrCompleted = `$true"
            return
        }

        sleep 5
    }

    Write-Log "INFO" "areAllPodsRunningOrCompleted = false"
    Write-Run "`$script:areAllPodsRunningOrCompleted = `$false"
}

# Checks if any pod is pending
# Output:
#   isAnyPodPending - Tells if any pod is pending (true/false)
function Test-IsAnyPodPending {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    $local:err = ""
    $local:pods = kubectl -n monitoring get pods --no-headers -o custom-columns=":.metadata.name,:.status.phase" | ForEach-Object {$_ -replace '\s+', ' '}
    foreach ($pod in $pods) {
        $local:podSplitted = ForEach-Object {$pod -split " "}
        $local:podName = $podSplitted[0]
        $local:podStatus = $podSplitted[1]

        if (-Not $podStatus.Equals("Pending")) {
            continue
        }

        $local:eventReason = kubectl get event -n monitoring --field-selector involvedObject.name=$podName --no-headers -o custom-columns=":.reason" | Select-Object -last 1 
        $local:eventMessage = kubectl get event -n monitoring --field-selector involvedObject.name=$podName --no-headers -o custom-columns=":.message" | Select-Object -last 1 
        $err += "`n  pod $podName status is Pending. reason: $eventReason, message: $eventMessage"
    }

    if ([string]::IsNullOrEmpty($err)) {
        Write-Log "INFO" "isAnyPodPending = false"
        Write-Run "`$script:isAnyPodPending = `$false"
        return
    }

    Write-Log "INFO" "isAnyPodPending = true"
    Write-Run "`$script:isAnyPodPending = `$true"
    Write-Run "Write-Error `"found pending pods:$err`""
}

# Checks if any pod is failed
# Output:
#   isAnyPodFailed - Tells if any pod is failed (true/false)
function Test-IsAnyPodFailed () {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    $local:err = ""
    $local:pods = kubectl -n monitoring get pods --no-headers -o custom-columns=":.metadata.name,:.status.phase" | ForEach-Object {$_ -replace '\s+', ' '}
    foreach ($pod in $pods) {
        $local:podSplitted = ForEach-Object {$pod -split " "}
        $local:podName = $podSplitted[0]
        $local:podStatus = $podSplitted[1]

        if (-Not $podStatus.Equals("Running") -or -Not $podStatus.Equals("Completed") -or -Not $podStatus.Equals("Succeeded") -or -Not $podStatus.Equals("Pending")) {
            continue
        }

        $err += "`n  pod $podName status is $podStatus"
    }

    if ([string]::IsNullOrEmpty($err)) {
        Write-Log "INFO" "isAnyPodFailed = false"
        Write-Run "`$isAnyPodFailed = `$false"
        return
    }

    Write-Log "INFO" "isAnyPodFailed = true"
    Write-Run "`$isAnyPodFailed = `$true"
    Write-Run "Write-Error `"found failed pods (run kubectl -n monitorin logs <<POD_NAME>> to see why):$err`""
}
