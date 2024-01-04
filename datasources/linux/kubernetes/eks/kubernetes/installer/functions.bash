#!/bin/bash

#################################################################################################################################
############################################ LINUX Datasource Installer Functions ###############################################
#################################################################################################################################

# Loads datasource installer utils functions
# Input:
#   ---
# Output:
#   ---
function load_installer_utils {
    local func_name="${FUNCNAME[0]}"

    local message='Loading installer utils functions ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$ALL_RESOURCES_LINUX_DIR/datasource_installer_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error loading installer utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    source "$KUBERNETES_RESOURCES_LINUX_DIR/datasource_installer_utils.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error loading installer utils functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $EXIT_CODE
    fi

    ((EXIT_CODE++))
}

# Gets environment id
# Input:
#   ---
# Output:
#   ENV_ID - The environment id
function get_environment_id {
    local func_name="${FUNCNAME[0]}"

    local message='Getting environment id ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    PARAMS=("${GENERAL_PARAMS[@]}")
    get_param_value 'envID'
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local env_id="$PARAM_VALUE"
    
    if [[ "$env_id" == '' ]]; then
        local cluster_name
        cluster_name=$(kubectl config current-context 2>"$TASK_ERROR_FILE")
        if [[ $? -ne 0 ]]; then
            local err=$(get_task_error_message)
            if [[ "$err" == *"ERROR"* ]]; then
                env_id=$(echo "$RANDOM" | md5sum | cut -c 1-32)
            fi
        else
            env_id=$(echo "$cluster_name" | cut -d'/' -f2)
        fi
    fi

    message="Environment id is '$env_id'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
    
    write_task_post_run "ENV_ID='$env_id'"
}

# Gets is Fargate option was selected
# Input:
#   ---
# Output:
#   IS_FARGATE - Tells is Fargate option was selected (true/false)
function get_is_fargate_was_selected {
    local func_name="${FUNCNAME[0]}"

    local message='Getting is Fargate option was selected ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    PARAMS=("${GENERAL_PARAMS[@]}")
    get_param_value 'isFargate'
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local is_fargate=$PARAM_VALUE

    if $is_fargate; then
        message='AWS Fargate option was selected'
    else
        message='AWS Fargate option was not selected'
    fi
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "IS_FARGATE=$is_fargate"
}

# Downloads eksctl
# Input:
#   ---
# Output:
#   Eksctl binary file in Logz.io temp directory
function download_eksctl {
    local func_name="${FUNCNAME[0]}"
    local binary_name="eksctl"
    local download_url=$(get_arch_specific_url "$EKSCTL_URL_DOWNLOAD" "$EKSCTL_ARM_URL_DOWNLOAD")
    local binary_path="$LOGZIO_TEMP_DIR/$binary_name"

    download_binary "$download_url" "$binary_name" "$binary_path"
}

# Creates Fargate profile with monitoring namespace on Kubernetes cluster
# Input:
#   ---
# Output:
#   ---
function create_fargate_profile {
    local func_name="${FUNCNAME[0]}"

    local message='Creating Fargate profile with monitoring namespace on Kubernetes cluster ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local kubectl_context
    kubectl_context=$(kubectl config current-context 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        local err=$(get_task_error_message)
        if [[ "$err" == *"ERROR"* ]]; then
            message="installer.bash ($EXIT_CODE): error getting kubectl current context: $err"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi
    fi

    local cluster_name=$(echo -e "$kubectl_context" | cut -d'/' -f2)
    local cluster_region=$(echo -e "$kubectl_context" | cut -d':' -f4)

    local fargate_profiles
    fargate_profiles=$($EKSCTL_BIN get fargateprofile --region "$cluster_region" --cluster "$cluster_name" 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error checking if Fargate profile 'fp-monitoring' in region '$cluster_region' on Kubernetes cluster '$cluster_name' exists: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
        
        return $EXIT_CODE
    fi

    local monitoring_fargate_profile=$(echo -e "$fargate_profiles" | grep -e '\smonitoring')
    if [[ ! -z "$monitoring_fargate_profile" ]]; then
        message="Fargate profile 'fp-monitoring' in region '$cluster_region' on Kubernetes cluster '$cluster_name' is already exists"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        return
    fi

    $EKSCTL_BIN create fargateprofile --region "$cluster_region" --namespace monitoring --cluster "$cluster_name" --name 'fp-monitoring' >/dev/null 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error creating Fargate profile 'fp-monitoring' in region '$cluster_region' with namespace 'monitoring' on Kubernetes cluster '$cluster_name': $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
        
        return $EXIT_CODE
    fi
}
