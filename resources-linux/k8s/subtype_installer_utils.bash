#!/bin/bash

#################################################################################################################################
########################################## LINUX Subtype Installer Utils Functions ##############################################
#################################################################################################################################

# Checks if Logz.io Helm exists
# Input:
#   ---
# Output:
#   IS_HELM_EXISTS - Tells if Logz.io Helm exists (true/false)
function is_logzio_helm_exists {
    local func_name="${FUNCNAME[0]}"

    local message='Checking if Logz.io Helm exists ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local helm_status
    helm_status=$(helm status -n monitoring logzio-monitoring 2>"TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error getting Logz.io Helm status: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    if [[ -z "$helm_status" ]]; then
        message='Logz.io Helm does not exist'
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        write_task_post_run "IS_HELM_EXISTS=false"
        return
    fi

    message='Logz.io Helm is already exists'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "IS_HELM_EXISTS=true"
}

# Uninstalls Logz.io Helm
# Input:
#   ---
# Output:
#   ---
function uninstall_logzio_helm {
    local func_name="${FUNCNAME[0]}"

    local message='Uninstalling Logz.io Helm ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    helm uninstall -n monitoring logzio-monitoring >/dev/null 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error uninstalling Logz.io Helm: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
}

# Creates Logz.io opt subdirectory
# Input:
#   ---
# Output:
#   ---
function create_logzio_opt_sub_dir {
    local func_name="${FUNCNAME[0]}"

    local message='Creating Logz.io opt subdirectory ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    mkdir -p "$LOGZIO_KUBERNETES_DIR" 2>"$TASK_ERROR_MESSAGE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error creating Logz.io Kubernetes directory: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
}

# Creates Logz.io Helm file with Helm install command
# Input:
#   ---
# Ouput:
#   ---
function create_logzio_helm_file_with_helm_install {
    local func_name="${FUNCNAME[0]}"

    local message='Creating Logz.io Helm file with Helm install command ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    echo -e "helm install -n monitoring $HELM_SETS --create-namespace logzio-monitoring logzio-helm/logzio-monitoring" >"$LOGZIO_HELM_FILE"
}

# Runs Helm install
# Input:
#   ---
# Output:
#   ---
function run_helm_install {
    local func_name="${FUNCNAME[0]}"

    local message='Running Helm install ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    message='Helm sets are '$LOG_HELM_SETS''
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local retries=3
    while [[ $retries -ne 0 ]]; do
        helm install -n monitoring $HELMN_SETS --create-namespace logzio-monitoring logzio-helm/logzio-monitoring >/dev/null 2>"$TASK_ERROR_FILE"
        if [[ $? -eq 0 ]]; then
            return
        fi

        sleep 5
        ((retries--))
    done

    helm status -n monitoring logzio-monitoring >/dev/null 2>"$TASK_ERROR_FILE"

    message="installer.bash ($EXIT_CODE): error running Helm install: $(get_task_error_message)"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_task_post_run "write_error \"$message\""

    return $EXIT_CODE
}

# Gets user answer about uninstalling the existing Logz.io Helm
# If 'y', uninstall the existing Logz.io Helm
# If 'n', exit
# Input:
#   ---
# Output:
#   ---
function uninstall_helm_or_exit {
    local func_name="${FUNCNAME[0]}"

    local message='Getting answer from user about uninstalling the existing Logz.io Helm ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local answer=''

    while true; do
        echo -ne "${YELLOW_COLOR}Logz.io Helm is already exists. If you continue the Logz.io Helm will be uninstalled. Are you sure? (y/n) $WHITE_COLOR"
        read answer
        
        answer="${answer,,}"
        if [[ "$answer" == 'y' || "$answer" == 'n' ]]; then
            break
        fi
    done

    message="The user answer is '$answer'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    if [[ "$answer" == 'n' ]]; then
        IS_REMOVE_LAST_RUN_ANSWER_NO=true
        run_final
        exit
    fi

    # Uninstall Logz.io Helm
    execute_task 'uninstall_logzio_helm' 'Uninstalling Logz.io Helm'
}
