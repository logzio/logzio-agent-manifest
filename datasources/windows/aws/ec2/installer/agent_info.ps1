#################################################################################################################################
################################################## WINDOWS Agent Info Script ####################################################
#################################################################################################################################

Write-Host
Write-Host '###################'
Write-Host '### ' -NoNewline
Write-Host 'Information' -ForegroundColor Magenta -NoNewline
Write-Host ' ###'
Write-Host '###################'
Write-Host 'Collector Binary' -ForegroundColor Magenta -NoNewLine
Write-Host ": $script:OtelCollectorExe"
Write-Host 'Collector Config' -ForegroundColor Magenta -NoNewLine
Write-Host ": $script:OtelConfig"
Write-Host 'Logz.io Agent Logs' -ForegroundColor Magenta -NoNewLine
Write-Host ": $script:AgentLogFile"
Write-Host 'Start Service' -ForegroundColor Magenta -NoNewLine
Write-Host ": Start-Service -Name $script:LogzioOtelCollectorServiceName"
Write-Host 'Stop Service' -ForegroundColor Magenta -NoNewLine
Write-Host ": Stop-Service -Name $script:LogzioOtelCollectorServiceName"
Write-Host 'Delete Service' -ForegroundColor Magenta -NoNewLine
Write-Host ": sc.exe DELETE $script:LogzioOtelCollectorServiceName (stop the service before deleting it)"
Write-Host 'Show Service' -ForegroundColor Magenta -NoNewLine
Write-Host ": Get-Service -Name $script:LogzioOtelCollectorServiceName"
Write-Host 'Show Service Logs' -ForegroundColor Magenta -NoNewLine
Write-Host ": eventvwr.msc ('Windows Logs'->'Application' all logs with source '$script:LogzioOtelCollectorServiceName')"
