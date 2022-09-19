#################################################################################################################################
################################################ Postrequisites Windows Script ##################################################
#################################################################################################################################

# Load functions
Write-Log "INFO" "Loading postrequisites functions ..."
. $logzioTempDir\postrequisites_functions.ps1

# Check if all pods are running or completed
Invoke-Task "Test-AreAllPodsRunningOrCompleted" "checking if all pods are running or completed"

if (-Not $areAllPodsRunningOrCompleted) {
    # Check if any pod is pending
    Invoke-Task "Test-IsAnyPodPending" "checking if any pod is pending"
    # Check if any pod is failed
    Invoke-Task "Test-IsAnyPodFailed" "checking if any pod is failed"
}

# Finished successfully
Exit 0
