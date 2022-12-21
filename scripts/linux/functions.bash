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
    local exit_code=2
    local func_name="${FUNCNAME[0]}"

    local message='Getting Linux info ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local linux_info=$(cat /etc/os-release 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error getting Linux info: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    local linux_name=$(echo -e "$linux_info" | grep -oP '(?<=^NAME=").*?(?=")')
    write_task_post_run "LINUX_NAME=\"$linux_name\""

    message="Linux name is '$linux_name'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local linux_version=$(echo -e "$linux_info" | grep -oP '(?<=^VERSION=").*?(?=")')
    write_task_post_run "LINUX_VERSION=\"$linux_version\""

    message="Linux version is '$linux_version'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local cpu_arch=$(uname -p 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error getting cpu arch: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
    
    message="CPU architecture is '$cpu_arch'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "CPU_ARCH=\"$cpu_arch\""
}

# Checks if script was run as root
# Input:
#   ---
# Output:
#   ---
function check_is_elevated {
    local exit_code=3
    local func_name="${FUNCNAME[0]}"

    local message='Checking if script was run as root ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local id=$(id -u)
    if [[ $id -eq 0 ]]; then
        return
    fi

    message="agent.bash ($exit_code): agent script was not run as root. please rerun the agent script with 'sudo' command"
    send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_task_post_run "write_error \"$message\""

    return $exit_code
}

# Prints usage
# Input:
#   ---
# Output:
#   Help usage
function show_help {
    write_task_post_run "echo -e \"Usage: .\agent.bash --url=<logzio_app_url> --id=<agent_id> [--debug=<agent_json>] [--release<repo_release>]\""
    write_task_post_run "echo -e ' --url=<logzio_app_url>       Logz.io app URL (https://app.logz.io)'"
    write_task_post_run "echo -e ' --id=<agent_id>              Logz.io agent ID'"
    write_task_post_run "echo -e ' --debug=<agent_json>         Debug run using a local agent json file'"
    write_task_post_run "echo -e ' --release=<repo_release>     The release of Logz.io repo. Default is latest release'"
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
    local exit_code=4
    local func_name="${FUNCNAME[0]}"

    local message='Getting arguments ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    for arg in "${AGENT_ARGS[@]]}"; do
        case "$arg" in
            --help)
                show_help
                write_task_post_run "IS_SHOW_HELP=true"
                
                return
                ;;
            --url=*)
                app_url=$(echo -e "$arg" | cut -d '=' -f2)
                if [[ -z "$app_url" ]]; then
                    message="agent.bash ($exit_code): no Logz.io app URL specified!"
                    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
                    write_task_post_run "write_error \"$message\""

                    return $exit_code
                fi

                message="Agent argument 'url' is '$app_url'"
                send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
                write_log "$LOG_LEVEL_DEBUG" "$message"
                
                write_task_post_run "APP_URL='$app_url'"
                ;;
            --id=*)
                agent_id=$(echo "$arg" | cut -d '=' -f2)
                if [[ -z "$agent_id" ]]; then
                    message="agent.bash ($exit_code): no agent ID specified!"
                    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
                    write_task_post_run "write_error \"$message\""

                    return $exit_code
                fi

                message="Agent argument 'id' is '$agent_id'"
                send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
                write_log "$LOG_LEVEL_DEBUG" "$message"
                
                write_task_post_run "AGENT_ID='$agent_id'"
                ;;
            --debug=*)
                agent_json_file=$(echo "$arg" | cut -d '=' -f2)
                if [[ -z "$agent_json_file" ]]; then
                    message="agent.bash ($exit_code): no json file specified!"
                    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
                    write_task_post_run "write_error \"$message\""

                    return $exit_code
                fi

                message="Agent argument 'debug' is '$agent_json_file'"
                send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
                write_log "$LOG_LEVEL_DEBUG" "$message"
                
                write_task_post_run "AGENT_JSON_FILE='$agent_json_file'"
                ;;
            --release=*)
                repo_release=$(echo "$arg" | cut -d '=' -f2)
                
                message="Agent argument 'release' is '$repo_release'"
                send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
                write_log "$LOG_LEVEL_DEBUG" "$message"

                write_task_post_run "REPO_RELEASE='$repo_release'"
                ;;
            *)
                message="agent.bash ($exit_code): unrecognized flag"
                send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
                write_task_post_run "write_error \"$message\""
                message="agent.bash ($exit_code): try running the agent with '--help' flag for more information"
                send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
                write_task_post_run "write_error \"$message\""
                
                return $exit_code
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
    local exit_code=5
    local func_name="${FUNCNAME[0]}"

    local message='Checking validation ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local app_url="${func_args[app_url]}"
    local agent_id="${func_args[agent_id]}"

    if [[ ! -z "$AGENT_JSON_FILE" ]]; then
        if [[ -f "$AGENT_JSON_FILE" ]]; then
            write_task_post_run "AGENT_ID='Debug'"
            return
        fi

        message="agent.bash ($exit_code): the json file '$AGENT_JSON_FILE' does not exist"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    local is_error=false

    if [[ -z "$APP_URL" ]]; then
        is_error=true
        message="agent.bash ($exit_code): Logz.io app url must be specified"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
        write_task_post_run "write_error \"$message\""
    fi
    if [[ -z "$AGENT_ID" ]]; then
        is_error=true
        message="agent.bash ($exit_code): agent id must be specified"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
        write_task_post_run "write_error \"$message\""
    fi

    if ! $is_error; then
        return
    fi

    message="agent.bash ($exit_code): try running the agent with '--help' flag for more information"
    send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_task_post_run "write_error \"$message\""

    return $exit_code
}

