#################################################################################################################################
################################################# Prerequisites Windows Script ##################################################
#################################################################################################################################

# Load functions
Write-Log "INFO" "Loading prerequisites functions ..."
. $logzioTempDir\prerequisites_functions.ps1

# Check if kubectl is installed
Invoke-Task "Test-IsKubectlInstalled" "checking if kubectl is installed"

# Check if kubectl is connected to an active Kubernetes cluster
Invoke-Task "Test-IsKubectlConnectedToKubernetesCluster" "checking if kubectl is connected to Kubernetes cluster"

# Check if Kubernetes cluster can connect to Logz.io logs (port 8071)
Invoke-Task "Test-CanKubernetesClusterConnectToLogzioLogs" "checking if Kubernetes cluster can connect to Logz.io logs"

# Check if Kubernetes cluster can connect to Logz.io metrics (port 8053)
Invoke-Task "Test-CanKubernetesClusterConnectToLogzioMetrics" "checking if Kubernetes cluster can connect to Logz.io metrics"

<#
# Check if Helm is installed
execute_task "is_helm_installed" "checking if Helm is installed"

# Add Logz.io Helm repo
execute_task "add_logzio_helm_repo" "adding Logz.io Helm repo"

# Update Logz.io Helm repo
execute_task "update_logzio_helm_repo" "updating Logz.io Helm repo"#>