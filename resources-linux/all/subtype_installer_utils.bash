#!/bin/bash

#################################################################################################################################
########################################## LINUX Subtype Installer Utils Functions ##############################################
#################################################################################################################################

# Runs each datasource prerequisites and installer scripts
# Input:
#   ---
# Output:
#   ---
function run_all_data_sources {
    local func_name="${FUNCNAME[0]}"

    local message='Running all datasources scripts ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    for data_source in ${DATA_SOURCES[@]}; do
        CURRENT_DATA_SOURCE="$data_source"

        message="Loading $data_source datasource prerequisites functions ..."
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/${data_source,,}/$PREREQUISITES_FUNCTIONS_FILE" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="installer.bash ($SUB_TYPE_INSTALLER_EXIT_CODE): error loading $data_source datasource prerequisites functions: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
            write_error "$message"

            IS_AGENT_FAILED=true
            run_final
            exit $SUB_TYPE_INSTALLER_EXIT_CODE
        fi

        message="Running $data_source datasource prerequisites ..."
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/${data_source,,}/$PREREQUISITES_FILE" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="installer.bash ($SUB_TYPE_INSTALLER_EXIT_CODE): error running $data_source datasource prerequisites: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
            write_error "$message"

            IS_AGENT_FAILED=true
            run_final
            exit $SUB_TYPE_INSTALLER_EXIT_CODE
        fi

        message="Loading $data_source datasource installer functions ..."
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/${data_source,,}/$INSTALLER_FUNCTIONS_FILE" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="installer.bash ($SUB_TYPE_INSTALLER_EXIT_CODE): error loading $data_source datasource installer functions: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
            write_error "$message"

            IS_AGENT_FAILED=true
            run_final
            exit $SUB_TYPE_INSTALLER_EXIT_CODE
        fi

        message="Running $data_source datasource installer ..."
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/${data_source,,}/$INSTALLER_FILE" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="installer.bash ($SUB_TYPE_INSTALLER_EXIT_CODE): error running $data_source datasource installer: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
            write_error "$message"

            IS_AGENT_FAILED=true
            run_final
            exit $SUB_TYPE_INSTALLER_EXIT_CODE
        fi
    done

    ((SUB_TYPE_INSTALLER_EXIT_CODE++))
}
