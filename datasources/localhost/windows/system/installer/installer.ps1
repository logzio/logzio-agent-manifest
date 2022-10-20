#################################################################################################################################
################################################### Installer Windows Script ####################################################
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
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    try {
        . $logzioTempDir\$Platform\$SubType\$DataSource\$LogsFile -ErrorAction Stop
        if ($LASTEXITCODE -ne 0) {
            Exit $LASTEXITCODE
        }
    }
    catch {
        $local:Message = "installer.ps1 ($ExitCode): error running System datasource logs script: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
        Write-Error $Message

        $IsAgentFailed = $true
        Exit $ExitCode
    }
}

# Runs logs script
# Input:
#   ---
# Output:
#   ---
function Invoke-Metrics {
    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = "Running System datasource metrics script ..."
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
    Write-Log $LogLevelDebug $Message

    try {
        . $logzioTempDir\$Platform\$SubType\$DataSource\$MetricsFile -ErrorAction Stop
        if ($LASTEXITCODE -ne 0) {
            Exit $LASTEXITCODE
        }
    }
    catch {
        $local:Message = "installer.ps1 ($ExitCode): error running System datasource metrics script: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype $DataSourceSystem
        Write-Error $Message

        $IsAgentFailed = $true
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
if ($IsLogsOptionSelected) {
    Invoke-Logs
}

# Run metrics script
#if ($isMetricsOptionSelected) {
#    Write-Log "INFO" "Running metrics script ..."
#    Write-Host "`nmetrics:"
#    . $logzioTempDir\metrics.ps1
#    if ($LASTEXITCODE -gt 0) {
#        Exit $LASTEXITCODE
#    }
#}

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
