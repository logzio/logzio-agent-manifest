#################################################################################################################################
############################################ WINDOWS Subtype Post-Requisites Script #############################################
#################################################################################################################################

$local:PostrequisitesScriptFile = "$LogzioTempDir\$Platform\$SubType\$PostrequisitesFunctionsFile"

# Print title
Write-Host
Write-Host '#######################'
Write-Host '### ' -NoNewline
Write-Host 'Post-Requisites' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '#######################'

# Check if all pods are running or completed
Invoke-Task 'Test-AreAllPodsRunningOrCompleted' @{} 'Checking if all pods are running or completed' @($PostrequisitesScriptFile)
if (-Not $script:AreAllPodsRunningOrCompleted) {
    # Check if any pod is pending
    Invoke-Task 'Test-IsAnyPodPending' @{} 'Checking if any pod is pending' @($PostrequisitesScriptFile)
    # Check if any pod is failed
    Invoke-Task 'Test-IsAnyPodFailed' @{} 'Checking if any pod is failed' @($PostrequisitesScriptFile)

    if ($script:IsPostrequisitesFailed) {
        Exit 3
    }
}

# Finished successfully
Exit 0
