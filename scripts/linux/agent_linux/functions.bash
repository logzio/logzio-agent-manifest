#!/bin/bash

#################################################################################################################################
###################################################### LINUX Agent Functions ####################################################
#################################################################################################################################

# Gets Linux info
# Input:
#   ---
# Output:
#   LINUX_NAME - Linux name
#   LINUX_VERSION - Linux version
#   CPU_ARCH - Linux cpu architecture
function get_linux_info {
    local func_name="${FUNCNAME[0]}"

    local message='Getting Linux info ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local linux_info=$(cat /etc/os-release 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($EXIT_CODE): error getting Linux info: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local linux_name=$(echo -e "$linux_info" | grep -oP '(?<=^NAME=").*?(?=")')
    write_task_post_run "LINUX_NAME=\"$linux_name\""

    message="Linux name is '$linux_name'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local linux_version=$(echo -e "$linux_info" | grep -oP '(?<=^VERSION=").*?(?=")')
    write_task_post_run "LINUX_VERSION=\"$linux_version\""

    message="Linux version is '$linux_version'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local cpu_arch=$(uname -p 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($EXIT_CODE): error getting cpu arch: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    
    message="CPU architecture is '$cpu_arch'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "CPU_ARCH=\"$cpu_arch\""
}

# Checks if bash version is 4.0 or above
# Input:
#   ---
# Output:
#   ---
function is_bash_version_4_or_above {
    local func_name="${FUNCNAME[0]}"

    local message='Checking if bash version is 4.0 or above ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local bash_major_version=$(echo -e "$BASH_VERSION" | cut -d. -f1)
    if [[ $bash_major_version -lt 4 ]]; then
        message="agent.bash ($EXIT_CODE): bash version must be 4.0 or above"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
}


# Prints usage
# Input:
#   ---
# Output:
#   Help usage
function show_help {
    write_task_post_run "echo -e \"Usage: .\agent.bash --url=<logzio_app_url> --id=<agent_id> [--debug=<agent_json>] [--release=<repo_release>] [--tmp_dest=<temp_dest>] [--proxy=<proxy_url>}\""
    write_task_post_run "echo -e ' --url=<logzio_app_url>       Logz.io app URL (https://app.logz.io)'"
    write_task_post_run "echo -e ' --id=<agent_id>              Logz.io agent ID'"
    write_task_post_run "echo -e ' --debug=<agent_json>         Debug run using a local agent json file'"
    write_task_post_run "echo -e ' --release=<repo_release>     The release of Logz.io repo. Default is latest release'"
    write_task_post_run "echo -e ' --temp_dest=<temp_dest>      The temp files destination path. Default is /tmp/logzio'"
    write_task_post_run "echo -e ' --proxy=<proxy_url>          The proxy url'"
    write_task_post_run "echo -e ' --help                       Show usage'"
}

