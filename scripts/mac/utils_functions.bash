#!/bin/bash

#################################################################################################################################
###################################################### MAC Utils Functions ######################################################
#################################################################################################################################

# Prints error message in red
# Input:
#   message - Message text
# Output:
#   The message
function write_error {
    local message="$1"

    write_log "$LOG_LEVEL_ERROR" "$message"
    echo -e "$RED_COLOR$message$WHITE_COLOR"
}

# Prints warning message in yellow
# Input:
#   message - Message text
# Output:
#   The message
function write_warning {
    local message="$1"

    write_log "$LOG_LEVEL_WARN" "$message"
    echo -e "$YELLOW_COLOR$message$WHITE_COLOR"
}

# Writes log into log file
# Input:
#   log_level - Level of the log (DEBUG/INFO/ERROR/WARN)
#   message - Message text
# Output:
#   ---
function write_log {
    local log_level="$1"
    local message="$2"
    
    echo -e "[$log_level] [$(date +'%Y-%m-%d %H:%M:%S')] $message" >>"$AGENT_LOG_FILE"
}

# Writes command into task post run script file
# Input:
#   command - The command to write into the file
# Output:
#   ---
function write_task_post_run {
    local command="$1"

    echo -e "#!/bin/bash" >>"$TASK_POST_RUN_FILE"
    echo -e "$command" >>"$TASK_POST_RUN_FILE"
}

# Gets task error file content
# Input:
#   ---
# Output:
#   Task error file content
function get_task_error_message {
    local err=$(cat "$TASK_ERROR_FILE")
    err="${err//\"/\\\"}"

    echo -e "$err"
}

# Sends log to Logz.io
# Input:
#   level - Log level
#   message - Log message
#   step - Log step
#   script_name - Log script name
#   func_name - Log function name
#   agent_id - Agent id
#   platform - Platform name
#   sub_type - Subtype name
#   data_source - Datasource name
# Output:
#   ---
function send_log_to_logzio {
    local level="$1"
    local message="$2"
    local step="$3"
    local script_name="$4"
    local func_name="$5"
    local agent_id="$6"
    local platform="$7"
    local sub_type="$8"
    local data_source="$9"

    message="${message//\"/\\\"}"
    message=$(echo -e "$message" | tr '\n' ' ')

    log="{\"datetime\":\"$(date +'%Y-%m-%dT%H:%M:%S%z')\",\"level\":\"$level\",\"message\":\"$message\",\"step\":\"$step\",\"script\":\"$script_name\",\"func\":\"$func_name\",\"os\":\"Mac\",\"os_name\":\"$MAC_NAME\",\"os_version\":\"$MAC_VERSION\",\"shell_version\":\"$BASH_VERSION\",\"cpu_arch\":\"$CPU_ARCH\""

    if [[ "$level" == "$LOG_LEVEL_ERROR" ]]; then
        local error_id_part=$(echo -e "$message" | grep -o '([0-9]\+)')
        local error_id=$(echo -e "$error_id_part" | grep -o '[0-9]\+')
        
        log+=",\"error_id\":\"$error_id\""
    fi
    if [[ ! -z "$agent_id" ]]; then
        log+=",\"agent_id\":\"$agent_id\""
    fi
    if [[ ! -z "$platform" ]]; then
        log+=",\"platform\":\"$platform\""
    fi
    if [[ ! -z "$sub_type" ]]; then
        log+=",\"subtype\":\"$sub_type\""
    fi
    if [[ ! -z "$data_source" ]]; then
        log+=",\"datasource\":\"$data_source\""
    fi

    log+='}'

    curl -fsSL "$SQS_URL" -d Action='SendMessage' -d MessageBody="$log" >/dev/null 2>&1 &
}

