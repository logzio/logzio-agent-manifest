#################################################################################################################################
############################################# WINDOWS Subtype Prerequisites Script ##############################################
#################################################################################################################################

# Checks if kubectl is installed
# Input:
#   ---
# Output:
#   ---
function Test-IsKubectlInstalled {
    $local:ExitCode = 1
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if kubectl is installed ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message
    
    try {
        Get-Command kubectl -ErrorAction Stop | Out-Null
    }
    catch {
        $Message = "prerequisites.ps1 ($ExitCode): 'kubectl' is not installed. please install it and rerun the agent"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Checks if kubectl is connected to an active Kubernetes cluster
# Input:
#   ---
# Output:
#   ---
function Test-IsKubectlConnectedToKubernetesCluster {
    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if kubectl is connected to an active Kubernetes cluster ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    $local:ClusterInfo = kubectl cluster-info 2>$script:TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        $Message = "prerequisites.ps1 ($ExitCode): kubectl is not connected to an active Kubernetes cluster. please configure your computer to access a Kubernetes cluster and rerun the agent: $(Get-TaskErrorMessage)"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $Message = "Kubernetes cluster info: $ClusterInfo"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message
}

# Sets Logz.io listener url in test pod yamls
# Input:
#   FuncArgs - Hashtable {ListenerUrl = $script:ListenerUrl}
# Output:
#   ---
function Set-LogzioListenerUrlInTestPodYamls {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Setting Logz.io listener url in test pod yamls ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('ListenerUrl')
    if ($Err.Count -ne 0) {
        $Message = "prerequisites.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:ListenerUrl = $FuncArgs.ListenerUrl

    $Err = Add-YamlFileFieldValue "$script:KubernetesResourcesDir\logzio_logs_connection_test_pod.yaml" '.spec.containers[0].command' "telnet $ListenerUrl 8071"
    if ($Err.Count -ne 0) {
        $Message = "prerequisites.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $Err = Add-YamlFileFieldValue "$script:KubernetesResourcesDir\logzio_metrics_connection_test_pod.yaml" '.spec.containers[0].command' "telnet $ListenerUrl 8053"
    if ($Err.Count -ne 0) {
        $Message = "prerequisites.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Checks if Kubernetes cluster can connect to Logz.io logs (port 8071)
# Input:
#   FuncArgs - Hashtable {ListenerUrl = $script:ListenerUrl}
# Output:
#   ---
function Test-CanKubernetesClusterConnectToLogzioLogs {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 4
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if Kubernetes cluster can connect to Logz.io logs (port 8071) ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('ListenerUrl')
    if ($Err.Count -ne 0) {
        $Message = "prerequisites.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:ListenerUrl = $FuncArgs.ListenerUrl

    kubectl apply -f $script:KubernetesResourcesDir\logzio_logs_connection_test_pod.yaml 2>$script:TaskErrorFile | Out-Null
    if ($LASTEXITCODE -ne 0) {
        $Message = "prerequisites.ps1 ($ExitCode): error creating 'logzio-logs-connection-test' pod: $(Get-TaskErrorMessage)"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:IsPodCompleted = $false
    $local:Retries = 18
    while ($Retries -ne 0) {
        $local:Pod = kubectl get pods 2>$script:TaskErrorFile | Select-String -Pattern 'logzio-logs-connection-test' | ForEach-Object {$_  -replace '\s+', ' '} | ForEach-Object {$_ -split ' '}
        if ($LASTEXITCODE -ne 0) {
            $Message = "prerequisites.ps1 ($ExitCode): error getting pods: $(Get-TaskErrorMessage)"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
            Write-TaskPostRun "Write-Error `"$Message`""
    
            return $ExitCode
        }
        
        $local:PodStatus = $Pod[2]

        if ($PodStatus.Equals('Completed')) {
            $IsPodCompleted = $true
            break
        }

        Start-Sleep -Seconds 10
        $Retries--
    }

    if (-Not $IsPodCompleted) {
        $local:PodLogs = kubectl logs logzio-logs-connection-test 2>$script:TaskErrorFile
        if ($LASTEXITCODE -ne 0) {
            $Message = "prerequisites.ps1 ($ExitCode): error getting logs of 'logzio-logs-connection-test' pod: $(Get-TaskErrorMessage)"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
            Write-TaskPostRun "Write-Error `"$Message`""
        }

        Remove-TestPod 'logzio-logs-connection-test'
        
        $Message = "prerequisites.ps1 ($ExitCode): pod 'logzio-logs-connection-test' was not completed. pod status is '$PodStatus': $PodLogs"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:PodLogs = kubectl logs logzio-logs-connection-test 2>$script:TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        $Message = "prerequisites.ps1 ($ExitCode): error getting logs of 'logzio-logs-connection-test' pod: $(Get-TaskErrorMessage)"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    Remove-TestPod 'logzio-logs-connection-test'

    if (-Not $PodLogs.Equals("Connected to $ListenerUrl")) {
        $Message = "prerequisites.ps1 ($ExitCode): Kubernetes cluster cannot connect to Logz.io logs. please check your Kubernetes cluster network for port 8071"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Checks if Kubernetes cluster can connect to Logz.io metrics (port 8053)
# Input:
#   FuncArgs - Hashtable {ListenerUrl = $script:ListenerUrl}
# Output:
#   ---
function Test-CanKubernetesClusterConnectToLogzioMetrics {
    param (
        [hashtable]$FuncArgs
    )
    
    $local:ExitCode = 5
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if Kubernetes cluster can connect to Logz.io metrics (port 8053) ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('ListenerUrl')
    if ($Err.Count -ne 0) {
        $Message = "prerequisites.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:ListenerUrl = $FuncArgs.ListenerUrl

    kubectl apply -f $script:KubernetesResourcesDir\logzio_metrics_connection_test_pod.yaml 2>$script:TaskErrorFile | Out-Null
    if ($LASTEXITCODE -ne 0) {
        $Message = "prerequisites.ps1 ($ExitCode): error creating 'logzio-metrics-connection-test' pod: $(Get-TaskErrorMessage)"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:IsPodCompleted = $false
    $local:Retries = 18
    while ($Retries -ne 0) {
        $local:Pod = kubectl get pods 2>$script:TaskErrorFile | Select-String -Pattern 'logzio-metrics-connection-test' | ForEach-Object {$_  -replace '\s+', ' '} | ForEach-Object {$_ -split ' '}
        if ($LASTEXITCODE -ne 0) {
            $Message = "prerequisites.ps1 ($ExitCode): error getting pods: $(Get-TaskErrorMessage)"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
            Write-TaskPostRun "Write-Error `"$Message`""
    
            return $ExitCode
        }

        $local:PodStatus = $Pod[2]

        if ($PodStatus.Equals('Completed')) {
            $IsPodCompleted = $true
            break
        }

        Start-Sleep -Seconds 10
        $Retries--
    }

    if (-Not $IsPodCompleted) {
        $local:PodLogs = kubectl logs logzio-metrics-connection-test 2>$script:TaskErrorFile
        if ($LASTEXITCODE -ne 0) {
            $Message = "prerequisites.ps1 ($ExitCode): error getting logs of 'logzio-metrics-connection-test' pod: $(Get-TaskErrorMessage)"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
            Write-TaskPostRun "Write-Error `"$Message`""
        }

        Remove-TestPod 'logzio-metrics-connection-test'
        
        $Message = "prerequisites.ps1 ($ExitCode): pod 'logzio-metrics-connection-test' was not completed. pod status is '$PodStatus': $PodLogs"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:PodLogs = kubectl logs logzio-metrics-connection-test 2>$script:TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        $Message = "prerequisites.ps1 ($ExitCode): error getting logs of 'logzio-metrics-connection-test' pod: $(Get-TaskErrorMessage)"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    Remove-TestPod 'logzio-metrics-connection-test'

    if (-Not $PodLogs.Equals("Connected to $ListenerUrl")) {
        $Message = "prerequisites.ps1 ($ExitCode): Kubernetes cluster cannot connect to Logz.io metrics. please check your Kubernetes cluster network for port 8053"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Deletes test pod from Kubernetes cluster
# Input:
#   PodName - The name of the pod to delete
# Output:
#   ---
function Remove-TestPod {
    param (
        [string]$PodName
    )

    kubectl delete pod $PodName 2>$script:TaskErrorFile | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-TaskPostRun "Write-Warning `"failed to delete '$PodName' pod: $(Get-TaskErrorMessage)`""
    }
}

# Checks if Helm is installed and installs Helm if not installed
# Input:
#   ---
# Output:
#   ---
function Test-IsHelmInstalled {
    $local:ExitCode = 6
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if Helm is installed ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    try {
        Get-Command helm -ErrorAction Stop | Out-Null

        $Message = 'Helm is installed'
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-Log $script:LogLevelDebug $Message
    }
    catch {
        $local:Message = 'Helm is not installed. Installing Helm ...'
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-Log $script:LogLevelDebug $Message

        $local:Err = Install-Chocolatey
        if ($Err.Count -ne 0) {
            $Message = "prerequisites.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        choco install kubernetes-helm -y 2>$script:TaskErrorFile | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $Message = "prerequisites.ps1 ($ExitCode): error install Helm. please run 'choco install kubernetes-helm', open a new PowerShell and rerun the agent: $(Get-TaskErrorMessage)"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }
    }
}

# Adds Logz.io Helm repo
# Input:
#   ---
# Output:
#   ---
function Add-LogzioHelmRepo {
    $local:ExitCode = 7
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Adding Logz.io Helm repo ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    helm repo add logzio-helm https://logzio.github.io/logzio-helm 2>$script:TaskErrorFile | Out-Null
    if ($LASTEXITCODE -ne 0) {
        $Message = "prerequisites.ps1 ($ExitCode): error adding Logz.io Helm repo: $(Get-TaskErrorMessage)"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Updates Logz.io Helm repo
# Input:
#   ---
# Output:
#   ---
function Update-LogzioHelmRepo {
    $local:ExitCode = 8
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Updating Logz.io Helm repo ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message
    
    helm repo update 2>$script:TaskErrorFile | Out-Null
    if ($LASTEXITCODE -ne 0) {
        $Message = "prerequisites.ps1 ($ExitCode): error updating Logz.io Helm repo: $(Get-TaskErrorMessage)"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPrerequisites $script:LogScriptPrerequisites $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}
