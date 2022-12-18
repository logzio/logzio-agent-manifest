#!/bin/bash

#################################################################################################################################
################################################ LINUX Subtype Installer Script #################################################
#################################################################################################################################

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
        read -p "$YELLOW_COLOR'$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME' service is already exists. If you continue the service will be removed. Are you sure? (y/n) $WHITE_COLOR" answer
        
        answer=${answer,,}
        if [[ "$answer" == 'y' || "$answer" == 'n' ]]; then
            break
        fi
    done

    message="The user answer is '$answer'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    if [[ "$answe" == 'n' ]]; then
        IS_REMOVE_LAST_RUN_ASNWER_NO=true
        exit
    fi

    # Remove Logz.io OTEL collector service
    execute_task 'remove_logzio_otel_collector_service' 'Removing Logz.io OTEL collector service'
}

# Runs each datasource prerequisites and installer scripts
# Input:
#   ---
# Output:
#   ---
function run_all_data_sources {
    local exit_code=6
    local func_name="${FUNCNAME[0]}"

    local message='Running all datasources scripts ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    for data_source in $DATA_SOURCES; do
        message="Running $data_source datasource prerequisites ..."
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        CURRENT_DATA_SOURCE="$data_source"

        source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/${data_source,,}/$PREREQUISITES_FILE" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="installer.bash ($exit_code): error running $data_source datasource prerequisites: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
            write_task_post_run "write_error \"$message\""

            IS_AGENT_FAILED=true
            exit $exit_code
        fi

        message="Running $data_source datasource installer ..."
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/${data_source,,}/$INSTALLER_FILE" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="installer.bash ($exit_code): error running $data_source datasource installer: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
            write_task_post_run "write_error \"$message\""

            IS_AGENT_FAILED=true
            exit $exit_code
        fi
    done
}


# Print title
echo
echo -e '########################'
echo -e "###$PURPLE_COLOR Pre-Installation $WHITE_COLOR###"
echo -e '########################'

# Check if Logz.io OTEL collector service exists
execute_task 'is_logzio_otel_collector_service_exists' 'Checking if Logz.io OTEL collector service exists'
if $IS_SERVICE_EXISTS; then
    # Get user answer about removing the existed service and run logic according the answer
    remove_service_or_exit
fi
# Download OTEL collector exe
execute_task 'download_otel_collector_binary' 'Downloading OTEL collector binary'
# Run each datasource scripts
#run_all_data_sources

# # Print title
# Write-Host
# Write-Host '####################'
# Write-Host '### ' -NoNewline
# Write-Host 'Installation' -ForegroundColor Magenta -NoNewline
# Write-Host ' ###'
# Write-Host '####################'

# # Create Logz.io AppData subdirectory
# Invoke-Task 'New-LogzioAppDataSubDir' @{} 'Creating Logz.io AppData subdirectory' @($InstallerScriptFile)
# # Copy Logz.io OTEL files to AppData sub directory
# Invoke-Task 'Copy-LogzioOtelFilesToAppDataSubDir' @{} 'Copying Logz.io OTEL files to AppData sub directory' @($InstallerScriptFile)
# # Run Logz.io OTEL collector service
# Invoke-Task 'Invoke-LogzioOtelCollectorService' @{} 'Running Logz.io OTEL collector service' @($InstallerScriptFile)

# # Finished successfully
# Exit 0
