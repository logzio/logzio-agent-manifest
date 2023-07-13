#################################################################################################################################
############################################### WINDOWS Subtype Installer Script ################################################
#################################################################################################################################

# Gets user answer about removing the existed Logz.io Helm
# If 'y', remove the existed service
# If 'n', exit
# Input:
#   ---
# Output:
#   ---
function Invoke-RemoveHelmOrExit {
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting answer from user about uninstalling the existed Helm ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    $local:Answer = ''

    while ($true) {
        Write-Host "Logz.io Helm is already exist. If you continue the Helm will be uninstalled. Are you sure? (y/n) " -ForegroundColor Yellow -NoNewline

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

    # Uninstall Logz.io Helm
    Invoke-Task 'Remove-LogzioHelm' @{} 'Uninstalling Logz.io Helm' @($InstallerScriptFile)
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

# Check if Logz.io Helm exists
Invoke-Task 'Get-IsLogzioHelmExist' @{} 'Checking if Logz.io Helm exists' @($InstallerScriptFile)
if ($script:IsHelmExist) {
    # Get user answer about uninstalling the existed Logz.io Helm and run logic according the answer
    Invoke-RemoveHelmOrExit
}
$local:Guid = New-Guid
$script:DefaultEnvId = $Guid.Guid
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
# Create Logz.io Helm file with Helm install command
Invoke-Task 'New-LogzioHelmFileWithHelmInstall' @{HelmSets = $script:HelmSets} 'Creating Logz.io Helm file with Helm install command' @($InstallerScriptFile)
# Run Helm install
Invoke-Task 'Invoke-HelmInstall' @{HelmSets = $script:HelmSets; LogHelmSets = $script:LogHelmSets} 'Running Helm install' @($InstallerScriptFile)

# Finished successfully
Exit 0
