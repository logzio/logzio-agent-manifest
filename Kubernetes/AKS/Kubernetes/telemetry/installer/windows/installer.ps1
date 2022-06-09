#################################################################################################################################
################################################### Installer Windows Script ####################################################
#################################################################################################################################

# Load functions
Write-Log "INFO" "Loading installer functions ..."
. $logzioTempDir\installer_functions.ps1

# Helm sets
$script:helmSets = ""

# Get general params
Invoke-Task "Get-GeneralParams" "getting general params"

# Get which products were selected
Invoke-Task "Get-WhichProductsWereSelected" "getting which products were selected"

# Build tolerations helm sets
Invoke-Task "Build-TolerationsHelmSets" "building tolerations Helm sets"
Write-Output $helmSets >> test.txt

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
}

# Run metrics script
if ($isMetricsOptionSelected) {
    Write-Log "INFO" "Running metrics script ..."
    Write-Host "`nmetrics:"
    . $logzioTempDir\metrics.ps1
}

# Run traces script
if ($isTracesOptionSelected) {
    Write-Log "INFO" "Running traces script ..."
    Write-Host "`ntraces:"
    . $logzioTempDir\traces.ps1
}

# Run Helm install
Write-Host "`ninstaller:"
Invoke-Task "Invoke-HelmInstall" "running Helm install"
