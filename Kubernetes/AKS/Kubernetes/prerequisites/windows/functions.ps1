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

    Write-Run "Write-Error `"prerequisites.ps1 (1): kubectl is not installed`""
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

    kubectl cluster-info > $using:taskResultFile 2>&1
    if ($?) {
        $local:result = Get-Content $using:taskResultFile
        Write-Log "INFO" "$result"
        return
    }

    $local:result = Get-Content $using:taskResultFile
    $result = $result[0..($result.length-7)]
    Write-Run "Write-Error `"prerequisites.ps1 (2): kubectl is not connected to an active Kubernetes cluster. $result`""
    return 2
}

# Checks if Kubernetes cluster can connect to Logz.io logs (port 8071)
# Error:
#   Exit Code 3
function Test-CanKubernetesClusterConnectToLogzioLogs {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Checking if Kubernetes cluster can connect to Logz.io logs (port 8071) ..."

    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/prerequisites/logzio_logs_connection_test_pod.yaml -OutFile $using:logzioTempDir\logzio_logs_connection_test_pod.yaml | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"prerequisites.ps1 (3): failed to get logzio logs connection test pod yaml file from logzio-agent-manifest repo. $_`""
        return 3
    }

    kubectl apply -f $using:logzioTempDir\logzio_logs_connection_test_pod.yaml 2>$using:taskResultFile | Out-Null
    if (-Not $?) {
        $local:result = Get-Content $using:taskResultFile
        $result = $result[0..($result.length-7)]
        Write-Run "Write-Error `"prerequisites.ps1 (3): failed to create logzio-logs-connection-test pod. $result`""
        return 3
    }

    sleep 3

    $local:podLogs = kubectl logs logzio-logs-connection-test 2>$using:taskResultFile
    $local:result = Get-Content $using:taskResultFile
    if (-Not [string]::IsNullOrEmpty($result)) {
        $result = $result[0..($result.length-7)]
        Write-Run "Write-Error `"prerequisites.ps1 (3): failed to get logs of logzio-logs-connection-test pod. $result`""
        return 3
    }

    if ($podLogs = "Connected to listener.logz.io") {
        kubectl delete pod logzio-logs-connection-test 2>$using:taskResultFile | Out-Null
        if ($?) {
            return
        }
        
        $result = Get-Content $using:taskResultFile
        $result = $result[0..($result.length-7)]
        Write-Run "Write-Warning `"prerequisites.ps1 (3): failed to delete logzio-logs-connection-test pod. $result`""
        return
    }

    kubectl delete pod logzio-logs-connection-test 2>$using:taskResultFile | Out-Null
    if (-Not $?) {
        $result = Get-Content $using:taskResultFile
        $result = $result[0..($result.length-7)]
        Write-Run "Write-Warning `"prerequisites.ps1 (3): failed to delete logzio-logs-connection-test pod. $result`""
    }

    Write-Log "Write-Error `"prerequisites.ps1 (3): Kubernetes cluster cannot connect to Logz.io logs (port 8071)`""
    return 3
}

# Checks if Kubernetes cluster can connect to Logz.io metrics (port 8053)
# Error:
#   Exit Code 3
function Test-CanKubernetesClusterConnectToLogzioMetrics {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Checking if Kubernetes cluster can connect to Logz.io metrics (port 8053) ..."

    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/prerequisites/logzio_metrics_connection_test_pod.yaml -OutFile $using:logzioTempDir\logzio_metrics_connection_test_pod.yaml | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"prerequisites.ps1 (3): failed to get logzio metrics connection test pod yaml file from logzio-agent-manifest repo. $_`""
        return 3
    }

    kubectl apply -f $using:logzioTempDir\logzio_metrics_connection_test_pod.yaml 2>$using:taskResultFile | Out-Null
    if (-Not $?) {
        $local:result = Get-Content $using:taskResultFile
        $result = $result[0..($result.length-7)]
        Write-Run "Write-Error `"prerequisites.ps1 (3): failed to create logzio-metrics-connection-test pod. $result`""
        return 3
    }

    sleep 3

    $local:podLogs = kubectl logs logzio-metrics-connection-test 2>$using:taskResultFile
    $local:result = Get-Content $using:taskResultFile
    if (-Not [string]::IsNullOrEmpty($result)) {
        $result = $result[0..($result.length-7)]
        Write-Run "Write-Error `"prerequisites.ps1 (3): failed to get logs of logzio-metrics-connection-test pod. $result`""
        return 3
    }

    if ($podLogs = "Connected to listener.logz.io") {
        kubectl delete pod logzio-logs-connection-test 2>$using:taskResultFile | Out-Null
        if ($?) {
            return
        }
        
        $result = Get-Content $using:taskResultFile
        $result = $result[0..($result.length-7)]
        Write-Run "Write-Warning `"prerequisites.ps1 (3): failed to delete logzio-metrics-connection-test pod. $result`""
        return
    }

    kubectl delete pod logzio-metrics-connection-test 2>$using:taskResultFile | Out-Null
    if (-Not $?) {
        $result = Get-Content $using:taskResultFile
        $result = $result[0..($result.length-7)]
        Write-Run "Write-Warning `"prerequisites.ps1 (3): failed to delete logzio-metrics-connection-test pod. $result`""
    }

    Write-Log "Write-Error `"prerequisites.ps1 (3): Kubernetes cluster cannot connect to Logz.io metrics (port 8053)`""
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
        choco upgrade kubernetes-helm -y 2>$using:taskResultFile | Out-Null
        if ($?) {
            return
        }
        
        $local:result = Get-Content $using:taskResultFile
        $result = $result[0..($result.length-7)]
        Write-Run "Write-Error `"prerequisites.ps1 (4): failed to upgrade Helm. $result`""
        return 4
    }

    Write-Log "INFO" "Installing Helm ..."
    choco install kubernetes-helm -y 2>$using:taskResultFile | Out-Null
    if ($?) {
        return
    }

    $local:result = Get-Content $using:taskResultFile
    $result = $result[0..($result.length-7)]
    Write-Run "Write-Error `"prerequisites.ps1 (4): failed to install Helm. $result`""
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

    helm repo add logzio-helm https://logzio.github.io/logzio-helm 2>$using:taskResultFile | Out-Null
    if ($?) {
        return
    }

    $local:result = Get-Content $using:taskResultFile
    $result = $result[0..($result.length-7)]
    Write-Run "Write-Error `"prerequisites.ps1 (5): failed to add Logz.io Helm repo. $result`""
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
    
    helm repo update logzio-helm 2>$using:taskResultFile | Out-Null
    if ($?) {
        return
    }

    $local:result = Get-Content $using:taskResultFile
    $result = $result[0..($result.length-7)]
    Write-Run "Write-Error `"prerequisites.ps1 (6): failed to update Logz.io Helm repo. $result`""
    return 6
}
