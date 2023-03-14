#################################################################################################################################
################################################### WINDOWS Installer Script ####################################################
#################################################################################################################################

# Runs logs script
# Input:
#   ---
# Output:
#   ---
function Invoke-Logs {
    $local:ExitCode = 8
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = "Running $CurrentDataSource datasource logs script ..."
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    try {
        . "$script:LogzioTempDir\$script:Platform\$script:SubType\$($script:CurrentDataSource.ToLower())\$script:LogsFile" -ErrorAction Stop
        if ($LASTEXITCODE -ne 0) {
            Exit $LASTEXITCODE
        }
    }
    catch {
        $local:Message = "installer.ps1 ($ExitCode): error running $CurrentDataSource datasource logs script: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-Error $Message

        $script:IsAgentFailed = $true
        Exit $ExitCode
    }
}

# Runs metrics script
# Input:
#   ---
# Output:
#   ---
function Invoke-Metrics {
    $local:ExitCode = 9
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = "Running $CurrentDataSource datasource metrics script ..."
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    try {
        . "$script:LogzioTempDir\$script:Platform\$script:SubType\$($script:CurrentDataSource.ToLower())\$script:MetricsFile" -ErrorAction Stop
        if ($LASTEXITCODE -ne 0) {
            Exit $LASTEXITCODE
        }
    }
    catch {
        $local:Message = "installer.ps1 ($ExitCode): error running $CurrentDataSource datasource metrics script: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-Error $Message

        $script:IsAgentFailed = $true
        Exit $ExitCode
    }
}

# Runs traces script
# Input:
#   ---
# Output:
#   ---
function Invoke-Traces {
    $local:ExitCode = 10
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = "Running $CurrentDataSource datasource traces script ..."
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    try {
        . "$script:LogzioTempDir\$script:Platform\$script:SubType\$($script:CurrentDataSource.ToLower())\$script:TracesFile" -ErrorAction Stop
        if ($LASTEXITCODE -ne 0) {
            Exit $LASTEXITCODE
        }
    }
    catch {
        $local:Message = "installer.ps1 ($ExitCode): error running $CurrentDataSource datasource traces script: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-Error $Message

        $script:IsAgentFailed = $true
        Exit $ExitCode
    }
}


$local:InstallerFunctionsScript = "$script:LogzioTempDir\$script:Platform\$script:SubType\$($script:CurrentDataSource.ToLower())\$script:InstallerFunctionsFile"

# Print title
Write-Host
Write-Host '##########################################'
Write-Host '### ' -NoNewline
Write-Host 'Kubernetes Datasource Installation' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '##########################################'

# Get the selected products
Invoke-Task 'Get-SelectedProducts' @{} 'Getting the selected products' @($InstallerFunctionsScript)
# Get general params
Invoke-Task 'Get-GeneralParams' @{} 'Getting general params' @($InstallerFunctionsScript)
# Get is Taints and Tolerations option was selected
Invoke-Task 'Get-IsTaintsAndTolerationWasSelected' @{GeneralParams = $script:GeneralParams} 'Getting is Taints and Tolerations option was selected' @($InstallerFunctionsScript)
if ($script:IsTaint) {
    # Build tolerations Helm sets
    Invoke-Task 'Build-TolerationsHelmSets' @{GeneralParams = $script:GeneralParams; IsLogsOptionSelected = $script:IsLogsOptionSelected; IsMetricsOptionSelected = $script:IsMetricsOptionSelected; IsTracesOptionSelected = $script:IsTracesOptionSelected} 'Building tolerations Helm sets' @($InstallerFunctionsScript)
}
# Get environment id
Invoke-Task 'Get-EnvironmentID' @{GeneralParams = $script:GeneralParams} 'Getting environment id' @($InstallerFunctionsScript)
if ($script:IsMetricsOptionSelected -or $script:IsTracesOptionSelected) {
    # Build enable metrics or traces Helm set
    Invoke-Task 'Build-EnableMetricsOrTracesHelmSet' @{} 'Building enable metrics or traces Helm set' @($InstallerFunctionsScript)
    # Build environment tag Helm set
    Invoke-Task 'Build-EnvironmentTagHelmSet' @{EnvId = $script:EnvId} 'Building environment tag Helm set' @($InstallerFunctionsScript)
    # Build environment id Helm set
    Invoke-Task 'Build-EnvironmentIdHelmSet' @{EnvId = $script:EnvId} 'Building environment id Helm set' @($InstallerFunctionsScript)
}
# Get is Fargate option was selected
Invoke-Task 'Get-IsFargateWasSelected' @{GeneralParams = $script:GeneralParams} 'Getting is Fargate was selected' @($InstallerFunctionsScript)
if ($script:IsLogsOptionSelected) {
    # Run logs script
    Invoke-Logs
}
if ($script:IsMetricsOptionSelected) {
    # Run metrics script
    Invoke-Metrics
}
if ($script:IsTracesOptionSelected) {
    # Run traces script
    Invoke-Traces
}

# Finished successfully
Exit 0
