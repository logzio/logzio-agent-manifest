#################################################################################################################################
############################################# WINDOWS Subtype Prerequisites Script ##############################################
#################################################################################################################################

# Print title
Write-Host
Write-Host '#####################'
Write-Host '### ' -NoNewline
Write-Host 'Prerequisites' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '#####################'

# Check if localhost can connect to Logz.io logs (port 8071)
Invoke-Task 'Test-CanLocalhostConnectToLogzioLogs' @{} 'Checking if localhost can connect to Logz.io logs' @("$LogzioTempDir\$Platform\$SubType\$PrerequisitesFunctionsFile")
# Check if localhost can connect to Logz.io metrics (port 8053)
Invoke-Task 'Test-CanLocalhostConnectToLogzioMetrics' @{} 'Checking if localhost can connect to Logz.io metrics' @("$LogzioTempDir\$Platform\$SubType\$PrerequisitesFunctionsFile")

# Finished successfully
Exit 0
