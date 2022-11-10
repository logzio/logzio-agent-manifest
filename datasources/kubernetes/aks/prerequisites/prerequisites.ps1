#################################################################################################################################
############################################# WINDOWS Subtype Prerequisites Script ##############################################
#################################################################################################################################

$local:PrerequisitesScriptFile = "$LogzioTempDir\$Platform\$SubType\$PrerequisitesFunctionsFile"

# Print title
Write-Host
Write-Host '#####################'
Write-Host '### ' -NoNewline
Write-Host 'Prerequisites' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '#####################'

# Check if kubectl is installed
Invoke-Task 'Test-IsKubectlInstalled' @{} 'Checking if kubectl is installed' @($PrerequisitesScriptFile)
# Check if kubectl is connected to an active Kubernetes cluster
Invoke-Task 'Test-IsKubectlConnectedToKubernetesCluster' @{} 'Checking if kubectl is connected to Kubernetes cluster' @($PrerequisitesScriptFile)
# Set Logz.io listener url in test pod yamls
Invoke-Task 'Set-LogzioListenerUrlInTestPodYamls' @{ListenerUrl = $script:ListenerUrl} 'Setting Logz.io listener url in test pod yamls' @($PrerequisitesScriptFile)
# Check if Kubernetes cluster can connect to Logz.io logs (port 8071)
Invoke-Task 'Test-CanKubernetesClusterConnectToLogzioLogs' @{ListenerUrl = $script:ListenerUrl} 'Checking if Kubernetes cluster can connect to Logz.io logs' @($PrerequisitesScriptFile)
# Check if Kubernetes cluster can connect to Logz.io metrics (port 8053)
Invoke-Task 'Test-CanKubernetesClusterConnectToLogzioMetrics' @{ListenerUrl = $script:ListenerUrl} 'Checking if Kubernetes cluster can connect to Logz.io metrics' @($PrerequisitesScriptFile)
# Check if Helm is installed and install Helm if not installed
Invoke-Task "Test-IsHelmInstalled" @{} 'Checking if Helm is installed' @($PrerequisitesScriptFile)
# Add Logz.io Helm repo
Invoke-Task 'Add-LogzioHelmRepo' @{} 'Adding Logz.io Helm repo' @($PrerequisitesScriptFile)
# Update Logz.io Helm repo
Invoke-Task 'Update-LogzioHelmRepo' @{} 'Updating Logz.io Helm repo' @($PrerequisitesScriptFile)

# Finished successfully
Exit 0
