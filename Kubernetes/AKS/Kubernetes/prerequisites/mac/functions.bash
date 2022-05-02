#!/bin/bash

#################################################################################################################################
################################################# Prerequisites Mac Functions ###################################################
#################################################################################################################################

# Checks if kubectl is installed
# Error:
#   Exit Code 1
function is_kubectl_installed () {
    which kubectl >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        return
    fi

    echo -e "print_error \"prerequisites (1): kubectl is not installed\"" > logzio-temp/run
    return 1
}

# Checks if kubectl is connected to an active Kubernetes cluster
# Error:
#   Exit Code 2
function is_kubectl_connected_to_k8s_cluster () {
    kubectl cluster-info > logzio-temp/task_result 2>&1
    if [ $? -eq 0 ]; then
        return
    fi

    local result=$(cat logzio-temp/task_result)
    echo -e "echo -e \"$result\"" > logzio-temp/run
    echo -e "print_error \"prerequisites (2): kubectl is not connected to an active Kubernetes cluster\"" >> logzio-temp/run
    return 2
}

# Checks if Helm is installed
# Error:
#   Exit Code 3
function is_helm_installed () {
    which helm >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        return
    fi

    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash > logzio-temp/task_result 2>&1
    if [ $? -ne 0 ]; then
        local result=$(cat logzio-temp/task_result)
        echo -e "echo -e \"$result\"" > logzio-temp/run
        echo -e "print_error \"prerequisites (3): failed to install Helm\"" >> logzio-temp/run
        return 3
    fi
}

# Adds Logz.io Helm repo
# Error:
#   Exit Code 4
function add_logzio_helm_repo () {
    helm repo add logzio-helm https://logzio.github.io/logzio-helm > logzio-temp/task_result 2>&1
    if [ $? -eq 0 ]; then
        return
    fi

    local result=$(cat logzio-temp/task_result)
    echo -e "echo -e \"$result\"" > logzio-temp/run
    echo -e "print_error \"prerequisites (4): failed to add Logz.io Helm repo\"" >> logzio-temp/run
    return 4
}

# Updates Logz.io Helm repo
# Error:
#   Exit Code 5
function update_logzio_helm_repo () {
    helm repo update logzio-helm > logzio-temp/task_result 2>&1
    if [ $? -eq 0 ]; then
        return
    fi

    local result=$(cat logzio-temp/task_result)
    echo -e "echo -e \"$result\"" > logzio-temp/run
    echo -e "print_error \"prerequisites (4): failed to update Logz.io Helm repo\"" >> logzio-temp/run
    return 5
}