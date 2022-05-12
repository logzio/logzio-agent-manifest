#!/bin/bash

#################################################################################################################################
###################################################### Utils Mac Functions ######################################################
#################################################################################################################################

# Prints error message in red
# Input:
#   message - Message text
# Output:
#   The message
function print_error () {
    local message="$1"
    echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] $message" >> logzio_agent.log
    echo -e "\033[0;31m$message\033[0;37m"
}

# Deletes the temp directory
function delete_temp_dir () {
    rm -R logzio-temp
}

# Finds the requested parameter in params 
# Inputs: 
#   params - The parameters in the application json
#   requested_name - The parameter name to find
# Output:
#   The requested parameter if requested_name was found, empty otherwise.
function find_param () {
    local params="$1"
    local requested_name="$2"
    local requested_param=""

    while read -r param; do
        local name=$(echo -e "$param" | jq -r '.name')
        if [[ "$name" = "$requested_name" ]]; then
            requested_param="$param"
        fi
    done < <(echo -e "$params" | jq -c '.')

    echo -e "$requested_param"
}

# Executes command with progress indicator
# Input:
#   command - Command to execute
#   desc - Task description
# Error:
#   Exit Code according the executed command
function execute_task () {
    local command="$1"
    local desc="$2"
    local frame=("-" "\\" "|" "/")
    local frame_interval=0.25

    tput civis -- invisible
    
    $command &
    local pid=$!

    while true; do
        echo -ne "\r[   ] $desc ..."

        for i in "${!frame[@]}"; do
            echo -ne "\r[ ${frame[i]} ]"
            sleep $frame_interval
        done

        if ! ps -p $pid &>/dev/null; then
            break
        fi
    done

    wait $pid
    local status=$?

    if [[ $status -ne 0 ]]; then
        echo -ne "\r[ \033[1;31m✗\033[0;37m ] \033[1;31m$desc ...\033[0;37m\n"
        tput cnorm -- normal
        
        source ./logzio-temp/run
        delete_temp_dir
        exit $status
    fi

    echo -ne "\r[ \033[1;32m✔\033[0;37m ] \033[1;32m$desc ...\033[0;37m\n"
    tput cnorm -- normal

    source ./logzio-temp/run
    > logzio-temp/run
}
