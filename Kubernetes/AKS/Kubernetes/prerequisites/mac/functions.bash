#!/bin/bash

#################################################################################################################################
################################################# Prerequisites Mac Functions ###################################################
#################################################################################################################################

# Checks if Kubectl is installed
# Error:
#   Status Code 1
function is_kubectl_installed () {
    which kubectl >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "prerequisites (1): Kubectl is not installed"
        exit 1
    fi

    echo "kubectl is already installed"
    print_progressbar_status
}

# Checks if Kubectl is connected to an active Kubernetes cluster
# Error:
#   Status Code 2
function is_kubectl_connected_to_k8s_cluster () {
    kubectl cluster-info
    if [ $? -ne 0 ]; then,
        echo "prerequisites (2): Kubectl is not connected to an active Kubernetes cluster"
        exit 2
    fi

    echo "Kubectl is connected to an active Kubernetes cluster"
    print_progressbar_status
}

# Checks if Helm is installed
# Error:
#   Status Code 3
function is_helm_installed () {
    which helm >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        if [ $? -ne 0 ]; then
            echo "prerequisites (3): failed to install Helm"
        fi
    fi

    echo "Helm is already installed"
    print_progressbar_status
}

# Adds Logz.io Helm repo
# Error:
#   Status Code 4
function add_logzio_helm_repo () {
    echo "Adding Logz.io Helm repo..."
    helm repo add logzio-helm https://logzio.github.io/logzio-helm
    if [ $? -ne 0 ]; then
        echo "prerequisites (4): failed to add Logz.io Helm repo"
    fi

    print_progressbar_status
}

# Updates Logz.io Helm repo
# Error:
#   Status Code 5
function update_logzio_helm_repo () {
    echo "Updating Logz.io Helm repo..."
    helm repo update logzio-helm
    if [ $? -ne 0 ]; then
        echo "prerequisites (4): failed to update Logz.io Helm repo"
    fi

    print_progressbar_status
}