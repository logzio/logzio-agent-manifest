#################################################################################################################################
############################################# WINDOWS Subtype Prerequisites Script ##############################################
#################################################################################################################################

$local:PrerequisitesScriptFile = "$LogzioTempDir\$Platform\$SubType\$PrerequisitesFunctionsFile"

# Print title
Write-Host
Write-Host '#####################'
Write-Host '### ' -NoNewline
Write-Host 'Prerequisites' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '#####################'

# Check if localhost can connect to Logz.io logs (port 8071)
Invoke-Task 'Test-CanLocalhostConnectToLogzioLogs' @{ListenerUrl = $ListenerUrl} 'Checking if localhost can connect to Logz.io logs' @($PrerequisitesScriptFile)
# Check if localhost can connect to Logz.io metrics (port 8053)
Invoke-Task 'Test-CanLocalhostConnectToLogzioMetrics' @{ListenerUrl = $ListenerUrl} 'Checking if localhost can connect to Logz.io metrics' @($PrerequisitesScriptFile)

# Finished successfully
Exit 0
