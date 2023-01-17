#!/bin/bash

#################################################################################################################################
############################################## LINUX Subtype Prerequisites Script ###############################################
#################################################################################################################################

# Checks if kubectl is installed
# Input:
#   ---
# Output:
#   ---
function is_kubectl_installed {
    local exit_code=1
    local func_name="${FUNCNAME[0]}"

    local message='Checking if kubectl is installed ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    which kubectl >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        message="prerequisites.bash ($exit_code): 'kubectl' is not installed. please install it and rerun the agent"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Checks if kubectl is connected to an active Kubernetes cluster
# Input:
#   ---
# Output:
#   ---
function is_kubectl_connected_to_kubernetes_cluster {
    local exit_code=2
    local func_name="${FUNCNAME[0]}"

    local message='Checking if kubectl is connected to an active Kubernetes cluster ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local cluster_info
    cluster_info=$(kubectl cluster-info 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        message="prerequisites.bash ($exit_code): 'kubectl' is not connected to an active Kubernetes cluster. please configure your computer to access a Kubernetes cluster and rerun the agent: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    cluster_info=$(echo -e "$cluster_info" | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' | head -n -2)

    message="Kubernetes cluster info: $cluster_info"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
}

# Sets Logz.io listener url in test pod yamls
# Input:
#   ---
# Output:
#   ---
function set_logzio_listener_url_in_test_pod_yamls {
    local exit_code=3
    local func_name="${FUNCNAME[0]}"

    local message='Setting Logz.io listener url in test pod yamls ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    add_yaml_file_field_value "$KUBERNETES_RESOURCES_DIR/logzio_logs_connection_test_pod.yaml" '.spec.containers[0].command' "telnet $LISTENER_URL 8071"
    if [[ $? -ne 0 ]]; then
        message="prerequisites.bash ($exit_code): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    add_yaml_file_field_value "$KUBERNETES_RESOURCES_DIR/logzio_metrics_connection_test_pod.yaml" '.spec.containers[0].command' "telnet $LISTENER_URL 8053"
    if [[ $? -ne 0 ]]; then
        message="prerequisites.bash ($exit_code): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Checks if Kubernetes cluster can connect to Logz.io logs (port 8071)
# Input:
#   ---
# Output:
#   ---
function can_kubernetes_cluster_connect_to_logzio_logs {
    local exit_code=4
    local func_name="${FUNCNAME[0]}"

    local message='Checking if Kubernetes cluster can connect to Logz.io logs (port 8071) ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    can_kubernetes_cluster_connect_to_logzio "logzio_logs_connection_test_pod.yaml" "logzio-logs-connection-test"
    if [[ $? -ne 0 ]]; then
        message="prerequisites.bash ($exit_code): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    if ! $IS_CONNECTED_TO_LOGZIO; then
        message="prerequisites.bash ($exit_code): Kubernetes cluster cannot connect to Logz.io logs. please check your Kubernetes cluster network for port 8071"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Checks if Kubernetes cluster can connect to Logz.io metrics (port 8053)
# Input:
#   ---
# Output:
#   ---
function can_kubernetes_cluster_connect_to_logzio_metrics {
    local exit_code=5
    local func_name="${FUNCNAME[0]}"

    local message='Checking if Kubernetes cluster can connect to Logz.io metrics (port 8053) ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    can_kubernetes_cluster_connect_to_logzio "logzio_metrics_connection_test_pod.yaml" "logzio-metrics-connection-test"
    if [[ $? -ne 0 ]]; then
        message="prerequisites.bash ($exit_code): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    if ! $IS_CONNECTED_TO_LOGZIO; then
        message="prerequisites.bash ($exit_code): Kubernetes cluster cannot connect to Logz.io metrics. please check your Kubernetes cluster network for port 8053"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Checks if Kubernetes cluster can connect to Logz.io
# Input:
#   yaml_file - Kubernetes pod creation yaml file
#   pod_name - The name of the pod that was created
# Output:
#   IS_CONNECTED_TO_LOGZIO - Tells if Kubernetes cluster can connect to Logz.io (true/false). Only if got no error.
#   If got error will output message with exit code.
function can_kubernetes_cluster_connect_to_logzio {
    local yaml_file="$1"
    local pod_name="$2"

    kubectl apply -f "$KUBERNETES_RESOURCES_DIR/$yaml_file" >/dev/null 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        echo -e "prerequisites.bash ($exit_code): error creating '$pod_name' pod: $(get_task_error_message)" >"$TASK_ERROR_FILE"
        return 1
    fi

    local is_pod_completed=false
    local retries=3
    while [[ $retries -ne 0 ]]; do
        local pod_status
        pod_status=$(kubectl get pods 2>"$TASK_ERROR_FILE" | grep "$pod_name" 2>"$TASK_ERROR_FILE" | tr -s ' ' | cut -d ' ' -f3)
        if [[ $? -ne 0 ]]; then
            echo -e "prerequisites.bash ($exit_code): error getting '$pod_name' pod status: $(get_task_error_message)" >"$TASK_ERROR_FILE"
            return 2
        fi

        if [[ "$pod_status" == 'Completed' ]]; then
            is_pod_completed=true
            break
        fi

        sleep 5
        ((retries--))
    done

    local pod_logs

    if ! $is_pod_completed; then
        pod_logs=$(kubectl logs "$pod_name" 2>"$TASK_ERROR_FILE")
        if [[ $? -ne 0 ]]; then
            echo -e "prerequisites.bash ($exit_code): error getting logs of '$pod_name' pod: $(get_task_error_message)" >"$TASK_ERROR_FILE"
        fi

        delete_test_pod "$pod_name"

        echo -e "prerequisites.bash ($exit_code): pod '$pod_name' was not completed. pod status is '$pod_status': $pod_logs" >>"$TASK_ERROR_FILE"
        return 3
    fi

    pod_logs=$(kubectl logs "$pod_name" 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        echo -e "prerequisites.bash ($exit_code): error getting logs of '$pod_name' pod: $(get_task_error_message)" >"$TASK_ERROR_FILE"

        delete_test_pod "$pod_name"
        return 4
    fi

    delete_test_pod "$pod_name"

    if [[ "$pod_logs" != "Connected to $LISTENER_URL" ]]; then
        IS_CONNECTED_TO_LOGZIO=false
        return
    fi

    IS_CONNECTED_TO_LOGZIO=true
}

# Deletes test pod from Kubernetes cluster
# Input:
#   pod_name - The name of the pod to delete
# Output:
#   ---
function delete_test_pod {
    local pod_name="$1"

    kubectl delete pod "$pod_name" >/dev/null 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        write_task_post_run "write_warning \"failed to delete '$pod_name' pod: $(get_task_error_message)\""
    fi
}

# Checks if Helm is installed and installs Helm if not installed
# Input:
#   ---
# Output:
#   ---
function is_helm_installed {
    local exit_code=6
    local func_name="${FUNCNAME[0]}"

    local message='Checking if Helm is installed ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    which helm >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        message='Helm is installed'
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        return
    fi

    message='Helm is not installed. Installing Helm ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    curl -sS 'https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3' | bash >/dev/null 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="prerequisites.bash ($exit_code): error install Helm. please run 'curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash' and rerun the agent script: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Adds Logz.io Helm repo
# Input:
#   ---
# Output:
#   ---
function add_logzio_helm_repo {
    local exit_code=7
    local func_name="${FUNCNAME[0]}"

    local message='Adding Logz.io Helm repo ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    helm repo add logzio-helm https://logzio.github.io/logzio-helm >/dev/null 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="prerequisites.bash ($exit_code): error adding Logz.io Helm repo: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Updates Logz.io Helm repo
# Input:
#   ---
# Output:
#   ---
function update_logzio_helm_repo {
    local exit_code=8
    local func_name="${FUNCNAME[0]}"

    local message='Updating Logz.io Helm repo ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
    
    helm repo update >/dev/null 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="prerequisites.bash ($exit_code): error updating Logz.io Helm repo: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PREREQUISITES" "$LOG_SCRIPT_PREREQUISITES" "$func_name" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}
