#!/bin/bash

#################################################################################################################################
##################################################### LINUX Utils Functions #####################################################
#################################################################################################################################

# Prints error message in red
# Input:
#   message - Message text
# Output:
#   The message
function write_error {
    local message=$1

    write_log $LOG_LEVEL_ERROR $message
    echo -e "$RED_COLOR$Message$WHITE_COLOR"
}

# Prints warning message in yellow
# Input:
#   message - Message text
# Output:
#   The message
function write_warning {
    local message=$1

    write_log $LOG_LEVEL_WARN $message
    echo -e "$YELLOW_COLOR$message$WHITE_COLOR"
}

# Writes log into log file
# Input:
#   log_level - Level of the log (DEBUG/INFO/ERROR/WARN)
#   message - Message text
# Output:
#   ---
function write_log {
    local log_level=$1
    local message=$2
    
    echo -e "[$log_level] [$(date +'%Y-%m-%d %H:%M:%S')] $message" >>$AGENT_LOG_FILE
}

# Writes command into task post run script file
# Input:
#   command - The command to write into the file
# Output:
#   ---
function write_task_post_run {
    local command=$1

    echo -e $command >>$TASK_POST_RUN_FILE
}

# Gets task error file content
# Input:
#   ---
# Output:
#   Task error file content
function get_task_error_message {
    local err=$(cat $TASK_POST_RUN_FILE)
    err=${err//'"'/''}

    echo -e $err
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
    local level=$1
    local message=$2
    local step=$3
    local script_name=$4
    local func_name=$5
    local agent_id=$6
    local platform=$7
    local sub_type=$8
    local data_source=$9

    message=${message//'\'/'\\'}
    message=${message//'"'/'\"'}

    log="{\"@timestamp\":\"$(date +'%Y-%m-%dT%H:%M:%S%:z')\",\"level\":\"$level\",\"message\":\"$message\",\"step\":\"$step\",\"script\":\"$script_name\",\"func\":\"$func_name\",\"os\":\"Linux\",\"os_name\":\"$LINUX_NAME\",\"os_version\":\"$LINUX_VERSION\",\"shell_version\":\"$BASH_VERSION\""

    if [[ $level == $LOG_LEVEL_ERROR ]]; then
        local error_id_part=$(echo -e $message | grep -oe '([0-9]\+)'
        local error_id=$(echo -e $error_id_part | grep -oe '[0-9]\+'
        
        log+=",\"error_id\":\"$error_id\""
    fi
    if [[ ! -z $agent_id ]]; then
        log+=",\"agent_id\":\"$agent_id\""
    fi
    if [[ ! -z $platform ]]; then
        log+=",\"platform\":\"$platform\""
    fi
    if [[ ! -z $sub_type ]]; then
        log+=",\"subtype\":\"$sub_type\""
    fi
    if [[ ! -z $data_source ]]; then
        log+=",\"datasource\":\"$data_source\""
    fi

    log+='}'

    curl -fsSL $SQS_URL -d Action='SendMessage' -d MessageBody=$log 2>$TASK_ERROR_FILE
    if [[ $? -ne 0 ]]; then
        write_task_post_run "write_warning \"failed to send a request with log message to Logz.io agent SQS: $(get_task_error_message)\""
    fi
}

# Checks if function arguments exist
# Input:
#   func_args - Dictionary of function arguments
#   arg_name - Argument names
# Output:
#   Retunrs nothing if everything ok.
#   If got error will output message with exit code.
function are_func_args_exist {
    local func_args=$1
    local arg_names=$2

    if [[ ${#func_args} -eq 0 ]]; then
        echo -e 'function hashtable argument is empty'
        return 1
    fi

    for arg_name in ${arg_names[@]}; do
        if [[ ! -z ${func_args[$arg_name]} ]]; then
            echo -e "function dictionary argument does not have '$arg_name' key"
            return 2
        fi
    done
}

# Gets json string field value
# input:
#   json_str - Json string
#   json_path - Json path
# Output:
#   JSON_VALUE - The value of the field. Only if got no error.
#   If got error will output message with exit code.
function get_json_str_field_value {
    local json_str=$1
    local json_path=$2

    local result=$(echo -e $json_str | $JQ_BIN -r $json_path 2>$TASK_ERROR_FILE
    if [[ $? -ne 0 ]]; then
        json_str=${json_str/'"'/'\"'}
        echo -e "error getting '$json_path' from '$json_str': $(get_task_error_message)"
        return 1
    fi
    if [[ -z $result ]]; then
        echo -e "'$json_path' is empty in '$json_str'"
        return 2
    fi
    if [[ $result == 'null' ]]; then
        echo -e "'$json_path' does not exist in '$json_str'"
        return 3
    fi

    JSON_VALUE=$result
}

# Gets json string field value list
# input:
#   json_str - Json string
#   json_path - Json path
# Output:
#   JSON_VALUE - The value (list) of the field. Only if got no error.
#   If got error will output message with exit code.
function get_json_str_field_value_list {
    local json_str=$1
    local json_path=$2

    local result=$(echo -e $json_str | $JQ_BIN -c $json_path 2>$TASK_ERROR_FILE
    if [[ $? -ne 0 ]]; then
        json_str=${json_str/'"'/'\"'}
        echo -e "error getting '$json_path' from '$json_str': $(get_task_error_message)"
        return 1
    fi
    if [[ ${#result} -eq 0 ]]; then
        echo -e "'$json_path' is empty in '$json_str'"
        return 2
    fi

    JSON_VALUE=$result
}

# Gets json file field value
# input:
#   json_file - Json file path
#   json_path - Json path
# Output:
#   JSON_VALUE - The value of the field. Only if got no error.
#   If got error will output message with exit code.
function get_json_file_field_value {
    local json_str=$1
    local json_path=$2

    local result=$($JQ_BIN -r $json_path $json_file 2>$TASK_ERROR_FILE)
    if [[ $? -ne 0 ]]; then
        echo -e "error getting '$json_path' from '$json_file': $(get_task_error_message)"
        return 1
    fi
    if [[ -z $result ]]; then
        echo -e "'$json_path' is empty in '$json_file'"
        return 2
    fi
    if [[ $result == 'null' ]]; then
        echo -e "'$json_path' does not exist in '$json_file'"
        return 3
    }

    JSON_VALUE=$result
}

# Gets json file field value list
# input:
#   json_file - Json file path
#   json_path - Json path
# Output:
#   JSON_VALUE - The value (list) of the field. Only if got no error.
#   If got error will output message with exit code.
function get_json_file_field_value_list {
    local json_str=$1
    local json_path=$2

    local result=$($JQ_BIN -c $json_path $json_file 2>$TASK_ERROR_FILE)
    if [[ $? -ne 0 ]]; then
        echo -e "error getting '$json_path' from '$json_file': $(get_task_error_message)"
        return 1
    fi
    if [[ ${#result} -eq 0 ]]; then
        echo -e "'$json_path' is empty in '$json_file'"
        return 2
    fi

    JSON_VALUE=$result
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
    local yaml_file=$1
    local yaml_path=$2
    local value=$3

    $YQ_BIN -i "$yaml_path += ""\"$value\"""" $yaml_file 2>$TASK_ERROR_FILE
    if [[ $? -ne 0 ]]; then
        echo -e "error adding '$value' to '$yaml_path in '$yaml_path': $(get_task_error_message)"
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
    local yaml_file=$1
    local yaml_path=$2
    local value=$3

    $YQ_BIN -i "$yaml_path = ""\"$value\"""" $yaml_file 2>$TASK_ERROR_FILE
    if [[ $? -ne 0 ]]; then
        echo -e "error setting '$value' to '$yaml_path in '$yaml_file': $(get_task_error_message)"
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
function Get-YamlFileFieldValue {
    local yaml_file=$1
    local yaml_path=$2

    local result=$($YQ_BIN $yaml_path $yaml_file 2>$TASK_ERROR_FILE)
    if [[ $? -ne 0 ]]; then
        echo -e "error getting '$yaml_path' from '$yaml_file': $(get_task_error_message)"
        return 1
    fi
    if [[ -z $result ]]; then
        echo -e "'$yaml_path' is empty in '$yaml_file'"
        return 2
    fi
    if [[ $result == 'null' ]]; then
        echo -e "'$yaml_path' does not exist in '$yaml_file'"
        return 3
    fi

    YAML_VALUE=$result
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
    local yaml_file_source=$1
    local yaml_file_dest=$2
    local yaml_path_source=$3
    local yaml_path_dest=$4

    $YQ_BIN eval-all -i "select(fileIndex==0)$yaml_path_dest += select(fileIndex==1)$yaml_path_source | select(fileIndex==0)" $yaml_file_dest $yaml_file_source 2>$TASK_ERROR_FILE
    if [[ $? -ne 0 ]]; then
        if [[ -z $yaml_path_source ]]; then
            yaml_path_source='.'
        fi

        echo -e "error adding '$yaml_path_source' in '$yaml_file_source' to '$yaml_path_dest' in '$yaml_file_dest': $(get_task_error_message)"
        return 1
    fi
}

# Converts list to string
# Input:
#   list - List of items
# Output:
#   List of items as string
function convert_list_to_str {
    local list=$1

    if [[ ${#list} -eq 0 ]]; then
        echo -e '()'
        return
    fi

    local str_list=''
    for item in $list; do
        if [[ $(echo -e $item | grep -oe "^'.*'$") || $(echo -e $item | grep -oe '^".*"$') ]]; then
            str_list+="$item "
        else
            str_list+="'$item' "
        fi
    done

    str_list=${str_list:0: ${#str_list}-1}
    echo -e "($str_list)"
}

# Gets param by name
# Input:
#   params - Parameters from the agent json
#   param_name - Parameter name
# Output:
#   TARGET_PARAM - The param json object. Only if got no error.
#   If got error will output message with exit code.
function get_param {
    local params=$1
    local param_name=$2

    for param in $params; do
        local err=$(get_json_str_field_value $param '.name')
        if [[ ${#err} -ne 0 ]]; then
            echo -e $err[0]
            return 1
        fi
        
        local name=$json_value
        if [[ $name != $param_name ]]; then
            continue
        fi

        TARGET_PARAM=$param
        return
    }

    echo -e "$param_name param was not found"
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
    local params=$1
    local param_name=$2

    local err=$(get_param $params $param_name)
    if [[ ${#err} -ne 0 ]]; then
        echo -e $err[0]
    fi

    local param=$TARGET_PARAM

    err=$(get_json_str_field_value $param '.value')
    if [[ ${#err} -ne 0 && $err[1] -ne 2 ]]; then
        echo -e $err[0]
        return 1
    fi
    if [[ ${#err} -ne 0 ]]; then
        PARAM_VALUE=''
        return
    fi
    
    PARAM_VALUE=$JSON_VALUE
}

# Gets param value list
# Inputs: 
#   params - Parameters from the agent json
#   param_name - Parameter name to get value of
# Output:
#   PARAM_VALUE - The value (list) of the target param. Only if got no error.
#   If got error will output message with exit code.
function get_param_value_list {
    local params=$1
    local param_name=$2

    local err=$(get_Param $params $param_name)
    if [[ ${#err} -ne 0 ]]; then
        echo -e $err[0]
    fi

    param=$TARGET_PARAM

    err=$(get_json_str_field_value_list $param '.value[]')
    if [[ ${#err} -ne 0 && $err[1] -eq 1 ]]; then
        echo -e $err[0]
        return 1
    fi
    if [[ ${#err} -ne 0 ]]; then
        PARAM_VALUE=()
        return
    fi
    
    PARAM_VALUE=$JSON_VALUE
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
    local func_name=$1
    local func_args=$2
    local description=$3
    local scripts_to_load=$4

    local frame=('-' '\' '|' '/')
    local frame_interval=250
    local timeout=300
    local counter=0

    if [[ ${#func_args} -eq 0 ]]; then
        $func_name &
    else
        $func_name $func_args &
    fi

    local pid=$!

    while true; do
        echo -ne "\r[   ] $description ..."

        for i in "${!frame[@]}"; do
            echo -ne "\r[ ${frame[i]} ]"
            sleep $frame_interval
        done

        ((counter++))

        if ! ps -p $pid &>/dev/null; then
            break
        fi

        if [[ $counter -eq $timeout ]]; then
            kill $pid
            is_timeout=true

            local message='utils.ps1 (1): timeout error: the task was not completed in time'
            send_log_to_logzio $LOG_LEVEL_ERROR $message '' $LOG_SCRIPT_AGENT $func_name $AGENT_ID
            write_task_post_run "write_error \"$message\""
            break
        fi
    done

    wait $pid 2>/dev/null
    local exit_code=$?

    if [[ $exit_code -ne 0 || $is_timeout ]]; then
        echo -ne "\r[ $RED_COLOR_BOLD✗$WHITE_COLOR ] $RED_COLOR_BOLD$description ...$WHITE_COLOR\n"

        if [[ -f $TASK_POST_RUN_FILE ]]; then
            source $TASK_POST_RUN_FILE 2>$TASK_ERROR_FILE
            if [[ $? -ne 0 ]]; then
                local message="utils.ps1 (2): error running task post run script: $(get_task_error_message)"
                send_log_to_logzio $LOG_LEVEL_ERROR $message '' $LOG_SCRIPT_UTILS_FUNCTIONS $func_name $AGENT_ID
                write_error $message

                IS_AGENT_FAILED=true
                exit 2
            fi
        fi

        >$TASK_POST_RUN_FILE

        if $is_timeout; then
            exit_code=1
        fi

        if $IS_POSTREQUISITE_FAILED; then
            return
        else
            $IS_AGENT_FAILED=true
        fi
        
        exit $exit_code
    fi

    echo -ne "\r[ $GREEN_COLOR_BOLD✔$WHITE_COLOR ] $GREEN_COLOR_BOLD$description ...$WHITE_COLOR\n"

    if [[ -f $TASK_POST_RUN_FILE ]]; then
        source $TASK_POST_RUN_FILE 2>$TASK_ERROR_FILE
        if [[ $? -ne 0 ]]; then
            local message="utils.ps1 (2): error running task post run script: $(get_task_error_message)"
            send_log_to_logzio $LOG_LEVEL_ERROR $message '' $LOG_SCRIPT_UTILS_FUNCTIONS $func_name $AGENT_ID
            write_error $message

            IS_AGENT_FAILED=true
            exit 2
        fi
    fi

    >$TASK_POST_RUN_FILE
}