# Gets arguments
# Input:
#   ---
# Output:
#   APP_URL - Logz.io app url
#   AGENT_ID - Logz.io agent id
#   AGENT_JSON_FILE - Agent json file path (for debug)
#   REPO_RELEASE - Repo release (for debug)
function get_arguments {
    local func_name="${FUNCNAME[0]}"

    local message='Getting arguments ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    for arg in "${AGENT_ARGS[@]}"; do
        case "$arg" in
            --help)
                show_help
                write_task_post_run "IS_SHOW_HELP=true"
                
                return
                ;;
            --url=*)
                app_url=$(echo -e "$arg" | cut -d '=' -f2)
                if [[ -z "$app_url" ]]; then
                    message="agent.bash ($EXIT_CODE): no Logz.io app URL specified!"
                    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
                    write_task_post_run "write_error \"$message\""

                    return $EXIT_CODE
                fi

                message="Agent argument 'url' is '$app_url'"
                send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
                write_log "$LOG_LEVEL_DEBUG" "$message"
                
                write_task_post_run "APP_URL='$app_url'"
                ;;
            --id=*)
                agent_id=$(echo "$arg" | cut -d '=' -f2)
                if [[ -z "$agent_id" ]]; then
                    message="agent.bash ($EXIT_CODE): no agent ID specified!"
                    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
                    write_task_post_run "write_error \"$message\""

                    return $EXIT_CODE
                fi

                message="Agent argument 'id' is '$agent_id'"
                send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
                write_log "$LOG_LEVEL_DEBUG" "$message"
                
                write_task_post_run "AGENT_ID='$agent_id'"
                ;;
            --debug=*)
                agent_json_file=$(echo "$arg" | cut -d '=' -f2)
                if [[ -z "$agent_json_file" ]]; then
                    message="agent.bash ($EXIT_CODE): no json file specified!"
                    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
                    write_task_post_run "write_error \"$message\""

                    return $EXIT_CODE
                fi

                message="Agent argument 'debug' is '$agent_json_file'"
                send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
                write_log "$LOG_LEVEL_DEBUG" "$message"
                
                write_task_post_run "AGENT_JSON_FILE='$agent_json_file'"
                ;;
            --release=*)
                repo_release=$(echo "$arg" | cut -d '=' -f2)
                
                message="Agent argument 'release' is '$repo_release'"
                send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
                write_log "$LOG_LEVEL_DEBUG" "$message"

                write_task_post_run "REPO_RELEASE='$repo_release'"
                ;;
            --temp_dest=*)
                temp_dest=$(echo "$arg" | cut -d '=' -f2)
                
                message="Agent argument 'temp_dest' is '$temp_dest'"
                send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
                write_log "$LOG_LEVEL_DEBUG" "$message"
                ;;
            --proxy=*)
                proxy=$(echo "$arg" | cut -d '=' -f2)
                
                message="Agent argument 'proxy' is '$proxy'"
                send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
                write_log "$LOG_LEVEL_DEBUG" "$message"

                write_task_post_run "PROXY='$proxy'"
                ;;
            *)
                message="agent.bash ($EXIT_CODE): unrecognized flag"
                send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
                write_task_post_run "write_error \"$message\""
                message="agent.bash ($EXIT_CODE): try running the agent with '--help' flag for more information"
                send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
                write_task_post_run "write_error \"$message\""
                
                return $EXIT_CODE
                ;;
        esac
    done
}

# Checks validation of the arguments
# Input:
#   ---
# Output:
#   if debug flag was used AGENT_ID='Debug'
function check_arguments_validation {
    local func_name="${FUNCNAME[0]}"

    local message='Checking validation ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    if [[ ! -z "$AGENT_JSON_FILE" ]]; then
        if [[ -f "$AGENT_JSON_FILE" ]]; then
            write_task_post_run "AGENT_ID='Debug'"
            return
        fi

        message="agent.bash ($EXIT_CODE): the json file '$AGENT_JSON_FILE' does not exist"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local is_error=false

    if [[ -z "$APP_URL" ]]; then
        is_error=true
        message="agent.bash ($EXIT_CODE): Logz.io app url must be specified"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""
    fi
    if [[ -z "$AGENT_ID" ]]; then
        is_error=true
        message="agent.bash ($EXIT_CODE): agent id must be specified"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""
    fi

    if ! $is_error; then
        return
    fi

    message="agent.bash ($EXIT_CODE): try running the agent with '--help' flag for more information"
    send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_task_post_run "write_error \"$message\""

    return $EXIT_CODE
}

