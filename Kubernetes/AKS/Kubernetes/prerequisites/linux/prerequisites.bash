#!/bin/bash

#################################################################################################################################
################################################## Prerequisites Linux Script ###################################################
#################################################################################################################################

# Load functions
echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Loading prerequisites functions ..." >> logzio_agent.log
source ./logzio-temp/prerequisites_functions.bash

# Check if kubectl is installed
execute_task "is_kubectl_installed" "checking if kubectl is installed"

# Check if kubectl is connected to an active Kubernetes cluster
execute_task "is_kubectl_connected_to_k8s_cluster" "checking if kubectl is connected to Kubernetes cluster"

# Check if Kubernetes cluster can connect to Logz.io logs (port 8071)
execute_task "can_k8s_cluster_connect_to_logzio_logs" "checking if Kubernetes cluster can connect to Logz.io logs"

# Check if Kubernetes cluster can connect to Logz.io metrics (port 8053)
execute_task "can_k8s_cluster_connect_to_logzio_metrics" "checking if Kubernetes cluster can connect to Logz.io metrics"

# Check if Helm is installed
execute_task "is_helm_installed" "checking if Helm is installed"

# Add Logz.io Helm repo
execute_task "add_logzio_helm_repo" "adding Logz.io Helm repo"

# Update Logz.io Helm repo
execute_task "update_logzio_helm_repo" "updating Logz.io Helm repo"