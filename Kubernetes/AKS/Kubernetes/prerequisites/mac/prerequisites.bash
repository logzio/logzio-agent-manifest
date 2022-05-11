#!/bin/bash

#################################################################################################################################
################################################### Prerequisites Mac Script ####################################################
#################################################################################################################################

# Load functions
echo -e "[INFO] Loading prerequisites functions ..." >> logzio_agent.log
source ./logzio-temp/prerequisites_functions.bash

# Check if kubectl is installed
execute_task "is_kubectl_installed" "is kubectl installed"

# Check if kubectl is connected to an active Kubernetes cluster
execute_task "is_kubectl_connected_to_k8s_cluster" "is kubectl connected to Kubernetes cluster"

# Add Logz.io Helm repo
execute_task "add_logzio_helm_repo" "adding Logz.io Helm repo"

# Update Logz.io Helm repo
execute_task "update_logzio_helm_repo" "updating Logz.io Helm repo"