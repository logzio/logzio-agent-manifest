#!/bin/bash

#################################################################################################################################
############################################## LINUX Subtype Prerequisites Script ###############################################
#################################################################################################################################

# Print title
echo
echo -e '#####################'
echo -e "###$PURPLE_COLOR Prerequisites $WHITE_COLOR###"
echo -e '#####################'

EXIT_CODE=1

# Load subtype prerequisites utils functions
load_prerequisites_utils

# Check if kubectl is installed
execute_task 'is_kubectl_installed' 'Checking if kubectl is installed'
# Check if kubectl is connected to an active Kubernetes cluster
execute_task 'is_kubectl_connected_to_kubernetes_cluster' 'Checking if kubectl is connected to Kubernetes cluster'
# Set Logz.io listener url in test pod yamls
execute_task 'set_logzio_listener_url_in_test_pod_yamls' 'Setting Logz.io listener url in test pod yamls'
# Check if Kubernetes cluster can connect to Logz.io logs (port 8071)
execute_task 'can_kubernetes_cluster_connect_to_logzio_logs' 'Checking if Kubernetes cluster can connect to Logz.io logs'
# Check if Kubernetes cluster can connect to Logz.io metrics (port 8053)
execute_task 'can_kubernetes_cluster_connect_to_logzio_metrics' 'Checking if Kubernetes cluster can connect to Logz.io metrics'
# Check if Helm is installed and install Helm if not installed
execute_task 'is_helm_installed' 'Checking if Helm is installed'
# Add Logz.io Helm repo
execute_task 'add_logzio_helm_repo' 'Adding Logz.io Helm repo'
# Update Logz.io Helm repo
execute_task 'update_logzio_helm_repo' 'Updating Logz.io Helm repo'
