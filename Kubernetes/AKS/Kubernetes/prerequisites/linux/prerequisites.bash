#!/bin/bash

#################################################################################################################################
################################################## Prerequisites Linux Script ###################################################
#################################################################################################################################

# Load functions
echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Loading prerequisites functions ..." >> logzio_agent.log
source ./logzio-temp/prerequisites_functions.bash

# Check if kubectl is installed
execute_task "is_kubectl_installed" "is kubectl installed"

# Check if kubectl is connected to an active Kubernetes cluster
execute_task "is_kubectl_connected_to_k8s_cluster" "is kubectl connected to Kubernetes cluster"

# Check if Kubernetes cluster is connected to Logz.io logs
execute_task "is_k8s_cluster_connected_to_logzio_logs" "is Kubernetes cluster connected to Logz.io logs"

# Check if Kubernetes cluster is connected to Logz.io metrics
execute_task "is_k8s_cluster_connected_to_logzio_metrics" "is Kubernetes cluster connected to Logz.io metrics"

# Check if Helm is installed
execute_task "is_helm_installed" "is Helm installed"

# Add Logz.io Helm repo
execute_task "add_logzio_helm_repo" "adding Logz.io Helm repo"

# Update Logz.io Helm repo
execute_task "update_logzio_helm_repo" "updating Logz.io Helm repo"