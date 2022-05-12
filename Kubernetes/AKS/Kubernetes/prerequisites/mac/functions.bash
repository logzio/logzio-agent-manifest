#!/bin/bash

#################################################################################################################################
################################################# Prerequisites Mac Functions ###################################################
#################################################################################################################################

# Checks if kubectl is installed
# Error:
#   Exit Code 1
function is_kubectl_installed () {
    echo -e "[INFO] Checking if kubectl is installed ..." >> logzio_agent.log

    which kubectl >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        return
    fi

    echo -e "print_error \"prerequisites.bash (1): kubectl is not installed\"" > logzio-temp/run
    return 1
}

# Checks if kubectl is connected to an active Kubernetes cluster
# Error:
#   Exit Code 2
function is_kubectl_connected_to_k8s_cluster () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Checking if kubectl is connected to an active Kubernetes cluster ..." >> logzio_agent.log

    kubectl cluster-info > logzio-temp/task_result 2>&1
    if [ $? -eq 0 ]; then
        cat logzio-temp/task_result >> logzio_agent.log
        return
    fi

    cat logzio-temp/task_result >> logzio_agent.log

    echo -e "cat logzio-temp/task_result" > logzio-temp/run
    echo -e "print_error \"prerequisites.bash (2): kubectl is not connected to an active Kubernetes cluster\"" >> logzio-temp/run
    return 2
}

# Checks if Helm is installed
# Error:
#   Exit Code 3
function is_helm_installed () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Checking if Helm is installed ..." >> logzio_agent.log

    which helm >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        return
    fi

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Installing Helm ..." >> logzio_agent.log
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash > logzio-temp/task_result 2>&1
    if [ $? -ne 0 ]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"prerequisites.bash (3): failed to install Helm\"" >> logzio-temp/run
        return 3
    fi
}

# Adds Logz.io Helm repo
# Error:
#   Exit Code 4
function add_logzio_helm_repo () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Adding Logz.io Helm repo ..." >> logzio_agent.log

    helm repo add logzio-helm https://logzio.github.io/logzio-helm > logzio-temp/task_result 2>&1
    if [ $? -eq 0 ]; then
        return
    fi

    cat logzio-temp/task_result >> logzio_agent.log

    echo -e "cat logzio-temp/task_result" > logzio-temp/run
    echo -e "print_error \"prerequisites.bash (4): failed to add Logz.io Helm repo\"" >> logzio-temp/run
    return 4
}

# Updates Logz.io Helm repo
# Error:
#   Exit Code 5
function update_logzio_helm_repo () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Updating Logz.io Helm repo ..." >> logzio_agent.log
    
    helm repo update logzio-helm > logzio-temp/task_result 2>&1
    if [ $? -eq 0 ]; then
        return
    fi

    cat logzio-temp/task_result >> logzio_agent.log

    echo -e "cat logzio-temp/task_result" > logzio-temp/run
    echo -e "print_error \"prerequisites.bash (5): failed to update Logz.io Helm repo\"" >> logzio-temp/run
    return 5
}
