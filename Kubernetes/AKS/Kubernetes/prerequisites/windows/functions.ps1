#################################################################################################################################
############################################### Prerequisites Windows Functions #################################################
#################################################################################################################################

# Checks if kubectl is installed
# Error:
#   Exit Code 1
function Test-IsKubectlInstalled {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Checking if kubectl is installed ..."

    Get-Command kubectl 2>&1 | Out-Null
    if ($?) {
        return
    }

    Write-Run "Write-Error `"prerequisites.ps1 (1): kubectl is not installed. please install it and rerun the agent script`""
    return 1
}

# Checks if kubectl is connected to an active Kubernetes cluster
# Error:
#   Exit Code 2
function Test-IsKubectlConnectedToKubernetesCluster {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Checking if kubectl is connected to an active Kubernetes cluster ..."

    $local:clusterInfo = kubectl cluster-info 2> $using:taskErrorFile
    $local:err = Get-Content $using:taskErrorFile
    if ([string]::IsNullOrEmpty($err)) {
        Write-Log "INFO" "$clusterInfo"
        return
    }

    Write-Run "Write-Error `"prerequisites.ps1 (2): kubectl is not connected to an active Kubernetes cluster. please configure your computer to access a Kubernetes cluster and rerun the agent script`n  $err`""
    return 2
}

# Deletes test pod from Kubernetes cluster
# Input:
#   podName - The name of the pod to delete
# Error:
#   Exit Code 3
function Remove-TestPod ([string]$podName) {
    kubectl delete pod logzio-logs-connection-test 2>$using:taskErrorFile | Out-Null
    if ($?) {
        return
    }

    $err = Get-Content $using:taskErrorFile
    Write-Run "Write-Warning `"prerequisites.ps1 (3): failed to delete logzio-logs-connection-test pod.`n  '$err'`""
}

# Checks if Kubernetes cluster can connect to Logz.io logs (port 8071)
# Error:
#   Exit Code 3
function Test-CanKubernetesClusterConnectToLogzioLogs {
    . $using:logzioTempDir\utils_functions.ps1
    . $using:logzioTempDir\prerequisites_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Checking if Kubernetes cluster can connect to Logz.io logs (port 8071) ..."

    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/prerequisites/logzio_logs_connection_test_pod.yaml -OutFile $using:logzioTempDir\logzio_logs_connection_test_pod.yaml | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"prerequisites.ps1 (3): failed to get logzio logs connection test pod yaml file from logzio-agent-manifest repo.`n  $_`""
        return 3
    }

    kubectl apply -f $using:logzioTempDir\logzio_logs_connection_test_pod.yaml 2>$using:taskErrorFile | Out-Null
    if (-Not $?) {
        $local:err = Get-Content $using:taskErrorFile
        Write-Run "Write-Error `"prerequisites.ps1 (3): failed to create logzio-logs-connection-test pod.`n  $err`""
        return 3
    }

    sleep 3

    $local:podLogs = kubectl logs logzio-logs-connection-test 2>$using:taskErrorFile
    $local:err = Get-Content $using:taskErrorFile
    if (-Not [string]::IsNullOrEmpty($result)) {
        Remove-TestPod "logzio-logs-connection-test"
        Write-Run "Write-Error `"prerequisites.ps1 (3): failed to get logs of logzio-logs-connection-test pod.`n  $err`""
        return 3
    }

    Write-Output $podLogs >> test.txt
    if ($podLogs = "Connected to listener.logz.io") {
        Remove-TestPod "logzio-logs-connection-test"
        return
    }

    Remove-TestPod "logzio-logs-connection-test"
    Write-Run "Write-Error `"prerequisites.ps1 (3): Kubernetes cluster cannot connect to Logz.io logs. please check your Kubernetes cluster network for port 8071`""
    return 3
}

# Checks if Kubernetes cluster can connect to Logz.io metrics (port 8053)
# Error:
#   Exit Code 3
function Test-CanKubernetesClusterConnectToLogzioMetrics {
    . $using:logzioTempDir\utils_functions.ps1
    . $using:logzioTempDir\prerequisites_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Checking if Kubernetes cluster can connect to Logz.io metrics (port 8053) ..."

    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/prerequisites/logzio_metrics_connection_test_pod.yaml -OutFile $using:logzioTempDir\logzio_metrics_connection_test_pod.yaml | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"prerequisites.ps1 (3): failed to get logzio metrics connection test pod yaml file from logzio-agent-manifest repo.`n  $_`""
        return 3
    }

    kubectl apply -f $using:logzioTempDir\logzio_metrics_connection_test_pod.yaml 2>$using:taskErrorFile | Out-Null
    if (-Not $?) {
        $local:err = Get-Content $using:taskErrorFile
        Write-Run "Write-Error `"prerequisites.ps1 (3): failed to create logzio-metrics-connection-test pod.`n  '$err'`""
        return 3
    }

    sleep 3

    $local:podLogs = kubectl logs logzio-metrics-connection-test 2>$using:taskErrorFile
    $local:err = Get-Content $using:taskErrorFile
    if (-Not [string]::IsNullOrEmpty($err)) {
        Remove-TestPod "logzio-metrics-connection-test"
        Write-Run "Write-Error `"prerequisites.ps1 (3): failed to get logs of logzio-metrics-connection-test pod.`n  '$err'`""
        return 3
    }

    if ($podLogs.Equals("Connected to listener.logz.io")) {
        Remove-TestPod "logzio-metrics-connection-test"
        return
    }

    Remove-TestPod "logzio-metrics-connection-test"
    Write-Run "Write-Error `"prerequisites.ps1 (3): Kubernetes cluster cannot connect to Logz.io metrics. please check your Kubernetes cluster network for port 8053`""
    return 3
}

# Checks if Helm is installed
# Error:
#   Exit Code 4
function Test-IsHelmInstalled {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Checking if Helm is installed ..."

    Get-Command helm 2>&1 | Out-Null
    if ($?) {
        return
    }

    $local:result = Install-Chocolatey
    if (-Not [string]::IsNullOrEmpty($result) -and $result -gt 0) {
        return 4
    }

    Write-Log "INFO" "Installing Helm ..."
    choco install kubernetes-helm -y 2>$using:taskErrorFile | Out-Null
    if ($?) {
        return
    }

    $local:err = Get-Content $using:taskErrorFile
    Write-Run "Write-Error `"prerequisites.ps1 (4): failed to install Helm.`n  $err`""
    return 4
}

# Adds Logz.io Helm repo
# Error:
#   Exit Code 5
function Add-LogzioHelmRepo {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Adding Logz.io Helm repo ..."

    helm repo add logzio-helm https://logzio.github.io/logzio-helm 2>$using:taskErrorFile | Out-Null
    if ($?) {
        return
    }

    $local:err = Get-Content $using:taskErrorFile
    Write-Run "Write-Error `"prerequisites.ps1 (5): failed to add Logz.io Helm repo.`n  $err`""
    return 5
}

# Updates Logz.io Helm repo
# Error:
#   Exit Code 6
function Update-LogzioHelmRepo {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Updating Logz.io Helm repo ..."
    
    helm repo update logzio-helm 2>$using:taskErrorFile | Out-Null
    if ($?) {
        return
    }

    $local:err = Get-Content $using:taskErrorFile
    Write-Run "Write-Error `"prerequisites.ps1 (6): failed to update Logz.io Helm repo.`n  $err`""
    return 6
}