# Download binary
function download_binary {
    local download_url="$1"
    local binary_name="$2"
    local binary_path="$3"
    local func_name="${FUNCNAME[0]}"

    # Check if the binary is already installed
    if copy_installed_binary "$binary_name" "$download_url" "$binary_path"; then
        write_log "$LOG_LEVEL_DEBUG" "$binary_name is already installed. Skipping download."
        return 0
    fi
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$download_message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$download_message"
       # Extract the binary from the tar.gz archive
    if [[ "$download_url" == *".tar.gz" ]]; then
        local tar_path="$LOGZIO_TEMP_DIR/$binary_name.tar.gz"

        curl -fsSL "$download_url" >"$tar_path" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="installer.bash ($EXIT_CODE): error downloading $binary_name.tar.gz: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi

        tar -zxf "$tar_path" --directory "$LOGZIO_TEMP_DIR" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="installer.bash ($EXIT_CODE): error extracting files from $tar_path: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi

        # Assuming the extracted binary starts with "$binary_name(_|-)"
        local extracted_binary=$(find "$LOGZIO_TEMP_DIR" -type f -name "${binary_name}[-|_]*" | head -n 1)
        message="Attempting to move extracted binary file: $extracted_binary using this pattern: '${binary_name}[-|_]*'"
        send_log_to_logzio "$LOG_LEVEL_INFO" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        # Check if a matching file is found
        if [ -n "$extracted_binary" ]; then
            # Move the file to the destination
            mv "$extracted_binary" "$binary_path"

            # Check if the move was successful
            if [ $? -eq 0 ]; then
                message="$extracted_binary binary file moved successfully."
                send_log_to_logzio "$LOG_LEVEL_INFO" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            else
                message="Error: Failed to move the $extracted_binary binary file to: $binary_path."
                send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"

            fi
        else
            message="No matching binary file that contains this name: $binary_name found."
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        
        fi
        rm -f $tar_path
    else
        # Directly download the binary file
        curl -fsSL --create-dirs "$download_url" > "$binary_path" 2>"$TASK_ERROR_FILE"

        if [[ $? -ne 0 ]]; then
            local error_message="installer.bash ($EXIT_CODE): error downloading $binary_name: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$error_message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
            write_task_post_run "write_error \"$error_message\""
            return $EXIT_CODE

        fi
    fi


    # Provide execution permissions to binary file
    chmod +x "$binary_path" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($EXIT_CODE): error giving execute premissions to '$binary_path': $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
}

# Downloads jq
# Input:
#   ---
# Output:
#   Jq binary file in Logz.io temp directory
function download_jq {
    local func_name="${FUNCNAME[0]}"
    local binary_name="jq"
    local binary_path="$LOGZIO_TEMP_DIR/$binary_name"
    local download_url=$(get_arch_specific_url "$JQ_URL_DOWNLOAD" "$JQ_ARM_URL_DOWNLOAD")
    
    download_binary "$download_url" "$binary_name" "$binary_path"
}

# Downloads yq
# Input:
#   ---
# Output:
#   Yq binary file in Logz.io temp directory
function download_yq {
    local func_name="${FUNCNAME[0]}"
    local binary_name="yq"
    local binary_path="$LOGZIO_TEMP_DIR/$binary_name"
    local download_url=$(get_arch_specific_url "$YQ_URL_DOWNLOAD" "$YQ_ARM_URL_DOWNLOAD")
    
    download_binary "$download_url" "$binary_name" "$binary_path"
}

