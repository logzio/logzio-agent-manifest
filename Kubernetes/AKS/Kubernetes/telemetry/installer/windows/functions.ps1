#################################################################################################################################
################################################# Installer Windows Functions ###################################################
#################################################################################################################################

# Gets general params (params under datasource)
# Output:
#   generalParams - The params under datasource
# Error:
#   Exit Code 1
function Get-GeneralParams {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting general params ..."

    $local:generalParams = jq -r '.configuration.subtypes[0].datasources[0].params[]' $using:appJSON
    if ([string]::IsNullOrEmpty($generalParams)) {
        Write-Run "Write-Error `"installer.ps1 (1): '.configuration.subtypes[0].datasources[0].params[]' is empty in application JSON`""
        return 1
    }
    if ($generalParams.Equals("null")) {
        Write-Run "Write-Error `"installer.ps1 (1): .configuration.subtypes[0].datasources[0].params[] was not found in application JSON`""
        return 1
    }

    Write-Log "INFO" "generalParams = $generalParams"
    Write-Run "`$script:generalParams = '$generalParams'"
}

# Gets which products were selected (logs/metrics/traces)
# Output:
#   isLogsOptionSelected - Tells if logs option was selected (true/false)
#   logsParams - The logs params if logs option was selected
#   isMetricsOptionSelected - Tells if metrics option was selected (true/false)
#   metricsParams - The metrics params if metrics option was selected
#   isTracesOptionSelected - Tells if traces option was selected (true/false)
#   tracesParams - The traces params if traces option was selected
# Error:
#   Exit Code 2
function Get-WhichProductsWereSelected {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting which products were selected ..."

    $local:telemetries = jq -c '.configuration.subtypes[0].datasources[0].telemetries[]' $using:appJSON
    if ([string]::IsNullOrEmpty($telemetries)) {
        Write-Run "Write-Error `"installer.ps1 (2): .configuration.subtypes[0].datasources[0].telemetries[] is empty in application JSON`""
        return 2
    }
    if ($telemetries.Equals("null")) {
        Write-Run "Write-Error `"installer.ps1 (2): .configuration.subtypes[0].datasources[0].telemetries[] was not found in application JSON`""
        return 2
    }

    $local:isLogsOptionSelected = $false
    $local:isMetricsOptionSelected = $false
    $local:isTracesOptionSelected = $false
    $local:index = 0

    foreach ($telemetry in $telemetries) {
        $local:type = Write-Output "$telemetry" | jq -r '.type'
        if ([string]::IsNullOrEmpty($type)) {
            Write-Run "Write-Error `"installer.ps1 (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' is empty in application JSON`""
            return 2
        }
        if ($type.Equals("null")) {
            Write-Run "Write-Error `"installer.ps1 (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' was not found in application JSON`""
            return 2
        }

        $local:params = Write-Output "$telemetry" | jq -r '.params[]'
        if ([string]::IsNullOrEmpty($params)) {
            $params = ""
        }
        if ($params.Equals("null")) {
            Write-Run "Write-Error `"installer.ps1 (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].params[]' was not found in application JSON`""
            return 2
        }

        if ($type.Equals("LOG_ANALYTICS")) {
            Write-Log "INFO" "isLogsOptionSelected = true"
            Write-Log "INFO" "logsParams = $params"

            $isLogsOptionSelected = $true
            Write-Run "`$script:logsParams = '$params'"
        } elseif ($type.Equals("METRICS")) {
            Write-Log "INFO" "isMetricsOptionSelected = true"
            Write-Log "INFO" "metricsParams = $params"

            $isMetricsOptionSelected = $true
            Write-Run "`$script:metricsParams = '$params'"
        } elseif ($type.Equals("TRACING")) {
            Write-Log "INFO" "isTracesOptionSelected = true"
            Write-Log "INFO" "tracesParams = $params"

            $isTracesOptionSelected = $true
            Write-Run "`$script:tracesParams = '$params'"
        }

        $index++
    }

    Write-Run "`$script:isLogsOptionSelected = `$$isLogsOptionSelected"
    Write-Run "`$script:isMetricsOptionSelected = `$$isMetricsOptionSelected"
    Write-Run "`$script:isTracesOptionSelected = `$$isTracesOptionSelected"
}

# Builds tolerations Helm sets
# Output:
#   helmSets - Contains all the Helm sets
# Error:
#   Exit Code 3
function Build-TolerationsHelmSets {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building tolerations Helm set ..."

    $local:isTaintParam = Find-Param "$using:generalParams" "isTaint"
    if ([string]::IsNullOrEmpty($isTaintParam)) {
        Write-Run "Write-Error `"installer.ps1 (3): isTaint param was not found`""
        return 3
    }

    $local:isTaintValue = Write-Output "$isTaintParam" | jq -r '.value'
    if ([string]::IsNullOrEmpty($isTaintValue)) {
        Write-Run "Write-Error `"installer.ps1 (3): '.configuration.subtypes[0].datasources[0].params[{name=isTaint}].value' is empty in application JSON`""
        return 3
    }
    if ($isTaintValue.Equals("null")) {
        Write-Run "Write-Error `"installer.ps1 (3): '.configuration.subtypes[0].datasources[0].params[{name=isTaint}].value' was not found in application JSON`""
        return 3
    }

    if (-Not $isTaintValue) {
        Write-Log "INFO" "isTaint value = false"
        return
    }
                    
    $local:items = kubectl get nodes -o json | jq -r '.items'
    if ([string]::IsNullOrEmpty($items)) {
        Write-Run "Write-Error `"installer.ps1 (3): '.items[]' is empty in kubectl get nodes JSON`""
        return 3
    }
    if ($items.Equals("null")) {
        Write-Run "Write-Error `"installer.ps1 (3): '.items[]' was not found in kubectl get nodes JSON`""
        return 3
    }

    $local:tolerationsSets = ""
    $local:index = 0
    $local:taints = Write-Output "$items" | jq -c '.[].spec | select(.taints!=null) | .taints[]'
    if ([string]::IsNullOrEmpty($taints)) {
        $taints = ""
    }

    foreach ($taint in $taints) {
        $local:key = Write-Output "$taint" | jq -r '.key'
        if ($key.Equals("null")) {
            Write-Run "Write-Error `"installer.ps1 (3): '.items[{item}].key' was not found in kubectl get nodes JSON`""
            return 3
        }

        $local:effect = Write-Output "$taint" | jq -r '.effect'
        if ($effect.Equals("null")) {
            Write-Run "Write-Error `"installer.ps1 (3): '.items[{item}].effect' was not found in kubectl get nodes JSON`""
            return 3
        }

        $local:operator = "Exists"
        $local:value = Write-Output "$taint" | jq -r '.value'
        if ($value.Equals("null")) {
            $operator = "Equal"

            if ($using:isLogsOptionSelected) {
                $tolerationsSets += " --set-string logzio-fluentd.daemonset.tolerations[$index].value=$value"
                $tolerationsSets += " --set-string logzio-fluentd.windowsDaemonset.tolerations[$index].value=$value"
            }
            if ($using:isMetricsOptionSelected -or $using:isTracesOptionSelected) {
                $tolerationsSets += " --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$index].value=$value"
                $tolerationsSets += " --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$index].value=$value"
                $tolerationsSets += " --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$index].value=$value"
                $tolerationsSets += " --set-string logzio-k8s-telemetry.tolerations[$index].value=$value"
            }
        }

        if ($using:isLogsOptionSelected) {
            $tolerationsSets += " --set-string logzio-fluentd.daemonset.tolerations[$index].key=$key"
            $tolerationsSets += " --set-string logzio-fluentd.daemonset.tolerations[$index].operator=$operator"
            $tolerationsSets += " --set-string logzio-fluentd.daemonset.tolerations[$index].effect=$effect"
            $tolerationsSets += " --set-string logzio-fluentd.windowsDaemonset.tolerations[$index].key=$key"
            $tolerationsSets += " --set-string logzio-fluentd.windowsDaemonset.tolerations[$index].operator=$operator"
            $tolerationsSets += " --set-string logzio-fluentd.windowsDaemonset.tolerations[$index].effect=$effect"
        }
        if ($using:isMetricsOptionSelected -or $using:isTracesOptionSelected) {
            $tolerationsSets += " --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$index].key=$key"
            $tolerationsSets += " --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$index].operator=$operator"
            $tolerationsSets += " --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$index].effect=$effect"
            $tolerationsSets += " --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$index].key=$key"
            $tolerationsSets += " --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$index].operator=$operator"
            $tolerationsSets += " --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$index].effect=$effect"
            $tolerationsSets += " --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$index].key=$key"
            $tolerationsSets += " --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$index].operator=$operator"
            $tolerationsSets += " --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$index].effect=$effect"
            $tolerationsSets += " --set-string logzio-k8s-telemetry.tolerations[$index].key=$key"
            $tolerationsSets += " --set-string logzio-k8s-telemetry.tolerations[$index].operator=$operator"
            $tolerationsSets += " --set-string logzio-k8s-telemetry.tolerations[$index].effect=$effect"
        }

        $index++
    }

    Write-Log "INFO" "tolerationsSets = $tolerationsSets"
    Write-Run "`$helmSets += '$tolerationsSets'"
}

# Builds enable metrics or traces Helm set
# Output:
#   helmSets - Contains all the Helm sets
function Build-EnableMetricsOrTracesHelmSet {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building enable metrics or traces Helm set ..."

    $local:helmSet = " --set metricsOrTraces.enabled=true"
    Write-Log "INFO" "helmSet = $helmSet"
    Write-Run "`$helmSets+='$helmSet'"
}

# Builds metrics/traces environment tag helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 4
function Build-EnvironmentTagHelmSet {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building environment tag Helm set ..."

    $local:envTag = jq -r '.id' $using:appJSON       ######################## Change the id to something else?
    if ([string]::IsNullOrEmpty($envTag)) {
        Write-Run "Write-Error `"installer.ps1 (4): '.id' is empty in application JSON`""
        return 4
    }
    if ($envTag.Equals("null")) {
        Write-Run "Write-Error `"installer.ps1 (4): '.id' was not found in application JSON`""
        return 4
    }

    $local:helmSet = " --set logzio-k8s-telemetry.secrets.p8s_logzio_name=$envTag"
    Write-Log "INFO" "helmSet = $helmSet"
    Write-Run "`$helmSets += '$helmSet'"
}

# Gets logs scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 5
function Get-LogsScripts {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting logs script file from logzio-agent-manifest repo ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/logs/windows/logs.ps1 -OutFile $using:logzioTempDir\logs.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"installer.ps1 (5): failed to get logs script file from logzio-agent-manifest repo.`n  $_`""
        return 5
    }


    Write-Log "INFO" "Getting logs functions script file from logzio-agent-manifest repo ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/logs/windows/functions.ps1 -OutFile $using:logzioTempDir\logs_functions.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"installer.ps1 (5): failed to get logs functions script file from logzio-agent-manifest repo.`n  $_`""
        return 5
    }
}

# Gets metrics scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 6
function Get-MetricsScripts {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting metrics script file from logzio-agent-manifest repo ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/metrics/windows/metrics.ps1 -OutFile $using:logzioTempDir\metrics.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"installer.ps1 (6): failed to get metrics script file from logzio-agent-manifest repo.`n  $_`""
        return 6
    }

    Write-Log "INFO" "Getting metrics functions script file from logzio-agent-manifest repo ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/metrics/windows/functions.ps1 -OutFile $using:logzioTempDir\metrics_functions.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"installer.ps1 (6): failed to get metrics functions script file from logzio-agent-manifest repo.`n  $_`""
        return 6
    }
}

# Gets traces scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 7
function Get-TracesScripts {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting traces script file from logzio-agent-manifest repo ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/traces/windows/traces.ps1 -OutFile $using:logzioTempDir\traces.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"installer.ps1 (7): failed to get traces script file from logzio-agent-manifest repo.`n  $_`""
        return 7
    }

    Write-Log "INFO" "Getting traces functions script file from logzio-agent-manifest repo ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/traces/windows/functions.ps1 -OutFile $using:logzioTempDir\traces_functions.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"installer.ps1 (7): failed to get traces functions script file from logzio-agent-manifest repo.`n  $_`""
        return 7
    }
}

# Runs Helm install
# Error:
#   Exit Code 8
function Invoke-HelmInstall {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Running Helm install ..."
    Write-Log "INFO" "helmSets = $using:helmSets"

    helm install -n monitoring $using:helmSets --create-namespace logzio-monitoring logzio-helm/logzio-monitoring 2>$using:taskErrorFile | Out-Null
    if ($?) {
        return
    }
        
    $local:err = Get-TaskError
    Write-Run "Write-Error `"installer.ps1 (8): failed to run Helm install.`n  $err`""
    return 8
}
