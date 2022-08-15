#################################################################################################################################
#################################################### Metrics Windows Script #####################################################
#################################################################################################################################

# Load functions
Write-Log "INFO" "Loading metrics functions ..."
. $logzioTempDir\metrics_functions.ps1

# Get Logz.io metrics listener URL
Invoke-Task "Get-LogzioMetricsListenerUrl" "getting Logz.io metrics listener URL"

# Get Logz.io metrics token
Invoke-Task "Get-LogzioMetricsToken" "getting Logz.io metrics token"

# Add metrics receivers to OTEL config
Invoke-Task "Add-MetricsReceiversToOTELConfig" "adding metrics receivers to OTEL config"

# Add metrics exporter to OTEL config
Invoke-Task "Add-MetricsExporterToOTELConfig" "adding metrics exporter to OTEL config"

# Finished successfully
Exit 0
