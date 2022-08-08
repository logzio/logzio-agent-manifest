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

# Finished successfully
Exit 0
