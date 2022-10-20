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
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
    Write-Log $LogLevelDebug $Message

    $local:Answer = ''

    while ($true) {
        Write-Host "$LogzioOtelServiceName service is already exist. If you continue the service will be removed. Are you sure? (y/n) " -ForegroundColor Yellow -NoNewline

        $Answer = Read-Host
        $Answer = $Answer.ToLower()
        if ($Answer.Equals('y') -or $Answer.Equals('n')) {
            break
        }
    }

    $Message = "The user answer is '$Answer'"
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
    Write-Log $LogLevelDebug $Message

    if ($Answer.Equals('n')) {
        $IsRemoveServiceAnswerNo = $true
        Exit 0
    }

    # Delete Logz.io OTEL collector service
    Invoke-Task 'Remove-LogzioOtelCollectorService' @{} 'Removing Logz.io OTEL collector service' @("$LogzioTempDir\$Platform\$SubType\$InstallerFunctionsFile")
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
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
    Write-Log $LogLevelDebug $Message

    foreach ($DataSource in $DataSources) {
        $Message = "Running $DataSource datasource prerequisites ..."
        Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
        Write-Log $LogLevelDebug $Message

        try {
            . $LogzioTempDir\$Platform\$SubType\$DataSource\$PrerequisitesFile -ErrorAction Stop
            if ($LASTEXITCODE -ne 0) {
                Exit $LASTEXITCODE
            }
        }
        catch {
            $Message = "installer.ps1 ($ExitCode): error running $DataSource datasource prerequisites: $_"
            Send-LogToLogzio $LogLevelError $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
            Write-Error $Message

            $IsAgentFailed = $true
            Exit $ExitCode
        }

        $Message = "Running $DataSource datasource installer ..."
        Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
        Write-Log $LogLevelDebug $Message
    
        try {
            . $LogzioTempDir\$Platform\$SubType\$DataSource\$InstallerFile -ErrorAction Stop
            if ($LASTEXITCODE -ne 0) {
                Exit $LASTEXITCODE
            }
        }
        catch {
            $Message = "installer.ps1 ($ExitCode): error running $DataSource datasource installer: $_"
            Send-LogToLogzio $LogLevelError $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
            Write-Error $Message

            $IsAgentFailed = $true
            Exit $ExitCode
        }
    }
}


# Print title
Write-Host
Write-Host '########################'
Write-Host '### ' -NoNewline
Write-Host 'Pre-Installation' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '########################'

# Check if Logz.io OTEL collector service exists
Invoke-Task 'Get-IsLogzioOtelCollectorServiceExist' @{} 'Checking if Logz.io OTEL collector service exists' @("$LogzioTempDir\$Platform\$SubType\$InstallerFunctionsFile")
if ($IsServiceExist) {
    # Get user answer about removing the existed service and run logic according the answer
    Invoke-RemoveServiceOrExit
}
# Create Logz.io AppData subdirectory
Invoke-Task 'New-LogzioAppDataSubDir' @{} 'Creating Logz.io AppData subdirectory' @("$LogzioTempDir\$Platform\$SubType\$InstallerFunctionsFile")
# Download OTEL collector exe
Invoke-Task 'Get-OtelCollectorExe' @{} 'Downloading OTEL collector exe' @("$LogzioTempDir\$Platform\$SubType\$InstallerFunctionsFile")
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
