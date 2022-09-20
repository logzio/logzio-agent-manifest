#################################################################################################################################
################################################### Installer Windows Script ####################################################
#################################################################################################################################

# Load functions
Write-Log "INFO" "Loading installer functions ..."
. $logzioTempDir\installer_functions.ps1

# Helm sets
$script:helmSets = ""
$script:logHelmSets = ""

# Get general params
Invoke-Task "Get-GeneralParams" "getting general params"

# Get the selected products
Invoke-Task "Get-SelectedProducts" "getting the selected products"

# Build tolerations helm sets
Invoke-Task "Build-TolerationsHelmSets" "building tolerations Helm sets"

# Build enable metrics or traces helm set
if ($isMetricsOptionSelected -or $isTracesOptionSelected) {
    Invoke-Task "Build-EnableMetricsOrTracesHelmSet" "building enable metrics or traces Helm set"
}

# Build metrics/traces environment tag helm set
if ($isMetricsOptionSelected -or $isTracesOptionSelected) {
    Invoke-Task "Build-EnvironmentTagHelmSet" "building metrics/traces environment tag Helm set"
}

# Get logs scripts
if ($isLogsOptionSelected) {
    Invoke-Task "Get-LogsScripts" "getting logs scripts"
}

# Get metrics scripts
if ($isMetricsOptionSelected) {
    Invoke-Task "Get-MetricsScripts" "getting metrics scripts"
}

# Get traces scripts
if ($isTracesOptionSelected) {
    Invoke-Task "Get-TracesScripts" "getting traces scripts"
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

# Run traces script
if ($isTracesOptionSelected) {
    Write-Log "INFO" "Running traces script ..."
    Write-Host "`ntraces:"
    . $logzioTempDir\traces.ps1
    if ($LASTEXITCODE -gt 0) {
        Exit $LASTEXITCODE
    }
}

# Run Helm install
Write-Host "`ninstaller:"
Invoke-Task "Invoke-HelmInstall" "running Helm install"

# Get postrequisites scripts
Invoke-Task "Get-PostrequisitesScripts" "getting postrequisites scripts"

# Run postrequisites script
Write-Log "INFO" "Running postrequisites script ..."
Write-Host "`npostrequisites:"
. $logzioTempDir\postrequisites.ps1

if (-Not $areAllPodsRunningOrCompleted -or $isAnyPodPending -or $isAnyPodFailed) {
    # Print fail message
    Write-Host
    Write-Error "##### Logz.io agent failed #####"
} else {
    # Print success message
    Write-Host
    Write-Info "##### Logz.io agent was finished successfully #####"
}

# Print information
Write-Host "`nInformation:`n"
Write-Host "Show Helm Install Command" -ForegroundColor Magenta -NoNewLine
Write-Host ": Get-Content -Path `"$(Get-Location)\logzio.helm`""

# Finished successfully
Exit 0
