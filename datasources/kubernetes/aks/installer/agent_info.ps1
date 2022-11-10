#################################################################################################################################
################################################## WINDOWS Agent Info Script ####################################################
#################################################################################################################################

Write-Host
Write-Host '###################'
Write-Host '### ' -NoNewline
Write-Host 'Information' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '###################'
Write-Host 'Logz.io Helm' -ForegroundColor Magenta -NoNewLine
Write-Host ": $script:LogzioHelmFile"
Write-Host 'Logz.io Agent Logs' -ForegroundColor Magenta -NoNewLine
Write-Host ": $script:AgentLogFile"
Write-Host 'Install Logz.io Helm' -ForegroundColor Magenta -NoNewLine
Write-Host ": Run command in Logz.io Helm file"
Write-Host 'Uninstall Logz.io Helm' -ForegroundColor Magenta -NoNewLine
Write-Host ": helm uninstall -n monitoring logzio-monitoring"
Write-Host 'Show Helm Status' -ForegroundColor Magenta -NoNewLine
Write-Host ": helm status -n monitoring logzio-monitoring"
Write-Host 'Get Pods' -ForegroundColor Magenta -NoNewLine
Write-Host ": kubectl get pods -n monitoring"
Write-Host "Show Pod's Logs" -ForegroundColor Magenta -NoNewLine
Write-Host ": kubectl logs <<POD_NAME>> -n monitoring"
Write-Host "Show Pod's Info" -ForegroundColor Magenta -NoNewLine
Write-Host ": kubectl describe pod <<POD_NAME>> -n monitoring"
