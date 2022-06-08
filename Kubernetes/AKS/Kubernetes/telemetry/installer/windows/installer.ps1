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
Invoke-Task "Build-TolerationsHelmSets" "building tolerations helm sets"

# Build enable metrics or traces helm set
if ($isMetricsOptionSelected -or $isTracesOptionSelected) {
    Invoke-Task "Build-EnableMetricsOrTracesHelmSet" "building enable metrics or traces helm set"
}

# Build metrics/traces environment tag helm set
if ($isMetricsOptionSelected -or $isTracesOptionSelected) {
    Invoke-Task "Build-EnvironmentTagHelmSet" "building metrics/traces environment tag helm set"
}

<#
# Get logs scripts
if $is_logs_option_selected; then
    execute_task "get_logs_scripts" "getting logs scripts"
fi

# Get metrics scripts
if $is_metrics_option_selected; then
    execute_task "get_metrics_scripts" "getting metrics scripts"
fi

# Get traces scripts
if $is_traces_option_selected; then
    execute_task "get_traces_scripts" "getting traces scripts"
fi

# Run logs script
if $is_logs_option_selected; then
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Running logs script ..." >> logzio_agent.log
    echo -e "\nlogs:"
    source ./logzio-temp/logs.bash
fi

# Run metrics script
if $is_metrics_option_selected; then
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Running metrics script ..." >> logzio_agent.log
    echo -e "\nmetrics:"
    source ./logzio-temp/metrics.bash
fi

# Run traces script
if $is_traces_option_selected; then
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Running traces script ..." >> logzio_agent.log
    echo -e "\ntraces:"
    source ./logzio-temp/traces.bash
fi

# Run Helm install
echo -e "\ninstaller:"
execute_task "run_helm_install" "running Helm install"#>
