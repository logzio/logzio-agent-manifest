#################################################################################################################################
#################################################### WINDOWS Metrics Script #####################################################
#################################################################################################################################

# Builds Windows node username and password Helm sets (if Kubernetes runs on Windows OS)
# Input:
#   ---
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   HelmSets - Contains all the Helm sets
function Build-WindowsNodeUsernameAndPasswordHelmSets {
    Write-Host 'Please enter your Windows Node username: ' -ForegroundColor Magenta -NoNewline
    $local:Username = Read-Host
    Write-Host 'Please enter your Windows Node password: ' -ForegroundColor Magenta -NoNewline
    $local:SecuredPassword = Read-Host -AsSecureString
    $local:Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecuredPassword))

    $local:WindowsUsernameHelmSet = " --set logzio-k8s-telemetry.secrets.windowsNodeUsername=$Username"
    $local:WindowsPasswordHelmSet = " --set logzio-k8s-telemetry.secrets.windowsNodePassword="
    $local:PasswordFirstChar = $Password[0]
    $local:passwordLastChar = $Password[$Password.Length-1]
    $local:LogPassword = "$PasswordFirstChar*****$PasswordLastChar"

    $local:Message = "Windows node username and password Helm sets are '$WindowsUsernameHelmSet$WindowsPasswordHelmSet$LogPassword'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepMetrics $script:LogScriptMetrics $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    $script:LogHelmSets += "$WindowsUsernameHelmSet$WindowsPasswordHelmSet$LogPassword"
    $script:HelmSets += "$WindowsUsernameHelmSet$WindowsPasswordHelmSet$Password"
}


$local:MetricsFunctionsScript = "$script:LogzioTempDir\$script:Platform\$script:SubType\$($script:CurrentDataSource.ToLower())\$script:MetricsFunctionsFile"

# Print headline
Write-Host
Write-Host '###############'
Write-Host '### ' -NoNewline
Write-Host 'Metrics' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '###############'

# Get Logz.io metrics token
Invoke-Task 'Get-LogzioMetricsToken' @{} 'Getting Logz.io metrics token' @($MetricsFunctionsScript)
# Build enable metrics Helm set
Invoke-Task 'Build-EnableMetricsHelmSet' @{} 'Building enable metrics Helm set' @($MetricsFunctionsScript)
# Build Logz.io metrics listener URL Helm set
Invoke-Task 'Build-LogzioMetricsListenerUrlHelmSet' @{ListenerUrl = $script:ListenerUrl} 'Building Logz.io metrics listener URL Helm set' @($MetricsFunctionsScript)
# Build Logz.io metrics token Helm set
Invoke-Task 'Build-LogzioMetricsTokenHelmSet' @{MetricsToken = $script:MetricsToken} 'Building Logz.io metrics token Helm set' @($MetricsFunctionsScript)
# Get if Kubernetes runs on Windows OS option was selected
Invoke-Task 'Get-IsKubernetesRunOnWindowsOsSelected' @{MetricsParams = $script:MetricsParams} 'Getting if Kubernetes runs on Windows OS option was selected' @($MetricsFunctionsScript)
if ($script:IsWindows) {
    # Build Windows node username and password Helm sets
    Build-WindowsNodeUsernameAndPasswordHelmSets
}
# Get if metrics filter option was selected
Invoke-Task 'Get-IsMetricsFilterWasSelected' @{MetricsParams = $script:MetricsParams} 'Getting if metrics filter was selected' @($MetricsFunctionsScript)
if ($script:IsFilter) {
    # Build enable metrics filter Helm set
    Invoke-Task 'Build-EnableMetricsFilterHelmSet' @{} 'Building enable metrics filter Helm set' @($MetricsFunctionsScript)
}
# Get if Kubernetes object logs option was selected
Invoke-Task 'Get-IsObjectLogsWasSelected' @{MetricsParams = $script:MetricsParams} 'Getting if Kubernetes object logs was selected' @($MetricsFunctionsScript)
if ($script:IsObjectLogs) {
    # Build enable Kubernetes object logs Helm set
    Invoke-Task 'Build-EnableObjectLogsHelmSet' @{} 'Building enable Kubernetes object logs Helm set' @($MetricsFunctionsScript)
    # Get Logz.io Kubernetes object logs token
    Invoke-Task 'Get-LogzioObjectLogsToken' @{} 'Getting Logz.io Kubernetes object logs token' @($MetricsFunctionsScript)
    # Build Logz.io Kubernetes object logs token Helm set
    Invoke-Task 'Build-LogzioObjectLogsTokenHelmSet' @{ObjectLogsToken = $script:ObjectLogsToken} 'Building Logz.io Kubernetes object logs token Helm set' @($MetricsFunctionsScript)
    # Build Logz.io region Helm set
    Invoke-Task 'Build-LogzioRegionHelmSet' @{ListenerUrl = $script:ListenerUrl} 'Building Logz.io region Helm set' @($MetricsFunctionsScript)
}

# Finished successfully
Exit 0
