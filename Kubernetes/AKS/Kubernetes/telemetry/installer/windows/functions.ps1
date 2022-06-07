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
    if ($generalParams.Equals("null")) {
        Write-Run "Write-Error `"installer.ps1 (1): .configuration.subtypes[0].datasources[0].params[] was not found in application JSON`""
        return 1
    }
    if ([string]::IsNullOrEmpty($generalParams)) {
        Write-Run "Write-Error `"installer.ps1 (1): '.configuration.subtypes[0].datasources[0].params[]' is empty in application JSON`""
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
    if ($telemetries.Equals("null")) {
        Write-Run "Write-Error `"installer.ps1 (2): .configuration.subtypes[0].datasources[0].telemetries[] was not found in application JSON`""
        return 2
    }
    if ([string]::IsNullOrEmpty($telemetries)) {
        Write-Run "Write-Error `"installer.ps1 (2): .configuration.subtypes[0].datasources[0].telemetries[] is empty in application JSON`""
        return 2
    }

    $local:isLogsOptionSelected = $false
    $local:isMetricsOptionSelected = $false
    $local:isTracesOptionSelected = $false
    $local:index = 0

    foreach ($telemetry in $telemetries) {
        $local:type = Write-Output "$telemetry" | jq -r '.type'
        if ($type.Equals("null")) {
            Write-Run "Write-Error `"installer.ps1 (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' was not found in application JSON`""
            return 2
        }
        if ([string]::IsNullOrEmpty($type)) {
            Write-Run "Write-Error `"installer.ps1 (2): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' is empty in application JSON`""
            return 2
        }

        $local:params = Write-Output "$telemetry" | jq -r '.params[]'
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

    Write-Run "`$script:isLogsOptionSelected = $isLogsOptionSelected"
    Write-Run "`$script:isMetricsOptionSelected = $isMetricsOptionSelected"
    Write-Run "`$script:isTracesOptionSelected = $isTracesOptionSelected"
}

# Builds tolerations Helm sets
# Output:
#   helmSets - Contains all the Helm sets
# Error:
#   Exit Code 3
function Build-TolerationsHelmSets {
    Write-Log "INFO" "Building tolerations Helm set ..."

    $local:isTaintParam = Find-Param "$generalParams" "isTaint"
    if ([string]::IsNullOrEmpty($isTaintParam)) {
        Write-Run "Write-Error `"installer.ps1 (3): isTaint param was not found`""
        return 3
    }

    $local:isTaintValue = Write-Output "$isTaintParam" | jq -r '.value'
    if ($isTaintValue.Equals("null")) {
        Write-Run "Write-Error `"installer.ps1 (3): '.configuration.subtypes[0].datasources[0].params[{name=isTaint}].value' was not found in application JSON`""
        return 3
    }
    if ([string]::IsNullOrEmpty($isTaintValue)) {
        Write-Run "Write-Error `"installer.ps1 (3): '.configuration.subtypes[0].datasources[0].params[{name=isTaint}].value' is empty in application JSON`""
        return 3
    }

    if (-Not $isTaintValue) {
        Write-Log "INFO" "isTaint value = false"
        return
    }
                    
    $local:items = kubectl get nodes -o json | jq -r '.items'
    if ($items.Equals("null")) {
        Write-Run "Write-Error `"installer.ps1 (3): '.items[]' was not found in kubectl get nodes JSON`""
        return 3
    }

    $local:tolerationsSets = ""
    $local:index = 0
    $local:taints = Write-Output "$items" | jq -c '.[].spec | select(.taints!=null) | .taints[]'

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

            if ($isLogsOptionSelected) {
                $tolerationsSets += " --set-string logzio-fluentd.daemonset.tolerations[$index].value=$value"
                $tolerationsSets += " --set-string logzio-fluentd.windowsDaemonset.tolerations[$index].value=$value"
            }
            if ($isMetricsOptionSelected -or $isTracesOptionSelected) {
                $tolerationsSets += " --set-string logzio-k8s-telemetry.prometheus-pushgateway.tolerations[$index].value=$value"
                $tolerationsSets += " --set-string logzio-k8s-telemetry.prometheus-node-exporter.tolerations[$index].value=$value"
                $tolerationsSets += " --set-string logzio-k8s-telemetry.kube-state-metrics.tolerations[$index].value=$value"
                $tolerationsSets += " --set-string logzio-k8s-telemetry.tolerations[$index].value=$value"
            }
        }

        if ($isLogsOptionSelected) {
            $tolerationsSets += " --set-string logzio-fluentd.daemonset.tolerations[$index].key=$key"
            $tolerationsSets += " --set-string logzio-fluentd.daemonset.tolerations[$index].operator=$operator"
            $tolerationsSets += " --set-string logzio-fluentd.daemonset.tolerations[$index].effect=$effect"
            $tolerationsSets += " --set-string logzio-fluentd.windowsDaemonset.tolerations[$index].key=$key"
            $tolerationsSets += " --set-string logzio-fluentd.windowsDaemonset.tolerations[$index].operator=$operator"
            $tolerationsSets += " --set-string logzio-fluentd.windowsDaemonset.tolerations[$index].effect=$effect"
        }
        if ($isMetricsOptionSelected -or $isTracesOptionSelected) {
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

<#
# Builds enable metrics or traces Helm set
# Output:
#   helm_sets - Contains all the Helm sets
function build_enable_metrics_or_traces_helm_set () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Building enable metrics or traces Helm set ..." >> logzio_agent.log

    local helm_set+=" --set metricsOrTraces.enabled=true"
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] helm_set = $helm_set" >> logzio_agent.log
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run
}

# Builds metrics/traces environment tag helm set
# Output:
#   helm_sets - Contains all the Helm sets
# Error:
#   Exit Code 4
function build_environment_tag_helm_set () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Building environment tag Helm set ..." >> logzio_agent.log

    local env_tag=$(jq -r '.id' logzio-temp/app.json)       ######################## Change the id to something else?
    if [[ "$env_tag" = null ]]; then
        echo -e "print_error \"installer.bash (4): '.id' was not found in application JSON\"" > logzio-temp/run
        return 4
    fi
    if [[ -z "$env_tag" ]]; then
        echo -e "print_error \"installer.bash (4): '.id' is empty in application JSON\"" > logzio-temp/run
        return 4
    fi

    local helm_set=" --set logzio-k8s-telemetry.secrets.p8s_logzio_name=$env_tag"
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] helm_set = $helm_set" >> logzio_agent.log
    echo -e "helm_sets+='$helm_set'" > logzio-temp/run
}

