#!/bin/bash

#################################################################################################################################
########################################## LINUX Subtype Installer Utils Functions ##############################################
#################################################################################################################################

# Checks if Logz.io OTEL collector service exists
# Input:
#   ---
# Output:
#   IS_SERVICE_EXISTS - Tells if Logz.io OTEL collector service exists (true/false)
function is_logzio_otel_collector_service_exists {
    local func_name="${FUNCNAME[0]}"

    local message='Checking if Logz.io OTEL collector service exists ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local service=$(sudo systemctl | grep "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" | grep "loaded")
    if [[ -z $service ]]; then
        message="'$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME' service does not exist"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        write_task_post_run "IS_SERVICE_EXISTS=false"
        return
    fi

    message="'$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME' service is already exists"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "IS_SERVICE_EXISTS=true"
}

# Removes Logz.io OTEL collector service
# Input:
#   ---
# Output:
#   ---
function remove_logzio_otel_collector_service {
    local func_name="${FUNCNAME[0]}"

    local message='Removing Logz.io OTEL collector service ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    sudo systemctl stop "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error stopping '$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME' service: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    sudo systemctl disable "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error disabling '$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME' service: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    sudo systemctl reset-failed "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 2>/dev/null

    rm "/etc/systemd/system/$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME.service" 2>/dev/null
    rm "/usr/lib/systemd/system/$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME.service" 2>/dev/null
    rm "/etc/init.d/$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 2>/dev/null

    return 0
}

# Downloads OTEL collector binary
# Input:
#   ---
# Output:
#   OTEL collector exe in Logz.io temp directory
function download_otel_collector_binary {
    local func_name="${FUNCNAME[0]}"
    local binary_name="$OTEL_COLLECTOR_BIN_NAME"
    local download_url=$(get_arch_specific_url "$OTEL_COLLECTOR_AMD_URL_DOWNLOAD" "$OTEL_COLLECTOR_ARM_URL_DOWNLOAD")
    local binary_path="$LOGZIO_TEMP_DIR/$binary_name"

    download_binary "$download_url" "$binary_name" "$binary_path"
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

    mkdir -p "$LOGZIO_OTEL_COLLECTOR_DIR" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error creating '$LOGZIO_OTEL_COLLECTOR_DIR' directory: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
}

# Copies OTEL files to opt subdirectory
# Input:
#   ---
# Output:
#   ---
function copy_logzio_otel_files_to_opt_sub_dir {
    local func_name="${FUNCNAME[0]}"

    local message='Copying Logz.io OTEL files to opt subdirectory ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    cp "$LOGZIO_TEMP_DIR/$OTEL_COLLECTOR_BIN_NAME" "$LOGZIO_OTEL_COLLECTOR_DIR" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error copying OTEL files to opt subdirectory: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    cp "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" "$LOGZIO_OTEL_COLLECTOR_DIR" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error copying OTEL files to opt subdirectory: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
}

