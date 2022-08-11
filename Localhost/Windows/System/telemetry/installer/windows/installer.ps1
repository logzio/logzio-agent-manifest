#################################################################################################################################
################################################### Installer Windows Script ####################################################
#################################################################################################################################

# Load functions
Write-Log "INFO" "Loading installer functions ..."
. $logzioTempDir\installer_functions.ps1

# Get the selected products
Invoke-Task "Get-SelectedProducts" "getting the selected products"

# Create Logz.io AppData directory
Invoke-Task "New-LogzioAppDataDir" "creating Logz.io AppData directory"

# Get OTEL collector binary
Invoke-Task "Get-OTELCollectorBinary" "getting OTEL collector binary"

# Get OTEL config
Invoke-Task "Get-OTELConfig" "getting OTEL config"

# Get logs scripts
if ($isLogsOptionSelected) {
    Invoke-Task "Get-LogsScripts" "getting logs scripts"
}

# Get metrics scripts
if ($isMetricsOptionSelected) {
    Invoke-Task "Get-MetricsScripts" "getting metrics scripts"
}

# Run logs script
if ($isLogsOptionSelected) {
    Write-Log "INFO" "Running logs script ..."
    Write-Host "`nlogs:"
    . $logzioTempDir\logs.ps1
    if ($LASTEXITCODE -gt 0) {
        Exit $LASTEXITCODE
    }
}

# Run metrics script
if ($isMetricsOptionSelected) {
    Write-Log "INFO" "Running metrics script ..."
    Write-Host "`nmetrics:"
    . $logzioTempDir\metrics.ps1
    if ($LASTEXITCODE -gt 0) {
        Exit $LASTEXITCODE
    }
}

# Run Logz.io OTEL collector service
Write-Host "`ninstaller:"
Invoke-Task "Invoke-LogzioOTELCollectorService" "running Logz.io OTEL collector service"

# Print success message
Write-Host
Write-Info "##### Logz.io agent was finished successfully #####"

# Print information
Write-Host "`nInformation:`n"
Write-Host "Collector Binary" -ForegroundColor Magenta -NoNewLine
Write-Host ": $otelBin"
Write-Host "Collector Config" -ForegroundColor Magenta -NoNewLine
Write-Host ": $otelConfig"
Write-Host "Start Service Command" -ForegroundColor Magenta -NoNewLine
Write-Host ": Start-Service -Name LogzioOTELCollector"
Write-Host "Stop Service Command" -ForegroundColor Magenta -NoNewLine
Write-Host ": Stop-Service -Name LogzioOTELCollector"
Write-Host "Show Service Command" -ForegroundColor Magenta -NoNewLine
Write-Host ": Get-Service -Name LogzioOTELCollector"
Write-Host "Show Logs Command" -ForegroundColor Magenta -NoNewLine
Write-Host ": Get-Content -Path $logzioAppDataDir\logzio_otel_collector.log -Tail 10 -Wait"
Write-Host

# Finished successfully
Exit 0
