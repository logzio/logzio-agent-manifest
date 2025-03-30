#################################################################################################################################
################################################### WINDOWS Logs Functions ######################################################
#################################################################################################################################

# Builds enable security report Helm set
# Input:
#   ---
# Output:
#   LogHelmSets - Containt all the Helm sets for logging
#   helmSets - Contains all the Helm sets
function Build-EnableSecurityReportHelmSet {
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Building enable security report Helm set ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message
    
    $local:HelmSet = " --set securityReport.enabled=true"

    $Message = "Enable security report Helm set is '$HelmSet'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepLogs $script:LogScriptLogs $FuncName $script:AgentId $script:Platform $script:Subtype $script:CurrentDataSource
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogHelmSets += '$HelmSet'"
    Write-TaskPostRun "`$script:HelmSets += '$HelmSet'"
}