# Copies service file to systemd system directory
# Input:
#   ---
# Output:
#   ---
function copy_logzio_otel_collector_service_file_to_systemd_system_dir {
    local func_name="${FUNCNAME[0]}"

    local message='Copying Logz.io OTEL collector service file to systemd system directory ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    sed -i "s@OTEL_COLLECTOR_BIN@$OTEL_COLLECTOR_BIN@g" "$OTEL_RESOURCES_LINUX_DIR/logzioOTELCollector.service" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi

    sed -i "s@OTEL_CONFIG@$OTEL_CONFIG@g" "$OTEL_RESOURCES_LINUX_DIR/logzioOTELCollector.service" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi
    
    local sampling_probability=${SAMPLING_PROPABILITY:-10}
    local sampling_latency=${SAMPLING_LATENCY:-200}
    local is_span_metrics=${IS_SPAN_METRICS:-false}
    
    # Replace environment variables placeholders with actual values
    sed -i "s@SAMPLING_PROPABILITY_PLACEHOLDER@$sampling_probability@g" "$OTEL_RESOURCES_LINUX_DIR/logzioOTELCollector.service" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error setting SAMPLING_PROPABILITY in service file: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi
    
    sed -i "s@SAMPLING_LATENCY_PLACEHOLDER@$sampling_latency@g" "$OTEL_RESOURCES_LINUX_DIR/logzioOTELCollector.service" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error setting SAMPLING_LATENCY in service file: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi
    
    sed -i "s@IS_SPAN_METRICS_PLACEHOLDER@$is_span_metrics@g" "$OTEL_RESOURCES_LINUX_DIR/logzioOTELCollector.service" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error setting IS_SPAN_METRICS in service file: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi

    if [[ ! -z "$PROXY" ]]; then
        sed -i "/^ExecStart=.*/a Environment=\"HTTPS_PROXY=$PROXY\"" "$OTEL_RESOURCES_LINUX_DIR/logzioOTELCollector.service" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="installer.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""
    
            return $EXIT_CODE
        fi
    fi
    get_general_params
    # Extract envID from GENERAL_PARAMS
    local envid_value=""
    for param in ${GENERAL_PARAMS//,/ }; do
        if [[ "$param" == envID=* ]]; then
            envid_value="${param#envID=}"
            break
        fi
    done
    sed -i "s@ENV_ID_PLACEHOLDER@$envid_value@g" "$OTEL_RESOURCES_LINUX_DIR/logzioOTELCollector.service" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error setting ENV_ID in service file: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
        return $EXIT_CODE
    fi

    sudo cp "$OTEL_RESOURCES_LINUX_DIR/logzioOTELCollector.service" "/etc/systemd/system" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error copying OTEL collector service file to systemd system directory: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
}

# Copies delete service script file to opt subdirectory
# Input:
#   ---
# Output:
#   ---
function copy_delete_service_script_to_opt_sub_dir {
    local func_name="${FUNCNAME[0]}"

    local message='Copying delete service script to opt subdirectory ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    sed -i "s@LOGZIO_OTEL_COLLECTOR_SERVICE_NAME@$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME@g" "$OTEL_RESOURCES_LINUX_DIR/delete_service.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $EXIT_CODE
    fi

    cp "$OTEL_RESOURCES_LINUX_DIR/delete_service.bash" "$LOGZIO_OTEL_COLLECTOR_DIR" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error copying delete service script file to opt subdirectory: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
}

# Runs Logz.io OTEL collector service
# Input:
#   ---
# Output:
#   ---
function run_logzio_otel_collector_service {
    local func_name="${FUNCNAME[0]}"

    local message='Running Logz.io OTEL collector service ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
    message=$(cat "$OTEL_CONFIG")
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    sudo systemctl start "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" >/dev/null 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error starting Logz.io OTEL collector service: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    sudo systemctl enable "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error enabling Logz.io OTEL collector service: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local is_service_running
    is_service_running=$(sudo systemctl status "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" | grep "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME.service failed")
    if [[ ! -z "$is_service_running" ]]; then
        local status=$(sudo systemctl status -l "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 2>"$TASK_ERROR_FILE")
        message="installer.bash ($EXIT_CODE): error running Logz.io OTEL collector service. run 'sudo systemctl status -l \"$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME\"' to see the error"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
}

# Gets user answer about removing the existed service
# If 'y', remove the existed service
# If 'n', exit
# Input:
#   ---
# Output:
#   ---
function remove_service_or_exit {
    local func_name="${FUNCNAME[0]}"

    local message='Getting answer from user about removing the existed service ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local answer=''

    while true; do
        echo -ne "$YELLOW_COLOR'$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME' service is already exists. If you continue the service will be removed. Are you sure? (y/n) $WHITE_COLOR"
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

    # Remove Logz.io OTEL collector service
    execute_task 'remove_logzio_otel_collector_service' 'Removing Logz.io OTEL collector service'
}