# Gets the agent json from the agent or local file
# Input:
#   ---
# Output:
#   Agent json file in Logz.io temp directory
function get_agent_json {
    local func_name="${FUNCNAME[0]}"

    local message='Getting agent json ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    if [[ ! -z "$AGENT_JSON_FILE" ]]; then
        # Using local app json file
        message='Using local agent json file ...'
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        cp "$AGENT_JSON_FILE" "$AGENT_JSON" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="agent.bash ($EXIT_CODE): error copying '$AGENT_JSON_FILE' to '$AGENT_JSON': $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi

        return
    fi

    # Getting agent json from agent
    message='Getting agent json from agent ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    if [[ ! -z "$PROXY" ]]; then
        curl --proxy "$PROXY" -fsSL "$APP_URL/telemetry-agent/public/agents/configuration/$AGENT_ID" >"$AGENT_JSON" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="agent.bash ($EXIT_CODE): error getting Logz.io agent json from agent. make sure your url is valid: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi
    else
        curl -fsSL "$APP_URL/telemetry-agent/public/agents/configuration/$AGENT_ID" >"$AGENT_JSON" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="agent.bash ($EXIT_CODE): error getting Logz.io agent json from agent. make sure your url is valid: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi
    fi

    get_json_file_field_value "$AGENT_JSON" '.statusCode'
    local func_status=$?
    if [[ $func_status -eq 1 ]]; then
        message="agent.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    if [[ $func_status -eq 0 ]]; then
        local status_code="$JSON_VALUE"

        message="agent.bash ($EXIT_CODE): error getting Logz.io agent json from agent (statusCode '$status_code'). make sure your id is valid."
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
}

# Gets agent json info
# input:
#   ---
# Output:
#   PLATFORM - Platfrom name
#   SUB_TYPE - Subtype name
#   DATA_SOURCES - List of datasource names
function get_agent_json_info {
    local func_name="${FUNCNAME[0]}"

    local message='Getting agent json info ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"
    
    if [[ ! -f "$AGENT_JSON" ]]; then
        message="agent.bash ($EXIT_CODE): agent json file does not exist"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""
    fi

    get_json_file_field_value "$AGENT_JSON" '.configuration.name'
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local platform="$JSON_VALUE"
    
    message="Platform is '$platform'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local command="PLATFORM='$platform'"
    write_task_post_run "$command"

    get_json_file_field_value "$AGENT_JSON" '.configuration.subtypes[0].name'
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    
    local sub_type="$JSON_VALUE"

    message="Subtype is '$sub_type'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    command="SUB_TYPE='$sub_type'"
    write_task_post_run "$command"
    
    get_json_file_field_value_list "$AGENT_JSON" '.configuration.subtypes[0].datasources[]'
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local data_sources=("${JSON_VALUE[@]}")

    local index=0
    local data_source_names=()
    for data_source in "${data_sources[@]}"; do
        get_json_str_field_value "$data_source" '.name'
        if [[ $? -ne 0 ]]; then
            message="agent.bash ($EXIT_CODE): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi
        
        local data_source_name="$JSON_VALUE"

        message="DataSource #$((index+1)) is '$data_source_name'"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        data_source_names+=("$data_source_name")
        ((index++))
    done

    LIST=("${data_source_names[@]}")
    local data_sources_str=$(convert_list_to_str)
    command="DATA_SOURCES=$data_sources_str"
    write_task_post_run "$command"
}

# Gets Logz.io listener url
# Input:
#   ---
# Ouput:
#   LISTENER_URL - Logz.io listener url
function get_logzio_listener_url {
    local func_name="${FUNCNAME[0]}"

    local message='Getting Logz.io listener url ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    get_json_file_field_value "$AGENT_JSON" '.listenerUrl'
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($EXIT_CODE): $result"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi

    local listener_url="$JSON_VALUE"

    message="Logz.io listener url is '$listener_url'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "LISTENER_URL='$listener_url'"
}