# Gets logs scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 5
function get_logs_scripts () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting logs script file from logzio-agent-manifest repo ..." >> logzio_agent.log
    curl -fsSL $repo_path/telemetry/logs/mac/logs.bash > logzio-temp/logs.bash 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"installer.script (5): failed to get logs script file from logzio-agent-manifest repo\"" >> logzio-temp/run
        return 5
    fi

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting logs functions script file from logzio-agent-manifest repo ..." >> logzio_agent.log
    curl -fsSL $repo_path/telemetry/logs/mac/functions.bash > logzio-temp/logs_functions.bash 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"installer.script (5): failed to get logs functions script file from logzio-agent-manifest repo\"" >> logzio-temp/run
        return 5
    fi
}

# Gets metrics scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 6
function get_metrics_scripts () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting metrics script file from logzio-agent-manifest repo ..." >> logzio_agent.log
    curl -fsSL $repo_path/telemetry/metrics/mac/metrics.bash > logzio-temp/metrics.bash 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"installer.script (6): failed to get metrics script file from logzio-agent-manifest repo\"" >> logzio-temp/run
        return 6
    fi

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting metrics functions script file from logzio-agent-manifest repo ..." >> logzio_agent.log
    curl -fsSL $repo_path/telemetry/metrics/mac/functions.bash > logzio-temp/metrics_functions.bash 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"installer.script (6): failed to get metrics functions script file from logzio-agent-manifest repo\"" >> logzio-temp/run
        return 6
    fi
}

# Gets traces scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 7
function get_traces_scripts () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting traces script file from logzio-agent-manifest repo ..." >> logzio_agent.log
    curl -fsSL $repo_path/telemetry/traces/mac/traces.bash > logzio-temp/traces.bash 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"installer.script (7): failed to get traces script file from logzio-agent-manifest repo\"" >> logzio-temp/run
        return 7
    fi

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting traces functions script file from logzio-agent-manifest repo ..." >> logzio_agent.log
    curl -fsSL $repo_path/telemetry/traces/mac/functions.bash > logzio-temp/traces_functions.bash 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"installer.script (7): failed to get traces functions script file from logzio-agent-manifest repo\"" >> logzio-temp/run
        return 7
    fi
}

# Runs Helm install
# Error:
#   Exit Code 8
function run_helm_install () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Running Helm install ..." >> logzio_agent.log
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] helm_sets = $helm_sets" >> logzio_agent.log

    helm install -n monitoring $helm_sets --create-namespace logzio-monitoring logzio-helm/logzio-monitoring > logzio-temp/task_result 2>&1
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"installer.bash (8): failed to run Helm install\"" >> logzio-temp/run
        return 8
    fi
}#>
