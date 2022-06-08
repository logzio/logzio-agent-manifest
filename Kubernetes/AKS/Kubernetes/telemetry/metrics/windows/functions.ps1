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
    Write-Run "`$helmSets += '$helmSet'"
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

    $listenerURL = "https://$listener_url:8053"
    $local:helmSet = " --set logzio-k8s-telemetry.secrets.ListenerHost=$listenerURL"
    Write-Log "INFO" "helmSet = $helmSet"
    Write-Run "`$helmSets += '$helmSet'"
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
    Write-Run "`$helmSets += '$helmSet'"
}

# Gets is Kubernetes runs on Windows OS
# Output:
#   isWindows - Tells if Kubernetes runs on Windows OS (true/false)
# Error:
#   Exit Code 3
function Get-IsKubernetesRunsOnWindowsOS {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting if Kubernetes runs on Windows OS ..."

    $local:isWindowsParam = Find-Param "$using:metricsParams" "isWindows"
    if ([string]::IsNullOrEmpty($isWindowsParam)) {
        Write-Run "Write-Error `"metrics.ps1 (3): isWindows param was not found`""
        return 3
    }

    $local:isWindowsValue = Write-Output "$isWindowsParam" | jq -r '.value'
    if ([string]::IsNullOrEmpty($isWindowsValue)) {
        Write-Run "Write-Error `"metrics.ps1 (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=METRICS}].params[{name=isWindows}].value' is empty in application JSON`""
        return 3
    }
    if ($isWindowsValue.Equals("null")) {
        Write-Run "Write-Error `"installer.ps1 (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=METRICS}].params[{name=isWindows}].value' was not found in application JSON`""
        return 3
    }

    Write-Log "INFO" "isWindows = $isWindowsValue"
    Write-Run "`$script:isWindows = `$$isWindowsValue"
}

# Builds Windows Node username and password Helms sets (if Kubernetes runs on Windows OS)
# Output:
#   helmSets - Contains all the Helm sets
function Build-WindowsNodeUsernameAndPasswordHelmSets {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building Windows Node username and password Helm sets ..."

    Write-Run "Write-Host `"Please enter your Windows Node username: `" -ForegroundColor Magenta -NoNewline"
    Write-Run "`$local:username = Read-Host"
    Write-Run "Write-Host `"Please enter your Windows Node password: `" -ForegroundColor Magenta -NoNewline"
    Write-Run "`$local:username = Read-Host -MaskInput"
    Write-Run "`$local:windowsSets += `" --set logzio-k8s-telemetry.secrets.windowsNodeUsername=`$username`""
    Write-Run "`$windowsSets += `" --set logzio-k8s-telemetry.secrets.windowsNodePassword=`$password`""
    Write-Run "Write-Log `"INFO`" `"windowsSets = `$windowsSets`""
    Write-Run "`$helmSets += `"`$windows_sets`""
}
