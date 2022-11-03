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

    $local:Message = "Running System datasource logs script ..."
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype $script:DataSourceSystem
    Write-Log $script:LogLevelDebug $Message

    try {
        . "$script:LogzioTempDir\$script:Platform\$script:SubType\$script:DataSourceSystem\$script:LogsFile" -ErrorAction Stop
        if ($LASTEXITCODE -ne 0) {
            Exit $LASTEXITCODE
        }
    }
    catch {
        $local:Message = "installer.ps1 ($ExitCode): error running System datasource logs script: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype $script:DataSourceSystem
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

    $local:Message = "Running System datasource metrics script ..."
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype $script:DataSourceSystem
    Write-Log $script:LogLevelDebug $Message

    try {
        . "$script:LogzioTempDir\$script:Platform\$script:SubType\$script:DataSourceSystem\$script:MetricsFile" -ErrorAction Stop
        if ($LASTEXITCODE -ne 0) {
            Exit $LASTEXITCODE
        }
    }
    catch {
        $local:Message = "installer.ps1 ($ExitCode): error running System datasource metrics script: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype $script:DataSourceSystem
        Write-Error $Message

        $script:IsAgentFailed = $true
        Exit $ExitCode
    }
}


$local:InstallerFunctionsScript = "$LogzioTempDir\$Platform\$SubType\$DataSourceSystem\$InstallerFunctionsFile"

# Print title
Write-Host
Write-Host '######################################'
Write-Host '### ' -NoNewline
Write-Host 'System Datasource Installation' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '######################################'

# Get the selected products
Invoke-Task 'Get-SelectedProducts' @{} 'Getting the selected products' @($InstallerFunctionsScript)
# Run logs script
if ($script:IsLogsOptionSelected) {
    Invoke-Logs
}
# Run metrics script
if ($script:IsMetricsOptionSelected) {
    Invoke-Metrics
}

# Finished successfully
Exit 0
