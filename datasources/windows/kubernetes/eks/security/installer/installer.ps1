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


$local:InstallerFunctionsScript = "$script:LogzioTempDir\$script:Platform\$script:SubType\$($script:CurrentDataSource.ToLower())\$script:InstallerFunctionsFile"

# Print title
Write-Host
Write-Host '##########################################'
Write-Host '### ' -NoNewline
Write-Host 'Security Datasource Installation' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '##########################################'

# Get the selected products
Invoke-Task 'Get-SelectedProducts' @{} 'Getting the selected products' @($InstallerFunctionsScript)
# # Get general params
# Invoke-Task 'Get-GeneralParams' @{} 'Getting general params' @($InstallerFunctionsScript)
# # Get environment id
# Invoke-Task 'Get-EnvironmentID' @{GeneralParams = $script:GeneralParams; DefaultEnvId = $script:DefaultEnvId} 'Getting environment id' @($InstallerFunctionsScript)
# Run logs script
Invoke-Logs

# Finished successfully
Exit 0
