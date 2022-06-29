#################################################################################################################################
################################################## Metrics Windows Functions ####################################################
#################################################################################################################################

# Builds enable metrics Helm set
# Output:
#   helmSets - Contains all the Helm sets
function Build-EnableMetricsHelmSet {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building enable metrics Helm set ..."

    $local:helmSet = " --set logzio-k8s-telemetry.metrics.enabled=true"
    Write-Log "INFO" "helmSet = $helmSet"
    Write-Run "`$script:logHelmSets += '$helmSet'"
    Write-Run "`$script:helmSets += '$helmSet'"
}

# Builds Logz.io metrics listener URL Helm set
# Output:
#   helmSets - Contains all the Helm sets
# Error:
#   Exit Code 1
function Build-LogzioMetricsListenerUrlHelmSet {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building Logz.io metrics listener URL Helm set ..."

    $local:listenerURL = jq -r '.listenerUrl' $using:appJSON
    if ([string]::IsNullOrEmpty($listenerURL)) {
        Write-Run "Write-Error `"metrics.ps1 (1): '.listenerUrl' is empty in application JSON`""
        return 1
    }
    if ($listenerURL.Equals("null")) {
        Write-Run "Write-Error `"metrics.ps1 (1): '.listenerUrl' was not found in application JSON`""
        return 1
    }

    $listenerURL = "https://$listenerURL`:8053"
    $local:helmSet = " --set logzio-k8s-telemetry.secrets.ListenerHost=$listenerURL"
    Write-Log "INFO" "helmSet = $helmSet"
    Write-Run "`$script:logHelmSets += '$helmSet'"
    Write-Run "`$script:helmSets += '$helmSet'"
}

# Builds Logz.io metrics token Helm set
# Output:
#   helmSets - Contains all the Helm sets
# Error:
#   Exit Code 2
function Build-LogzioMetricsTokenHelmSet {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building Logz.io metrics token Helm set ..."

    $local:shippingToken = jq -r '.shippingTokens.METRICS' $using:appJSON
    if ([string]::IsNullOrEmpty($shippingToken)) {
        Write-Run "Write-Error `"metrics.ps1 (2): '.shippingTokens.METRICS' is empty in application JSON`""
        return 2
    }
    if ($shippingToken.Equals("null")) {
        Write-Run "Write-Error `"metrics.ps1 (2): '.shippingTokens.METRICS' was not found in application JSON`""
        return 2
    }
    
    $local:helmSet = " --set logzio-k8s-telemetry.secrets.MetricsToken=$shippingToken"
    Write-Log "INFO" "helmSet = $helmSet"
    Write-Run "`$script:logHelmSets += '$helmSet'"
    Write-Run "`$script:helmSets += '$helmSet'"
}