# Downloads subtype files
# Input:
#   ---
# Output:
#   Subtype files in Logz.io temp directory
function download_sub_type_files {
    local func_name="${FUNCNAME[0]}"

    local message='Donwloading subtype files ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    if [[ -z "$REPO_RELEASE" ]]; then
        if [[ ! -z "$PROXY" ]]; then
            curl --proxy "$PROXY" -fsSL "https://github.com/logzio/logzio-agent-manifest/releases/latest/download/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz" >"$LOGZIO_TEMP_DIR/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz" 2>"$TASK_ERROR_FILE"
            if [[ $? -ne 0 ]]; then
                message="agent.bash ($EXIT_CODE): error downloading subtype tar.gz file from Logz.io repo: $(get_task_error_message)"
                send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
                write_task_post_run "write_error \"$message\""

                return $EXIT_CODE
            fi
        else
            curl -fsSL "https://github.com/logzio/logzio-agent-manifest/releases/latest/download/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz" >"$LOGZIO_TEMP_DIR/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz" 2>"$TASK_ERROR_FILE"
            if [[ $? -ne 0 ]]; then
                message="agent.bash ($EXIT_CODE): error downloading subtype tar.gz file from Logz.io repo: $(get_task_error_message)"
                send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
                write_task_post_run "write_error \"$message\""

                return $EXIT_CODE
            fi
        fi
    else
        if [[ ! -z "$PROXY" ]]; then
            curl --proxy "$PROXY" -fsSL "https://github.com/logzio/logzio-agent-manifest/releases/download/$REPO_RELEASE/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz" >"$LOGZIO_TEMP_DIR/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz" 2>"$TASK_ERROR_FILE"
            if [[ $? -ne 0 ]]; then
                message="agent.bash ($EXIT_CODE): error downloading subtype tar.gz file from Logz.io repo: $(get_task_error_message)"
                send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
                write_task_post_run "write_error \"$message\""

                return $EXIT_CODE
            fi
        else
            curl -fsSL "https://github.com/logzio/logzio-agent-manifest/releases/download/$REPO_RELEASE/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz" >"$LOGZIO_TEMP_DIR/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz" 2>"$TASK_ERROR_FILE"
            if [[ $? -ne 0 ]]; then
                message="agent.bash ($EXIT_CODE): error downloading subtype tar.gz file from Logz.io repo: $(get_task_error_message)"
                send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
                write_task_post_run "write_error \"$message\""

                return $EXIT_CODE
            fi
        fi
    fi
    
    tar -zxf "$LOGZIO_TEMP_DIR/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz" --directory "$LOGZIO_TEMP_DIR" --overwrite 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($EXIT_CODE): error extracting files from '$LOGZIO_TEMP_DIR/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz': $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
}

# Runs subtype prerequisites
# Input:
#   ---
# Output:
#   ---
function run_sub_type_prerequisites {
    local func_name="${FUNCNAME[0]}"

    local message='Laoding subtype prerequisites functions ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/$PREREQUISITES_FUNCTIONS_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($AGENT_EXIT_CODE): error loading subtype prerequisites functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $AGENT_EXIT_CODE
    fi

    message='Running subtype prerequisites ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/$PREREQUISITES_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($AGENT_EXIT_CODE): error running subtype prerequisites: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $AGENT_EXIT_CODE
    fi

    ((AGENT_EXIT_CODE++))
}

# Runs subtype installer
# Input:
#   ---
# Output:
#   ---
function run_sub_type_installer {
    local func_name="${FUNCNAME[0]}"

    local message='Laoding subtype installer functions ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/$INSTALLER_FUNCTIONS_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($AGENT_EXIT_CODE): error loading subtype installer functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $AGENT_EXIT_CODE
    fi

    message='Running subtype installer ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/$INSTALLER_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($AGENT_EXIT_CODE): error running subtype installer: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $AGENT_EXIT_CODE
    fi

    ((AGENT_EXIT_CODE++))
}

# Runs subtype post-requisites
# Input:
#   ---
# Output:
#   ---
function run_sub_type_postrequisites {
    local func_name="${FUNCNAME[0]}"

    local message='Laoding subtype post-requisites functions ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/$POSTREQUISITES_FUNCTIONS_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($AGENT_EXIT_CODE): error loading subtype post-requisites functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $AGENT_EXIT_CODE
    fi

    local message='Running subtype post-requisites ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/$POSTREQUISITES_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($AGENT_EXIT_CODE): error running subtype post-requisites: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_error "$message"

        IS_AGENT_FAILED=true
        run_final
        exit $AGENT_EXIT_CODE
    fi

    ((AGENT_EXIT_CODE++))
}