# Gets json string field value
# input:
#   json_str - Json string
#   json_path - Json path
# Output:
#   JSON_VALUE - The value of the field. Only if got no error.
#   If got error will output message with exit code.
function get_json_str_field_value {
    local json_str="$1"
    local json_path="$2"

    local result=$(echo -e "$json_str" | $JQ_BIN -r "$json_path" 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        echo -e "error getting '$json_path' from '${json_str//\"/\\\"}': $(get_task_error_message)" >"$TASK_ERROR_FILE"
        return 1
    fi
    if [[ -z "$result" ]]; then
        echo -e "'$json_path' is empty in '${json_str//\"/\\\"}'" >"$TASK_ERROR_FILE"
        return 2
    fi
    if [[ "$result" == 'null' ]]; then
        echo -e "'$json_path' does not exist in '${json_str//\"/\\\"}'" >"$TASK_ERROR_FILE"
        return 3
    fi

    JSON_VALUE="$result"
}

# Gets json string field value list
# input:
#   json_str - Json string
#   json_path - Json path
# Output:
#   JSON_VALUE - The value (list) of the field. Only if got no error.
#   If got error will output message with exit code.
function get_json_str_field_value_list {
    local json_str="$1"
    local json_path="$2"

    local result=$(echo -e "$json_str" | $JQ_BIN -c "$json_path" 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        echo -e "error getting '$json_path' from '$json_str': $(get_task_error_message)" >"$TASK_ERROR_FILE"
        return 1
    fi
    if [[ ${#result} -eq 0 ]]; then
        echo -e "'$json_path' is empty in '$json_str'" >"$TASK_ERROR_FILE"
        return 2
    fi

    readarray -t JSON_VALUE < <(echo -e "$result")
}

# Gets json file field value
# input:
#   json_file - Json file path
#   json_path - Json path
# Output:
#   JSON_VALUE - The value of the field. Only if got no error.
#   If got error will output message with exit code.
function get_json_file_field_value {
    local json_file="$1"
    local json_path="$2"

    local result=$($JQ_BIN -r "$json_path" "$json_file" 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        echo -e "error getting '$json_path' from '$json_file': $(get_task_error_message)" >"$TASK_ERROR_FILE"
        return 1
    fi
    if [[ -z "$result" ]]; then
        echo -e "'$json_path' is empty in '$json_file'" >"$TASK_ERROR_FILE"
        return 2
    fi
    if [[ "$result" == 'null' ]]; then
        echo -e "'$json_path' does not exist in '$json_file'" >"$TASK_ERROR_FILE"
        return 3
    fi

    JSON_VALUE="$result"
}

# Gets json file field value list
# input:
#   json_file - Json file path
#   json_path - Json path
# Output:
#   JSON_VALUE - The value (list) of the field. Only if got no error.
#   If got error will output message with exit code.
function get_json_file_field_value_list {
    local json_file="$1"
    local json_path="$2"

    local result=$($JQ_BIN -c "$json_path" "$json_file" 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        echo -e "error getting '$json_path' from '$json_file': $(get_task_error_message)" >"$TASK_ERROR_FILE"
        return 1
    fi
    if [[ ${#result} -eq 0 ]]; then
        echo -e "'$json_path' is empty in '$json_file'" >"$TASK_ERROR_FILE"
        return 2
    fi

    readarray -t JSON_VALUE < <(echo -e "$result")
}

# Adds yaml file field value
# input:
#   yaml_file - Yaml file path
#   yaml_path - Yaml path
#   value - Value to add
# Output:
#   Returns nothing if everything ok.
#   If got error will output message with exit code.
function add_yaml_file_field_value {
    local yaml_file="$1"
    local yaml_path="$2"
    local value="$3"

    $YQ_BIN -i "$yaml_path += \"$value\"" $yaml_file 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        echo -e "error adding '$value' to '$yaml_path in '$yaml_file': $(get_task_error_message)" >"$TASK_ERROR_FILE"
        return 1
    fi
}

# Sets yaml file field value
# input:
#   yaml_file - Yaml file path
#   yaml_path - Yaml path
#   value - Value to set
# Output:
#   Returns nothing if everything ok.
#   If got error will output message with exit code.
function set_yaml_file_field_value {
    local yaml_file="$1"
    local yaml_path="$2"
    local value="$3"

    $YQ_BIN -i "$yaml_path = \"$value\"" "$yaml_file" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        echo -e "error setting '$value' to '$yaml_path in '$yaml_file': $(get_task_error_message)" >"$TASK_ERROR_FILE"
        return 1
    fi
}

# Gets yaml file field value
# input:
#   yaml_file - Yaml file path
#   yaml_path - Yaml path
# Output:
#   YAML_VALUE - The value of the field. Only if got no error.
#   If got error will output message with exit code.
function get_yaml_file_field_value {
    local yaml_file="$1"
    local yaml_path="$2"

    local result=$($YQ_BIN "$yaml_path" "$yaml_file" 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        echo -e "error getting '$yaml_path' from '$yaml_file': $(get_task_error_message)" >"$TASK_ERROR_FILE"
        return 1
    fi
    if [[ -z "$result" ]]; then
        echo -e "'$yaml_path' is empty in '$yaml_file'" >"$TASK_ERROR_FILE"
        return 2
    fi
    if [[ "$result" == 'null' ]]; then
        echo -e "'$yaml_path' does not exist in '$yaml_file'" >"$TASK_ERROR_FILE"
        return 3
    fi

    YAML_VALUE="$result"
}

# Gets yaml file field value list
# input:
#   yaml_file - Yaml file path
#   yaml_path - Yaml path
# Output:
#   YAML_VALUE - The value (list) of the field. Only if got no error.
#   If got error will output message with exit code.
function get_yaml_file_field_value_list {
    local yaml_file="$1"
    local yaml_path="$2"

    local result=$($YQ_BIN "$yaml_path" "$yaml_file" 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        echo -e "error getting '$yaml_path' from '$yaml_file': $(get_task_error_message)" >"$TASK_ERROR_FILE"
        return 1
    fi
    if [[ -z "$result" ]]; then
        echo -e "'$yaml_path' is empty in '$yaml_file'" >"$TASK_ERROR_FILE"
        return 2
    fi
    if [[ "$result" == 'null' ]]; then
        echo -e "'$yaml_path' does not exist in '$yaml_file'" >"$TASK_ERROR_FILE"
        return 3
    fi

    readarray -t YAML_VALUE < <(echo -e "$result")
}

# Adds yaml file field value to another yaml file field
# input:
#   yaml_file_source - Source yaml file path
#   yaml_file_dest - Destination yaml file path
#   yaml_path_source - Yaml path of the source yaml
#   yaml_path_dest - Yaml path of the destination yaml
# Output:
#   Retunrs nothing if everything is ok.
#   If got error will output message with exit code.
function add_yaml_file_field_value_to_another_yaml_file_field {
    local yaml_file_source="$1"
    local yaml_file_dest="$2"
    local yaml_path_source="$3"
    local yaml_path_dest="$4"

    $YQ_BIN eval-all -i "select(fileIndex==0)$yaml_path_dest += select(fileIndex==1)$yaml_path_source | select(fileIndex==0)" "$yaml_file_dest" "$yaml_file_source" 2>$TASK_ERROR_FILE
    if [[ $? -ne 0 ]]; then
        if [[ -z $yaml_path_source ]]; then
            yaml_path_source='.'
        fi

        echo -e "error adding '$yaml_path_source' in '$yaml_file_source' to '$yaml_path_dest' in '$yaml_file_dest': $(get_task_error_message)" >"$TASK_ERROR_FILE"
        return 1
    fi
}

# Converts list to string
# Input:
#   ---
# Output:
#   List of items as string
function convert_list_to_str {
    if [[ ${#LIST[@]} -eq 0 ]]; then
        echo -e '()'
        return
    fi

    local str_list='('
    for item in "${LIST[@]}"; do
        if [[ $(echo -e "$item" | grep -o "^'.*'$") || $(echo -e "$item" | grep -o '^".*"$') ]]; then
            str_list+="$item "
        else
            str_list+="'$item' "
        fi
    done

    str_list=${str_list:0: ${#str_list}-1}
    str_list+=')'
    echo -e "$str_list"
}

# Gets param by name
# Input:
#   params - Parameters from the agent json
#   param_name - Parameter name
# Output:
#   TARGET_PARAM - The param json object. Only if got no error.
#   If got error will output message with exit code.
function get_param {
    local param_name="$1"

    for param in "${PARAMS[@]}"; do
        get_json_str_field_value "$param" '.name'
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        
        local name="$JSON_VALUE"

        if [[ "$name" != "$param_name" ]]; then
            continue
        fi

        TARGET_PARAM="$param"
        return
    done

    echo -e "$param_name param was not found" >"$TASK_ERROR_FILE"
    return 2
}

# Gets param value
# Inputs: 
#   params - Parameters from the agent json
#   param_name - Parameter name to get value of
# Output:
#   PARAM_VALUE - The value of the target param. Only if got no error.
#   If got error will output message with exit code.
function get_param_value {
    local param_name="$1"

    get_param "$param_name"
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    local param="$TARGET_PARAM"

    get_json_str_field_value "$param" '.value'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -ne 2 ]]; then
        return 2
    fi
    if [[ $func_status -ne 0 ]]; then
        PARAM_VALUE=''
        return
    fi
    
    PARAM_VALUE="$JSON_VALUE"
}

# Gets param value list
# Inputs: 
#   params - Parameters from the agent json
#   param_name - Parameter name to get value of
# Output:
#   PARAM_VALUE - The value (list) of the target param. Only if got no error.
#   If got error will output message with exit code.
function get_param_value_list {
    local param_name="$1"

    get_param "$param_name"
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    param="$TARGET_PARAM"

    get_json_str_field_value_list "$param" '.value[]'
    local func_status=$?
    if [[ $func_status -ne 0 && $func_status -eq 1 ]]; then
        return 2
    fi
    if [[ $func_status -ne 0 ]]; then
        PARAM_VALUE=()
        return
    fi
    
    PARAM_VALUE=("${JSON_VALUE[@]}")
}

# Gets Logz.io region
# Input:
#   listener_url - Logz.io listener url
# Output:
#   LOGZIO_REGION - Logz.io region
function get_logzio_region {
    local listener_url=$1

    local region='us'
    if [[ $listener_url = *'-'* ]]; then
        local listener_part=$(cut -d '.' -f1 <<< $listener_url)
        region=$(cut -d '-' -f2 <<< $listener_part)
    fi

    echo -e $region
}

# Executes task
# Input:
#   func_name - Function name to invoke
#   func_args - Hashtable of the function arguments
#   description - Task description that is going to be displayed
#   scripts_to_load - List of script names that need to be loaded before invoking the function
# Output:
#   ---
function execute_task {
    local func_name="$1"
    local description="$2"

    local frame=('-' "\\" '|' '/')
    local frame_interval=0.25
    local timeout=300
    local counter=0

    $func_name &
    local pid=$!

    while true; do
        echo -ne "\r  [   ] $description ..."

        for i in "${!frame[@]}"; do
            if ! ps -p $pid &>/dev/null; then
                break
            fi

            echo -ne "\r  [ ${frame[i]} ]"
            sleep $frame_interval
        done

        ((counter++))

        if ! ps -p $pid &>/dev/null; then
            break
        fi

        if [[ $counter -eq $timeout ]]; then
            kill $pid
            is_timeout=true

            local message='utils.bash (1): timeout error: the task was not completed in time'
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" '' "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
            write_task_post_run "write_error \"$message\""
            break
        fi
    done

    wait $pid 2>/dev/null
    local exit_code=$?

    if [[ $exit_code -ne 0 || $is_timeout ]]; then
        echo -ne "\r  [ $RED_COLOR_BOLD\xE2\x9C\x97$WHITE_COLOR ] $RED_COLOR_BOLD$description ...$WHITE_COLOR\n"

        if [[ -f "$TASK_POST_RUN_FILE" ]]; then
            source "$TASK_POST_RUN_FILE" 2>"$TASK_ERROR_FILE"
            if [[ $? -ne 0 ]]; then
                local message="utils.bash (2): error running task post run script: $(get_task_error_message)"
                send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" '' "$LOG_SCRIPT_UTILS_FUNCTIONS" "$func_name" "$AGENT_ID"
                write_error "$message"

                IS_AGENT_FAILED=true
                run_final
                exit 2
            fi
        fi

        >"$TASK_POST_RUN_FILE"

        if $is_timeout; then
            exit_code=1
        fi

        if $CONTINUE_IF_FAILED; then
            return
        elif $IS_POSTREQUISITES_STEP; then
            IS_POSTREQUISITES_FAILED=true
        else
            IS_AGENT_FAILED=true
        fi
        
        run_final
        exit $exit_code
    fi

    echo -ne "\r  [ $GREEN_COLOR_BOLD\xE2\x9C\x94$WHITE_COLOR ] $GREEN_COLOR_BOLD$description ...$WHITE_COLOR\n"

    if [[ -f "$TASK_POST_RUN_FILE" ]]; then
        source "$TASK_POST_RUN_FILE" 2>"$TASK_ERROR_FILE"
        if [[ $? -ne 0 ]]; then
            local message="utils.bash (2): error running task post run script: $(get_task_error_message)"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" '' "$LOG_SCRIPT_UTILS_FUNCTIONS" "$func_name" "$AGENT_ID"
            write_error "$message"

            IS_AGENT_FAILED=true
            run_final
            exit 2
        fi
    fi

    ((EXIT_CODE++))
    >"$TASK_POST_RUN_FILE"
}

# Check if binary is already installed with the correct version, if it does copy it to temp directory
# Input:
# - download_url - Binary/zipped binary file URL
# - binary_name - Binary file name
# - binary_path - Path to binary file in Logz.io temp directory
#   ---
# Output:
#   A binary file in Logz.io temp directory
function copy_installed_binary {
    local binary_name="$1"
    local download_url="$2"
    local binary_path="$3"

    # Check if the binary is installed
    if command -v "$binary_name" &>/dev/null; then
        # If version validation is not required, binary is considered installed
        if [ -z "$download_url" ]; then
            # Copy the installed binary to the specified path, if provided
            if [ -n "$binary_path" ]; then
                cp "$(command -v "$binary_name")" "$binary_path"
            fi
            return 0  # Binary is installed
        fi

        # Fetch the content of the version URL
        downloaded_version=$(curl -s "$download_url")

        # Check if the downloaded version matches the installed version
        installed_version=$("$binary_name" --version | head -n 1)
        if echo "$installed_version" | grep -E -q "$downloaded_version"; then
            # Copy the installed binary to the specified path, if provided
            if [ -n "$binary_path" ]; then
                cp "$(command -v "$binary_name")" "$binary_path"
            fi
            return 0  # Binary is installed with the correct version
        else
            return 1  # Binary is installed, but version does not match
        fi
    else
        return 1  # Binary is not installed
    fi
}

# Function to get the architecture-specific download URL
# Input:
# - download_url - Binary/zipped binary file URL
# - binary_name - Binary file name
# - binary_path - Path to binary file in Logz.io temp directory
#   ---
# Output:
#   A binary file in Logz.io temp directory
function get_arch_specific_url {
    local amd_url="$1"
    local arm_url="$2"

    if [[ ( "$CPU_ARCH" == "arm64" || "$CPU_ARCH" == "aarch64" ) && ! -z "$arm_url" ]]; then
        echo "$arm_url"
    elif [[ ( "$CPU_ARCH" == "amd64" || "$CPU_ARCH" == "x86_64" ) && ! -z "$amd_url" ]]; then
        echo "$amd_url"
    else
        echo "error getting arch specific url, arm_url: '$arm_url', amd_url: '$amd_url'"
    fi
}