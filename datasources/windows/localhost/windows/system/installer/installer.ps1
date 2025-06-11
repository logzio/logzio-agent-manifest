#################################################################################################################################
################################################### WINDOWS Installer Script ####################################################
#################################################################################################################################

# Runs logs script
# Input:
#   ---
# Output:
#   ---
function Invoke-Logs {
    $local:ExitCode = 2
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
    $local:ExitCode = 3
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
# Runs tracing script
# Input:
#   ---
# Output:
#   ---
function Invoke-Traces {
    $local:ExitCode = 4
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = "Running $CurrentDataSource datasource tracing script ..."
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    try {
      . "$script:LogzioTempDir\$script:Platform\$script:SubType\$($script:CurrentDataSource.ToLower())\$script:TracesFile" -ErrorAction Stop
      if ($LASTEXITCODE -ne 0) {
          Exit $LASTEXITCODE
      }
    }
    catch {
        $local:Message = "installer.ps1 ($ExitCode): error running $CurrentDataSource datasource tracing script: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
        Write-Error $Message

        $script:IsAgentFailed = $true
        Exit $ExitCode
    }
  }

$local:InstallerFunctionsScript = "$script:LogzioTempDir\$script:Platform\$script:SubType\$($script:CurrentDataSource.ToLower())\$script:InstallerFunctionsFile"

# Print title
Write-Host
Write-Host '######################################'
Write-Host '### ' -NoNewline
Write-Host 'System Datasource Installation' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '######################################'

# Get the selected products
Invoke-Task 'Get-SelectedProducts' @{} 'Getting the selected products' @($InstallerFunctionsScript)
if ($script:IsLogsOptionSelected) {
    # Run logs script
    Invoke-Logs
}
if ($script:IsMetricsOptionSelected) {
    # Run metrics script
    Invoke-Metrics
}
if ($script:IsTracesOptionSelected) {
  # Run Tracing script
  Invoke-Traces
}
# Finished successfully
Exit 0
