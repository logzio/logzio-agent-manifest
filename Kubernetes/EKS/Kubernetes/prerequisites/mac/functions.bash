#!/bin/bash

#################################################################################################################################
################################################# Prerequisites Mac Functions ###################################################
#################################################################################################################################

# Checks if kubectl is installed
# Error:
#   Exit Code 1
function is_kubectl_installed () {
    write_log "INFO" "Checking if kubectl is installed ..."

    which kubectl >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        return
    fi

    write_run "print_error \"prerequisites.bash (1): kubectl is not installed. please install it and rerun the agent script\""
    return 1
}

# Checks if kubectl is connected to an active Kubernetes cluster
# Error:
#   Exit Code 2
function is_kubectl_connected_to_k8s_cluster () {
    write_log "INFO" "Checking if kubectl is connected to an active Kubernetes cluster ..."

    local cluster_info=$(kubectl cluster-info 2> $task_error_file)
    local err=$(cat $task_error_file)
    if [[ -z "$err" ]]; then
        write_log "INFO" "$cluster_info"
        return
    fi

    write_run "print_error \"prerequisites.bash (2): kubectl is not connected to an active Kubernetes cluster. please configure your computer to access a Kubernetes cluster and rerun the agent script.\n  $err\""
    return 2
}

# Deletes test pod from Kubernetes cluster
# Input:
#   pod_name - The name of the pod to delete
# Error:
#   Exit Code 3
function delete_test_pod () {
    local pod_name="$1"

    kubectl delete pod $pod_name >/dev/null 2>$task_error_file
    if [[ $? -eq 0 ]]; then
        return
    fi

    local err=$(cat $task_error_file)
    write_run "print_warning \"prerequisites.bash (3): failed to delete logzio-metrics-connection-test pod.\n  $err\""
}

# Checks if Kubernetes cluster can connect to Logz.io logs (port 8071)
# Error:
#   Exit Code 3
function can_k8s_cluster_connect_to_logzio_logs () {
    write_log "INFO" "Checking if Kubernetes cluster can connect to Logz.io logs (port 8071) ..."

    curl -fsSL $repo_path/prerequisites/logzio_logs_connection_test_pod.yaml > $logzio_temp_dir/logzio_logs_connection_test_pod.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (3): failed to get logzio logs connection test pod yaml file from logzio-agent-manifest repo.\n  $err\""
        return 3
    fi

    kubectl apply -f $logzio_temp_dir/logzio_logs_connection_test_pod.yaml >/dev/null 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (3): failed to create logzio-logs-connection-test pod.\n  $err\""
        return 3
    fi

    sleep 3

    local pod_logs=$(kubectl logs logzio-logs-connection-test 2>$task_error_file)
    local err=$(cat $task_error_file)
    if [[ ! -z "$err" ]]; then
        delete_test_pod "logzio-logs-connection-test"
        write_run "print_error \"prerequisites.bash (3): failed to get logs of logzio-logs-connection-test pod.\n  $err\""
        return 3
    fi
    if [[ "$pod_logs" = "Connected to listener.logz.io" ]]; then
        delete_test_pod "logzio-logs-connection-test"
        return
    fi

    delete_test_pod "logzio-logs-connection-test"
    write_run "print_error \"prerequisites.bash (3): Kubernetes cluster cannot connect to Logz.io logs. please check your Kubernetes cluster network for port 8071\""
    return 3
}

# Checks if Kubernetes cluster can connect to Logz.io metrics (port 8053)
# Error:
#   Exit Code 3
function can_k8s_cluster_connect_to_logzio_metrics () {
    write_log "INFO" "Checking if Kubernetes cluster can connect to Logz.io metrics (port 8053) ..."

    curl -fsSL $repo_path/prerequisites/logzio_metrics_connection_test_pod.yaml > $logzio_temp_dir/logzio_metrics_connection_test_pod.yaml 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (3): failed to get logzio metrics connection test pod yaml file from logzio-agent-manifest repo.\n  $err\""
        return 3
    fi

    kubectl apply -f $logzio_temp_dir/logzio_metrics_connection_test_pod.yaml >/dev/null 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (3): failed to create logzio-metrics-connection-test pod.\n  $err\""
        return 3
    fi

    sleep 3

    local pod_logs=$(kubectl logs logzio-metrics-connection-test 2>$task_error_file)
    local err=$(cat $task_error_file)
    if [[ ! -z "$err" ]]; then
        delete_test_pod "logzio-metrics-connection-test"
        write_run "print_error \"prerequisites.bash (3): failed to get logs of logzio-metrics-connection-test pod.\n  $err\""
        return 3
    fi
    if [[ "$pod_logs" = "Connected to listener.logz.io" ]]; then
        delete_test_pod "logzio-metrics-connection-test"
        return
    fi

    delete_test_pod "logzio-metrics-connection-test"
    write_run "print_error \"prerequisites.bash (3): Kubernetes cluster cannot connect to Logz.io metrics. please check your Kubernetes cluster network for port 8053\"" >> logzio-temp/run
    return 3
}

# Checks if Helm is installed
# Error:
#   Exit Code 4
function is_helm_installed () {
    write_log "INFO" "Checking if Helm is installed ..."

    which helm >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        return
    fi

    write_log "INFO" "Installing Helm ..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash >/dev/null 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (4): failed to install Helm.\n  $err\""
        return 4
    fi
}

# Adds Logz.io Helm repo
# Error:
#   Exit Code 5
function add_logzio_helm_repo () {
    write_log "INFO" "Adding Logz.io Helm repo ..."

    helm repo add logzio-helm https://logzio.github.io/logzio-helm >/dev/null 2>$task_error_file
    if [[ $? -eq 0 ]]; then
        return
    fi

    local err=$(cat $task_error_file)
    write_run "print_error \"prerequisites.bash (5): failed to add Logz.io Helm repo.\n  $err\""
    return 5
}

# Updates Logz.io Helm repo
# Error:
#   Exit Code 6
function update_logzio_helm_repo () {
    write_log "INFO" "Updating Logz.io Helm repo ..."
    
    helm repo update >/dev/null 2>$task_error_file
    if [[ $? -eq 0 ]]; then
        return
    fi

    local err=$(cat $task_error_file)
    write_run "print_error \"prerequisites.bash (6): failed to update Logz.io Helm repo.\n  $err\""
    return 6
}
