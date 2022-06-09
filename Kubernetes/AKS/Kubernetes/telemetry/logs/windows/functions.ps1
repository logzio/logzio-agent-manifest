#################################################################################################################################
################################################### Logs Windows Functions ######################################################
#################################################################################################################################

# Builds enable logs Helm set
# Output:
#   helmSets - Contains all the Helm sets
function Build-EnableLogsHelmSet {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building enable logs Helm set ..."
    
    $local:helmSet = " --set logs.enabled=true"
    Write-Log "INFO" "helmSet = $helmSet"
    Write-Run "`$script:logHelmSets += '$helmSet'"
    Write-Run "`$script:helmSets += '$helmSet'"
}

# Builds Logz.io logs listener URL Helm set
# Output:
#   helmSets - Contains all the Helm sets
# Error:
#   Exit Code 1
function Build-LogzioLogsListenerUrlHelmSet {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building Logz.io logs listener URL Helm set ..."

    $local:listenerURL = jq -r '.listenerUrl' $using:appJSON
    if ([string]::IsNullOrEmpty($listenerURL)) {
        Write-Run "Write-Error `"logs.ps1 (1): '.listenerUrl' is empty in application JSON`""
        return 1
    }
    if ($listenerURL.Equals("null")) {
        Write-Run "Write-Error `"logs.ps1 (1): '.listenerUrl' was not found in application JSON`""
        return 1
    }

    $local:helmSet = " --set logzio-fluentd.secrets.logzioListener=$listenerURL"
    Write-Log "INFO" "helmSet = $helmSet"
    Write-Run "`$script:logHelmSets += '$helmSet'"
    Write-Run "`$script:helmSets += '$helmSet'"
}

# Builds Logz.io logs token Helm set
# Output:
#   helmSets - Contains all the Helm sets
# Error:
#   Exit Code 2
function Build-LogzioLogsTokenHelmSet {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building Logz.io logs token Helm set ..."

    $local:shippingToken = jq -r '.shippingTokens.LOG_ANALYTICS' $using:appJSON
    if ([string]::IsNullOrEmpty($shippingToken)) {
        Write-Run "Write-Error `"logs.ps1 (2): '.shippingTokens.LOG_ANALYTICS' is empty in application JSON`""
        return 2
    }
    if ($shippingToken.Equals("null")) {
        Write-Run "Write-Error `"logs.ps1 (2): '.shippingTokens.LOG_ANALYTICS' was not found in application JSON`""
        return 2
    }

    $local:helmSet = " --set logzio-fluentd.secrets.logzioShippingToken=$shippingToken"
    Write-Log "INFO" "helmSet = $helmSet"
    Write-Run "`$script:logHelmSets += '$helmSet'"
    Write-Run "`$script:helmSets += '$helmSet'"
}

# Builds multiline Helm sets
# Output:
#   helmSets - Contains all the Helm sets
# Error:
#   Exit Code 3
function Build-MultilineHelmSets {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building multiline Helm sets ..."

    $local:multilineParam = Find-Param "$using:logsParams" "multiline"
    if ([string]::IsNullOrEmpty($multilineParam)) {
        Write-Run "Write-Error `"logs.ps1 (3): multiline param was not found`""
        return 3
    }

    $local:multilineValue = Write-Output "$multilineParam" | jq -c '.value[]'
    if ([string]::IsNullOrEmpty($multilineValue)) {
        Write-Run "Write-Error `"logs.ps1 (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[]' is empty in application JSON`""
        return 3
    }
    if ($multilineValue.Equals("null")) {
        Write-Run "Write-Error `"logs.ps1 (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[]' was not found in application JSON`""
        return 3
    }

    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/logs/multiline_source.conf -OutFile $using:logzioTempDir\multiline_source.conf | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"logs.ps1 (3): failed to get multiline source conf file from logzio-agent-manifest repo.`n  $_`""
        return 3
    }

    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/logs/multiline_filter.conf -OutFile $using:logzioTempDir\multiline_filter.conf | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"logs.ps1 (3): failed to get multiline filter conf file from logzio-agent-manifest repo.`n  $_`""
        return 3
    }

    $local:paths = ""
    $local:index = 1

    foreach ($multilineObj in $multilineValue) {
        $local:source = Get-Content $logzio_temp_dir\multiline_source.conf
        $local:filter = Get-Content $logzio_temp_dir\multiline_filter.conf
        $local:name = "custom$index"

        $local:path = Write-Output "$multilineObj" | jq -r '.source'
        if ([string]::IsNullOrEmpty($path)) {
            Write-Run "Write-Error `"logs.ps1 (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[{obj}].source' is empty in application JSON`""
            return 3
        }
        if ($path.Equals("null")) {
            Write-Run "Write-Error `"logs.ps1 (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[{obj}].source' was not found in application JSON`""
            return 3
        }

        $paths += ",$path"

        $local:regex = Write-Output "$multilineObj" | jq -r '.pattern'
        if ([string]::IsNullOrEmpty($regex)) {
            Write-Run "Write-Error `"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[{obj}].pattern' is empty in application JSON`""
            return 3
        }
        if ($regex.Equals("null")) {
            Write-Run "Write-Error `"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=multiline}].value[{obj}].pattern' was not found in application JSON`""
            return 3
        }

        $source = $source.Replace("NAME", $name)
        $source = $source.Replace("PATH", $path)
        $filter = $filter.Replace("NAME", $name)
        $filter = $filter.Replace("REGEX", $regex)
        Write-Output "$source" > $using:logzioTempDir\sources.conf
        Write-Output "$filter" > $using:logzioTempDir\filters.conf
        $index++
    }

    $paths = $paths.Substring(1)

    $local:multilineSets += " --set-file configmap.customSources=logzio-temp/sources.conf"
    $multilineSets += " --set-file configmap.customFilters=logzio-temp/filters.conf"
    $multilineSets += " --set daemonset.extraExclude=`"$paths`""

    $local:sources = Get-Content $logzio_temp_dir\sources.conf
    $local:filters = Get-Content $logzio_temp_dir\filters.conf
    Write-Log "INFO" "sources.conf:`n$sources"
    Write-Log "INFO" "filters.conf:`n$filters"
    Write-Log "INFO" "multilineSets = $multilineSets"

    Write-Run "`$script:logHelmSets += '$multilineSets'"
    Write-Run "`$script:helmSets += '$multilineSets'"
}
