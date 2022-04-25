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
        print_error "prerequisites (1): Kubectl is not installed"
        print_progress_bar false
        exit 1
    fi

    print_success "kubectl is already installed"
    print_progress_bar true
}

# Checks if Kubectl is connected to an active Kubernetes cluster
# Error:
#   Status Code 2
function is_kubectl_connected_to_k8s_cluster () {
    kubectl cluster-info
    if [ $? -ne 0 ]; then,
        print_error "prerequisites (2): Kubectl is not connected to an active Kubernetes cluster"
        print_progress_bar false
        exit 2
    fi

    print_success "Kubectl is connected to an active Kubernetes cluster"
    print_progress_bar true
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
            print_error "prerequisites (3): failed to install Helm"
            print_progress_bar false
            exit 3
        fi
    fi

    print_success "Helm is already installed"
    print_progress_bar true
}

# Adds Logz.io Helm repo
# Error:
#   Status Code 4
function add_logzio_helm_repo () {
    echo "Adding Logz.io Helm repo..."
    helm repo add logzio-helm https://logzio.github.io/logzio-helm
    if [ $? -ne 0 ]; then
        print_error "prerequisites (4): failed to add Logz.io Helm repo"
        print_progress_bar false
        exit 4
    fi

    print_progress_bar true
}

# Updates Logz.io Helm repo
# Error:
#   Status Code 5
function update_logzio_helm_repo () {
    echo "Updating Logz.io Helm repo..."
    helm repo update logzio-helm
    if [ $? -ne 0 ]; then
        print_error "prerequisites (4): failed to update Logz.io Helm repo"
        print_progress_bar false
        exit 5
    fi

    print_progress_bar true
}