#################################################################################################################################
############################################### Prerequisites Windows Functions #################################################
#################################################################################################################################

# Checks if kubectl is installed
# Error:
#   Exit Code 1
function Test-IsKubectlInstalled {
    Write-Log "INFO" "Checking if kubectl is installed ..."

    Get-Command kubectl 2>&1 | Out-Null
    if ($?) {
        return
    }

    Write-Run "Write-Error `"prerequisites.ps1 (1): kubectl is not installed`""
    return 1
}

# Checks if kubectl is connected to an active Kubernetes cluster
# Error:
#   Exit Code 2
function Test-IsKubectlConnectedToKubernetesCluster () {
    Write-Log "INFO" "Checking if kubectl is connected to an active Kubernetes cluster ..."

    kubectl cluster-info > logzio-temp/task_result 2>&1
    if ($?) {
        Get-Content logzio-temp/task_result >> logzio_agent.log
        return
    }

    Get-Content logzio-temp/task_result >> logzio_agent.log

    #echo -e "cat logzio-temp/task_result" > logzio-temp/run
    Write-Run "Write-Error `"prerequisites.ps1 (2): kubectl is not connected to an active Kubernetes cluster`""
    return 2
}

<#
# Checks if Kubernetes cluster can connect to Logz.io logs (port 8071)
# Error:
#   Exit Code 3
function can_k8s_cluster_connect_to_logzio_logs () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Checking if Kubernetes cluster can connect to Logz.io logs (port 8071) ..." >> logzio_agent.log

    curl -fsSL $repo_path/prerequisites/logzio_logs_connection_test_pod.yaml > logzio-temp/logzio_logs_connection_test_pod.yaml 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"prerequisites.script (3): failed to get logzio logs connection test pod yaml file from logzio-agent-manifest repo\"" >> logzio-temp/run
        return 3
    fi

    kubectl apply -f logzio-temp/logzio_logs_connection_test_pod.yaml >/dev/null 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"prerequisites.script (3): failed to create logzio-logs-connection-test pod\"" >> logzio-temp/run
        return 3
    fi

    sleep 3

    local pod_logs=$(kubectl logs logzio-logs-connection-test 2>logzio-temp/task_result)
    local result=$(cat logzio-temp/task_result)
    if [[ ! -z "$result" ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"prerequisites.script (3): failed to get logs of logzio-logs-connection-test pod\"" >> logzio-temp/run
        return 3
    fi
    if [[ "$pod_logs" = "Connected to listener.logz.io" ]]; then
        kubectl delete pod logzio-logs-connection-test >/dev/null 2>logzio-temp/task_result
        if [[ $? -ne 0 ]]; then
            cat logzio-temp/task_result >> logzio_agent.log

            echo -e "cat logzio-temp/task_result" > logzio-temp/run
            echo -e "print_warning \"prerequisites.script (3): failed to delete logzio-logs-connection-test pod\"" >> logzio-temp/run
        fi

        return
    fi

    kubectl delete pod logzio-logs-connection-test >/dev/null 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_warning \"prerequisites.script (3): failed to delete logzio-logs-connection-test pod\"" >> logzio-temp/run
    fi

    echo -e "print_error \"prerequisites.bash (3): Kubernetes cluster cannot connect to Logz.io logs (port 8071)\"" >> logzio-temp/run
    return 3
}

# Checks if Kubernetes cluster can connect to Logz.io metrics (port 8053)
# Error:
#   Exit Code 3
function can_k8s_cluster_connect_to_logzio_metrics () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Checking if Kubernetes cluster can connect to Logz.io metrics (port 8053) ..." >> logzio_agent.log

    curl -fsSL $repo_path/prerequisites/logzio_metrics_connection_test_pod.yaml > logzio-temp/logzio_metrics_connection_test_pod.yaml 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"prerequisites.script (3): failed to get logzio metrics connection test pod yaml file from logzio-agent-manifest repo\"" >> logzio-temp/run
        return 3
    fi

    kubectl apply -f logzio-temp/logzio_metrics_connection_test_pod.yaml >/dev/null 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"prerequisites.script (3): failed to create logzio-metrics-connection-test pod\"" >> logzio-temp/run
        return 3
    fi

    sleep 3

    local pod_logs=$(kubectl logs logzio-metrics-connection-test 2>logzio-temp/task_result)
    local result=$(cat logzio-temp/task_result)
    if [[ ! -z "$result" ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"prerequisites.script (3): failed to get logs of logzio-metrics-connection-test pod\"" >> logzio-temp/run
        return 3
    fi
    if [[ "$pod_logs" = "Connected to listener.logz.io" ]]; then
        kubectl delete pod logzio-metrics-connection-test >/dev/null 2>logzio-temp/task_result
        if [[ $? -ne 0 ]]; then
            cat logzio-temp/task_result >> logzio_agent.log

            echo -e "cat logzio-temp/task_result" > logzio-temp/run
            echo -e "print_warning \"prerequisites.script (3): failed to delete logzio-metrics-connection-test pod\"" >> logzio-temp/run
        fi

        return
    fi

    kubectl delete pod logzio-metrics-connection-test >/dev/null 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_warning \"prerequisites.script (3): failed to delete logzio-metrics-connection-test pod\"" >> logzio-temp/run
    fi

    echo -e "print_error \"prerequisites.bash (3): Kubernetes cluster cannot connect to Logz.io metrics (port 8053)\"" >> logzio-temp/run
    return 3
}

# Checks if Helm is installed
# Error:
#   Exit Code 4
function is_helm_installed () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Checking if Helm is installed ..." >> logzio_agent.log

    which helm >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        return
    fi

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Installing Helm ..." >> logzio_agent.log
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash > logzio-temp/task_result 2>&1
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"prerequisites.bash (4): failed to install Helm\"" >> logzio-temp/run
        return 4
    fi
}

# Adds Logz.io Helm repo
# Error:
#   Exit Code 5
function add_logzio_helm_repo () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Adding Logz.io Helm repo ..." >> logzio_agent.log

    helm repo add logzio-helm https://logzio.github.io/logzio-helm > logzio-temp/task_result 2>&1
    if [[ $? -eq 0 ]]; then
        return
    fi

    cat logzio-temp/task_result >> logzio_agent.log

    echo -e "cat logzio-temp/task_result" > logzio-temp/run
    echo -e "print_error \"prerequisites.bash (5): failed to add Logz.io Helm repo\"" >> logzio-temp/run
    return 5
}

# Updates Logz.io Helm repo
# Error:
#   Exit Code 6
function update_logzio_helm_repo () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Updating Logz.io Helm repo ..." >> logzio_agent.log
    
    helm repo update logzio-helm > logzio-temp/task_result 2>&1
    if [[ $? -eq 0 ]]; then
        return
    fi

    cat logzio-temp/task_result >> logzio_agent.log

    echo -e "cat logzio-temp/task_result" > logzio-temp/run
    echo -e "print_error \"prerequisites.bash (6): failed to update Logz.io Helm repo\"" >> logzio-temp/run
    return 6
}#>
