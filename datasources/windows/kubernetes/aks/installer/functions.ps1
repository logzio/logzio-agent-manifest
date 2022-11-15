#################################################################################################################################
############################################# WINDOWS Subtype Installer Functions ###############################################
#################################################################################################################################

# Checks if Logz.io Helm exists
# Input:
#   ---
# Output:
#   IsHelmExist - Tells if Logz.io Helm exists (true/false)
function Get-IsLogzioHelmExist {
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if Logz.io Helm exists ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $LogLevelDebug $Message

    $local:Result = helm status logzio-monitoring -n monitoring 2>$null
    if ([string]::IsNullOrEmpty($Result)) {
        $Message = 'Logz.io Helm does not exist'
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-Log $script:LogLevelDebug $Message

        Write-TaskPostRun "`$script:IsHelmExist = `$false"
        return
    }

    $Message = 'Logz.io Helm is already exists'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:IsHelmExist = `$true"
}

# Uninstalls Logz.io Helm
# Input:
#   ---
# Output:
#   ---
function Remove-LogzioHelm {
    $local:ExitCode = 1
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Uninstalling Logz.io Helm ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    helm uninstall -n monitoring logzio-monitoring 2>$script:TaskErrorFile | Out-Null
    if ($LASTEXITCODE -ne 0) {
        $Message = "installer.ps1 ($ExitCode): error uninstalling Logz.io Helm: $(Get-TaskErrorMessage)"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Creates Logz.io AppData subdirectory
# Input:
#   ---
# Output:
#   ---
function New-LogzioAppDataSubDir {
    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Creating Logz.io AppData subdirectory ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message
    
    try {
        New-Item -Path $script:LogzioKubernetesDir -ItemType Directory -Force -ErrorAction Stop | Out-Null    
    }
    catch {
        $Message = "installer.ps1 ($ExitCode): error creating Logz.io Kubernetes directory: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Creates Logz.io Helm file with Helm install command
# Input:
#   FuncArgs - Hashtable {HelmSets = $script:HelmSets}
# Ouput:
#   ---
function New-LogzioHelmFileWithHelmInstall {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Creating Logz.io Helm file with Helm install command ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('HelmSets')
    if ($Err.Count -ne 0) {
        $Message = "installer.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:HelmSets = $FuncArgs.HelmSets

    "helm install -n monitoring $HelmSets --create-namespace logzio-monitoring logzio-helm/logzio-monitoring" | Out-File -FilePath $script:LogzioHelmFile -Encoding utf8
}

# Runs Helm install
# Input:
#   FuncArgs - Hashtable {HelmSets = $script:HelmSets; LogHelmSets = $script:LogHelmSets}
# Output:
#   ---
function Invoke-HelmInstall {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 4
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Running Helm install ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('HelmSets', 'LogHelmSets')
    if ($Err.Count -ne 0) {
        $Message = "installer.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:HelmSets = $FuncArgs.HelmSets
    $local:LogHelmSets = $FuncArgs.LogHelmSets

    $local:Message = "Helm sets are '$LogHelmSets'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    $local:Retries = 3
    while ($Retries -ne 0) {
        Invoke-Expression -Command "helm install -n monitoring $HelmSets --create-namespace logzio-monitoring logzio-helm/logzio-monitoring" 2>$script:TaskErrorFile | Out-Null
        if ($LASTEXITCODE -eq 0) {
            return
        }

        Start-Sleep -Seconds 5
        $Retries--
    }

    helm status logzio-monitoring -n monitoring 2>&1 | Out-Null

    $Message = "installer.ps1 ($ExitCode): error running Helm install: $(Get-TaskErrorMessage)"
    Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-TaskPostRun "Write-Error `"$Message`""

    return $ExitCode
}
