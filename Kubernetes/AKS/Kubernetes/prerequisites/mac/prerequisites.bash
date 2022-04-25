#!/bin/bash

#################################################################################################################################
################################################### Prerequisites Mac Script ####################################################
#################################################################################################################################

# Load functions
source ./prerequisites_functions.bash

# Check if Kubectl is installed
is_kubectl_installed

# Check if Kubectl is connected to an active Kubernetes cluster
is_kubectl_connected_to_k8s_cluster

# Add Logz.io Helm repo
add_logzio_helm_repo

# Update Logz.io Helm repo
update_logzio_helm_repo