# Downloads jq
# Input:
#   ---
# Output:
#   Jq binary file in Logz.io temp directory
function download_jq {
    local exit_code=6
    local func_name="${FUNCNAME[0]}"

    local message='Downloading jq ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_DOWNLOADS" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    curl -fsSL "$JQ_URL_DOWNLOAD" >"$JQ_BIN" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error downloading jq binary: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_DOWNLOADS" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    chmod +x "$JQ_BIN" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error giving execute premissions to '$JQ_BIN': $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_DOWNLOADS" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Downloads yq
# Input:
#   ---
# Output:
#   Yq binary file in Logz.io temp directory
function download_yq {
    local exit_code=7
    local func_name="${FUNCNAME[0]}"

    local message='Downloading yq ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_DOWNLOADS" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    curl -fsSL "$YQ_URL_DOWNLOAD" >"$LOGZIO_TEMP_DIR/yq.tar.gz" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error downloading yq tar.gz: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_DOWNLOADS" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    tar -zxf "$LOGZIO_TEMP_DIR/yq.tar.gz" --directory "$LOGZIO_TEMP_DIR" --overwrite 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error extracting yq tar.gz file: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_DOWNLOADS" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    chmod +x "$YQ_BIN" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error giving execute premissions to '$YQ_BIN': $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_DOWNLOADS" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Gets the agent json from the agent or local file
# Input:
#   ---
# Output:
#   Agent json file in Logz.io temp directory
function get_agent_json {
    local exit_code=8
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
            message="agent.bash ($exit_code): error copying '$AGENT_JSON_FILE' to '$AGENT_JSON': $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
            write_task_post_run "write_error \"$message\""

            return $exit_code
        fi

        return
    fi

    # Getting agent json from agent
    message='Getting agent json from agent ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    curl -fsSL "$APP_URL/telemetry-agent/public/agents/configuration/$AGENT_ID" >"$AGENT_JSON" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error getting Logz.io agent json from agent. make sure your url is valid: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    get_json_file_field_value "$AGENT_JSON" '.statusCode'
    local func_status=$?
    if [[ $func_status -eq 1 ]]; then
        message="agent.bash ($exit_code): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
    if [[ $func_status -eq 3 ]]; then
        return
    fi

    local status_code="$JSON_VALUE"

    message="agent.bash ($exit_code): error getting Logz.io agent json from agent (statusCode '$status_code'). make sure your id is valid."
    send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_task_post_run "write_error \"$message\""

    return $exit_code
}

# Gets agent json info
# input:
#   ---
# Output:
#   PLATFORM - Platfrom name
#   SUB_TYPE - Subtype name
#   DATA_SOURCES - List of datasource names
function get_agent_json_info {
    local exit_code=9
    local func_name="${FUNCNAME[0]}"

    local message='Getting agent json info ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"
    
    get_json_file_field_value "$AGENT_JSON" '.configuration.name'
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    local platform="$JSON_VALUE"
    
    message="Platform is '$platform'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local command="PLATFORM='$platform'"
    write_task_post_run "$command"

    get_json_file_field_value "$AGENT_JSON" '.configuration.subtypes[0].name'
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
    
    local sub_type="$JSON_VALUE"

    message="Subtype is '$sub_type'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    command="SUB_TYPE='$sub_type'"
    write_task_post_run "$command"
    
    get_json_file_field_value_list "$AGENT_JSON" '.configuration.subtypes[0].datasources[]'
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    local data_sources=("${JSON_VALUE[@]}")

    local index=0
    local data_source_names=()
    for data_source in "${data_sources[@]}"; do
        get_json_str_field_value "$data_source" '.name'
        if [[ $? -ne 0 ]]; then
            message="agent.bash ($exit_code): $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
            write_task_post_run "write_error \"$message\""

            return $exit_code
        fi
        
        local data_source_name="$JSON_VALUE"

        message="DataSource #$((index+1)) is '$data_source_name'"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        data_source_names+=("$data_source_name")
        ((index++))
    done

    command="DATA_SOURCES=${data_source_names[@]}"
    write_task_post_run "$command"
}

# Gets Logz.io listener url
# Input:
#   ---
# Ouput:
#   LISTENER_URL - Logz.io listener url
function get_logzio_listener_url {
    local exit_code=10
    local func_name="${FUNCNAME[0]}"

    local message='Getting Logz.io listener url ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    get_json_file_field_value "$AGENT_JSON" '.listenerUrl'
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): $result"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
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
    local exit_code=11
    local func_name="${FUNCNAME[0]}"

    local message='Donwloading subtype files ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    if [[ -z "$REPO_RELEASE" ]]; then
        curl -fsSL "https://github.com/logzio/logzio-agent-manifest/releases/latest/download/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz" >"$LOGZIO_TEMP_DIR/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="agent.bash ($exit_code): error downloading subtype tar.gz file from Logz.io repo: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
            write_task_post_run "write_error \"$message\""

            return $exit_code
        fi
    else
        curl -fsSL "https://github.com/logzio/logzio-agent-manifest/releases/download/$REPO_RELEASE/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz" >"$LOGZIO_TEMP_DIR/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            message="agent.bash ($exit_code): error downloading subtype tar.gz file from Logz.io repo: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
            write_task_post_run "write_error \"$message\""

            return $exit_code
        fi
    fi
    
    tar -zxf "$LOGZIO_TEMP_DIR/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz" --directory "$LOGZIO_TEMP_DIR" --overwrite 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error extracting files from '$LOGZIO_TEMP_DIR/linux_${PLATFORM,,}_${SUB_TYPE,,}.tar.gz': $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Runs subtype prerequisites
# Input:
#   ---
# Output:
#   ---
function run_sub_type_prerequisites {
    local exit_code=12
    local func_name="${FUNCNAME[0]}"

    local message='Laoding subtype prerequisites functions ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/$PREREQUISITES_FUNCTIONS_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error loading subtype prerequisites functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_error "$message"

        IS_AGENT_FAILED=true
        exit $exit_code
    fi

    message='Running subtype prerequisites ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/$PREREQUISITES_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error running subtype prerequisites: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_error "$message"

        IS_AGENT_FAILED=true
        exit $exit_code
    fi
}

# Runs subtype installer
# Input:
#   ---
# Output:
#   ---
function run_sub_type_installer {
    local exit_code=13
    local func_name="${FUNCNAME[0]}"

    local message='Laoding subtype installer functions ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/$INSTALLER_FUNCTIONS_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error loading subtype installer functions: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_error "$message"

        IS_AGENT_FAILED=true
        exit $exit_code
    fi

    message='Running subtype installer ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/$INSTALLER_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error running subtype installer: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_error "$message"

        IS_AGENT_FAILED=true
        exit $exit_code
    fi
}

# Runs subtype post-requisites
# Input:
#   ---
# Output:
#   ---
function run_sub_type_postrequisites {
    local exit_code=14
    local func_name="${FUNCNAME[0]}"

    local message='Running subtype post-requisites ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/$POSTREQUISITES_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error running subtype post-requisites: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_INIT" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_error "$message"

        IS_AGENT_FAILED=true
        exit $exit_code
    fi
}
