#################################################################################################################################
################################################ Postrequisites Windows Script ##################################################
#################################################################################################################################

# Load functions
Write-Log "INFO" "Loading postrequisites functions ..."
. $logzioTempDir\postrequisites_functions.ps1

# Check if all pods are running or completed
Invoke-Task "are_all_pods_running_or_completed" "checking if all pods are running or completed"

if ($areAllPodsRunningOrCompleted) {
    # Check if any pod is pending
    Invoke-Task "is_any_pod_pending" "checking if any pod is pending"
    # Check if any pod is failed
    Invoke-Task "is_any_pod_failed" "checking if any pod is failed"
}

# Finished successfully
Exit 0
