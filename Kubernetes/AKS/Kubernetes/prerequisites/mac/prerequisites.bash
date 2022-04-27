#!/bin/bash

#################################################################################################################################
################################################### Prerequisites Mac Script ####################################################
#################################################################################################################################

# Load functions
source ./logzio-temp/prerequisites_functions.bash

# Check if Kubectl is installed
execute_task "is_kubectl_installed" "is kubectl installed"

# Check if Kubectl is connected to an active Kubernetes cluster
execute_task "is_kubectl_connected_to_k8s_cluster" "is kubectl connected to k8s cluster"

# Add Logz.io Helm repo
execute_task "add_logzio_helm_repo" "adding Logz.io helm repo"

# Update Logz.io Helm repo
execute_task "update_logzio_helm_repo" "updating Logz.io helm repo"