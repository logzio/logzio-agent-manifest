#################################################################################################################################
############################################### WINDOWS Subtype Installer Script ################################################
#################################################################################################################################

# Gets user answer about removing the existed service
# If 'y', remove the existed service
# If 'n', exit
# Input:
#   ---
# Output:
#   ---
function Invoke-RemoveServiceOrExit {
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting answer from user about removing the existed service ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    $local:Answer = ''

    while ($true) {
        Write-Host "'$script:LogzioOtelCollectorServiceName' service is already exists. If you continue the service will be removed. Are you sure? (y/n) " -ForegroundColor Yellow -NoNewline

        $Answer = Read-Host
        $Answer = $Answer.ToLower()
        if ($Answer.Equals('y') -or $Answer.Equals('n')) {
            break
        }
    }

    $Message = "The user answer is '$Answer'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    if ($Answer.Equals('n')) {
        $script:IsRemoveLastRunAnswerNo = $true
        Exit 0
    }

    # Delete Logz.io OTEL collector service
    Invoke-Task 'Remove-LogzioOtelCollectorService' @{} 'Removing Logz.io OTEL collector service' @($InstallerScriptFile)
}

# Runs each datasource prerequisites and installer scripts
# Input:
#   ---
# Output:
#   ---
function Invoke-AllDataSources {
    $local:ExitCode = 6
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Running all datasources scripts ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $script:FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    foreach ($DataSource in $script:DataSources) {
        $Message = "Running $DataSource datasource prerequisites ..."
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-Log $script:LogLevelDebug $Message

        $script:CurrentDataSource = $DataSource
        "`$script:CurrentDataSource = '$DataSource'" | Out-File -FilePath $script:ConstsFile -Append -Encoding utf8

        try {
            . "$script:LogzioTempDir\$script:Platform\$script:SubType\$($DataSource.ToLower())\$script:PrerequisitesFile" -ErrorAction Stop
            if ($LASTEXITCODE -ne 0) {
                Exit $LASTEXITCODE
            }
        }
        catch {
            $Message = "installer.ps1 ($ExitCode): error running $DataSource datasource prerequisites: $_"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
            Write-Error $Message

            $script:IsAgentFailed = $true
            Exit $ExitCode
        }

        $Message = "Running $DataSource datasource installer ..."
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-Log $script:LogLevelDebug $Message
    
        try {
            . "$script:LogzioTempDir\$script:Platform\$script:SubType\$($DataSource.ToLower())\$script:InstallerFile" -ErrorAction Stop
            if ($LASTEXITCODE -ne 0) {
                Exit $LASTEXITCODE
            }
        }
        catch {
            $Message = "installer.ps1 ($ExitCode): error running $DataSource datasource installer: $_"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
            Write-Error $Message

            $script:IsAgentFailed = $true
            Exit $ExitCode
        }
    }
}


$local:InstallerScriptFile = "$script:LogzioTempDir\$script:Platform\$script:SubType\$script:InstallerFunctionsFile"

# Print title
Write-Host
Write-Host '########################'
Write-Host '### ' -NoNewline
Write-Host 'Pre-Installation' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '########################'

# Check if Logz.io OTEL collector service exists
Invoke-Task 'Get-IsLogzioOtelCollectorServiceExist' @{} 'Checking if Logz.io OTEL collector service exists' @($InstallerScriptFile)
if ($script:IsServiceExist) {
    # Get user answer about removing the existed service and run logic according the answer
    Invoke-RemoveServiceOrExit
}
# Download OTEL collector exe
Invoke-Task 'Get-OtelCollectorExe' @{} 'Downloading OTEL collector exe' @($InstallerScriptFile)
# Run each datasource scripts
Invoke-AllDataSources

# Print title
Write-Host
Write-Host '####################'
Write-Host '### ' -NoNewline
Write-Host 'Installation' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '####################'

# Create Logz.io AppData subdirectory
Invoke-Task 'New-LogzioAppDataSubDir' @{} 'Creating Logz.io AppData subdirectory' @($InstallerScriptFile)
# Copy Logz.io OTEL files to AppData sub directory
Invoke-Task 'Copy-LogzioOtelFilesToAppDataSubDir' @{} 'Copying Logz.io OTEL files to AppData sub directory' @($InstallerScriptFile)
# Run Logz.io OTEL collector service
Invoke-Task 'Invoke-LogzioOtelCollectorService' @{} 'Running Logz.io OTEL collector service' @($InstallerScriptFile)

# Finished successfully
Exit 0
