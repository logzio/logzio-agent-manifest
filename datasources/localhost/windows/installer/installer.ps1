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
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    $local:Answer = ''

    while ($true) {
        Write-Host "$script:LogzioOtelServiceName service is already exist. If you continue the service will be removed. Are you sure? (y/n) " -ForegroundColor Yellow -NoNewline

        $Answer = Read-Host
        $Answer = $Answer.ToLower()
        if ($Answer.Equals('y') -or $Answer.Equals('n')) {
            break
        }
    }

    $Message = "The user answer is '$Answer'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    if ($Answer.Equals('n')) {
        $script:IsRemoveServiceAnswerNo = $true
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
    $local:ExitCode = 4
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Running all datasources scripts ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $script:FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    foreach ($DataSource in $script:DataSources) {
        $Message = "Running $DataSource datasource prerequisites ..."
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-Log $script:LogLevelDebug $Message

        try {
            . "$script:LogzioTempDir\$script:Platform\$script:SubType\$DataSource\$script:PrerequisitesFile" -ErrorAction Stop
            if ($LASTEXITCODE -ne 0) {
                Exit $LASTEXITCODE
            }
        }
        catch {
            $Message = "installer.ps1 ($ExitCode): error running $DataSource datasource prerequisites: $_"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
            Write-Error $Message

            $script:IsAgentFailed = $true
            Exit $ExitCode
        }

        $Message = "Running $DataSource datasource installer ..."
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-Log $script:LogLevelDebug $Message
    
        try {
            . "$script:LogzioTempDir\$script:Platform\$script:SubType\$DataSource\$script:InstallerFile" -ErrorAction Stop
            if ($LASTEXITCODE -ne 0) {
                Exit $LASTEXITCODE
            }
        }
        catch {
            $Message = "installer.ps1 ($ExitCode): error running $DataSource datasource installer: $_"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
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
# Create Logz.io AppData subdirectory
Invoke-Task 'New-LogzioAppDataSubDir' @{} 'Creating Logz.io AppData subdirectory' @($InstallerScriptFile)
# Download OTEL collector exe
Invoke-Task 'Get-OtelCollectorExe' @{} 'Downloading OTEL collector exe' @($InstallerScriptFile)
# Run each datasource scripts
Invoke-AllDataSources






# Run Logz.io OTEL collector service
#Write-Host "`ninstaller:"
#Invoke-Task "Invoke-LogzioOTELCollectorService" "running Logz.io OTEL collector service"

# Print success message
#Write-Host
#Write-Info "##### Logz.io agent was finished successfully #####"

# Print information
#Write-Host "`nInformation:`n"
#Write-Host "Collector Binary" -ForegroundColor Magenta -NoNewLine
#Write-Host ": $otelBin"
#Write-Host "Collector Config" -ForegroundColor Magenta -NoNewLine
#Write-Host ": $otelConfig"
#Write-Host "Start Service Command" -ForegroundColor Magenta -NoNewLine
#Write-Host ": Start-Service -Name LogzioOTELCollector"
#Write-Host "Stop Service Command" -ForegroundColor Magenta -NoNewLine
#Write-Host ": Stop-Service -Name LogzioOTELCollector"
#Write-Host "Delete Service Command" -ForegroundColor Magenta -NoNewLine
#Write-Host ": sc.exe DELETE LogzioOTELCollector (stop the service before deleting it)"
#Write-Host "Show Service Command" -ForegroundColor Magenta -NoNewLine
#Write-Host ": Get-Service -Name LogzioOTELCollector"
#Write-Host "Show Logs Command" -ForegroundColor Magenta -NoNewLine
#Write-Host ": eventvwr.msc ('Windows Logs'->'Application' all logs with source 'LogzioOTELCollector')"
#Write-Host

# Finished successfully
Exit 0
