#################################################################################################################################
################################################## Traces Windows Functions #####################################################
#################################################################################################################################

# Builds enable traces Helm set
# Output:
#   helmSets - Contains all the Helm sets
function Build-EnableTracesHelmSet {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building enable traces Helm set ..."

    $local:helmSet = " --set logzio-k8s-telemetry.traces.enabled=true"
    Write-Log "INFO" "helm_set = $helmSet"
    Write-Run "`$helmSets += '$helmSet'"
}

# Builds Logz.io traces token Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 2
function Build-LogzioTracesTokenHelmSet {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building Logz.io traces token Helm set ..."

    $local:shippingToken = jq -r '.shippingTokens.TRACING' $using:appJSON
    if ([string]::IsNullOrEmpty($shippingToken)) {
        Write-Run "Write-Error `"traces.ps1 (2): '.shippingTokens.TRACING' is empty in application JSON`""
        return 2
    }
    if ($shippingToken.Equals("null")) {
        Write-Run "Write-Error `"traces.ps1 (2): '.shippingTokens.TRACING' was not found in application JSON`""
        return 2
    }
    
    $local:helmSet = " --set logzio-k8s-telemetry.secrets.TracesToken=$shippingToken"
    Write-Log "INFO" "helm_set = $helmSet"
    Write-Run "`$helmSets += '$helmSet'"
}

# Builds Logz.io region Helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Error Code 3
function Build-LogzioRegionHelmSet {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building Logz.io region Helm set ..."

    $local:listenerURL = jq -r '.listenerUrl' $using:appJSON
    if ([string]::IsNullOrEmpty($listenerURL)) {
        Write-Run "Write-Error `"traces.ps1 (3): '.listenerUrl' is empty in application JSON`""
        return 3
    }
    if ($listenerURL.Equals("null")) {
        Write-Run "Write-Error `"traces.ps1 (3): '.listenerUrl' was not found in application JSON`""
        return 3
    }

    $local:region = "us"
    if ($listenerURL -match ".*-.*") {
        $local:listenerPart = $listenerURL.Split(".", 2)[0]
        $region = $listenerPart.Split("-", 2)[1]
    }
    
    $local:helmSet = " --set logzio-k8s-telemetry.secrets.LogzioRegion=$region"
    Write-Log "INFO" "helm_set = $helmSet"
    Write-Run "`$helmSets += '$helmSet'"
}
