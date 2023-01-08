#!/bin/bash

#################################################################################################################################
############################################## LINUX Subtype Installer Functions ################################################
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

    local service=$(systemctl | grep "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME")
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
    local exit_code=1
    local func_name="${FUNCNAME[0]}"

    local message='Removing Logz.io OTEL collector service ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    systemctl stop "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error stopping '$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME' service: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    systemctl disable "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error disabling '$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME' service: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    rm "/etc/systemd/system/$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME.service" 2>/dev/null
    rm "/usr/lib/systemd/system/$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME.service" 2>/dev/null
    rm "/etc/init.d/$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 2>/dev/null
}

# Downloads OTEL collector binary
# Input:
#   ---
# Output:
#   OTEL collector exe in Logz.io temp directory
function download_otel_collector_binary {
    local exit_code=2
    local func_name="${FUNCNAME[0]}"

    local message='Downloading OTEL collector binary ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    curl -fsSL "$OTEL_COLLECTOR_URL_DOWNLOAD" >"$LOGZIO_TEMP_DIR/otelcol-logzio.tar.gz" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error downloading otelcol-logzio.tar.gz: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    tar -zxf "$LOGZIO_TEMP_DIR/otelcol-logzio.tar.gz" --directory "$LOGZIO_TEMP_DIR" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error extracting files from otelcol-logzio.tar.gz: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Creates Logz.io opt subdirectory
# Input:
#   ---
# Output:
#   ---
function create_logzio_opt_sub_dir {
    local exit_code=3
    local func_name="${FUNCNAME[0]}"

    local message='Creating Logz.io opt subdirectory ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    mkdir -p "$LOGZIO_OTEL_COLLECTOR_DIR" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error creating '$LOGZIO_OTEL_COLLECTOR_DIR' directory: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Copies OTEL files to opt subdirectory
# Input:
#   ---
# Output:
#   ---
function copy_logzio_otel_files_to_opt_sub_dir {
    local exit_code=4
    local func_name="${FUNCNAME[0]}"

    local message='Copying Logz.io OTEL files to opt subdirectory ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    cp "$LOGZIO_TEMP_DIR/$OTEL_COLLECTOR_BIN_NAME" "$LOGZIO_OTEL_COLLECTOR_DIR" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error copying OTEL files to opt subdirectory: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    cp "$OTEL_RESOURCES_DIR/$OTEL_CONFIG_NAME" "$LOGZIO_OTEL_COLLECTOR_DIR" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error copying OTEL files to opt subdirectory: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Copies service file to systemd system directory
# Input:
#   ---
# Output:
#   ---
function copy_logzio_otel_collector_service_file_to_systemd_system_dir {
    local exit_code=5
    local func_name="${FUNCNAME[0]}"

    local message='Copying Logz.io OTEL collector service file to system directory ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    sed -i "s@OTEL_COLLECTOR_BIN@$OTEL_COLLECTOR_BIN@g" "$OTEL_RESOURCES_DIR/linux/logzioOTELCollector.service" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $exit_code
    fi

    sed -i "s@OTEL_CONFIG@$OTEL_CONFIG@g" "$OTEL_RESOURCES_DIR/linux/logzioOTELCollector.service" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $exit_code
    fi

    cp "$OTEL_RESOURCES_DIR/linux/logzioOTELCollector.service" "/etc/systemd/system" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error copying OTEL collector service file to systemd system directory: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Copies delete service script file to opt subdirectory
# Input:
#   ---
# Output:
#   ---
function copy_delete_service_script_to_opt_sub_dir {
    local exit_code=6
    local func_name="${FUNCNAME[0]}"

    local message='Copying delete service script to opt subdirectory ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    sed -i "s@LOGZIO_OTEL_COLLECTOR_SERVICE_NAME@$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME@g" "$OTEL_RESOURCES_DIR/linux/delete_service.bash" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""
    
        return $exit_code
    fi

    cp "$OTEL_RESOURCES_DIR/linux/delete_service.bash" "$LOGZIO_OTEL_COLLECTOR_DIR" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error copying delete service script file to opt subdirectory: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Runs Logz.io OTEL collector service
# Input:
#   ---
# Output:
#   ---
function run_logzio_otel_collector_service {
    local exit_code=7
    local func_name="${FUNCNAME[0]}"

    local message='Running Logz.io OTEL collector service ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"
    message=$(cat "$OTEL_CONFIG")
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    systemctl start "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" >/dev/null 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error starting Logz.io OTEL collector service: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    local is_service_running
    is_service_running=$(systemctl status "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" | grep "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME.service failed")
    if [[ ! -z "$is_service_running" ]]; then
        message="installer.bash ($exit_code): error running if Logz.io OTEL collector service. run 'sudo systemctl status -l \"$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME\"' to see the error"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}
