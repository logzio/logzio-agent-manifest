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
    write_log "ERROR" "$message"
    echo -e "\033[0;31m$message\033[0;37m"
}

# Prints warning message in yellow
# Input:
#   message - Message text
# Output:
#   The message
function print_warning () {
    local message="$1"
    write_log "WARN" "$message"
    echo -e "\033[0;33m$message\033[0;37m"
}

# Writes log into Logz.io agent log file
# Input:
#   log_level - The level of the log (INFO/ERROR/WARN)
#   log - Log text
function write_log () {
    local log_level="$1"
    local log="$2"
    echo -e "[$log_level] [$(date +"%Y-%m-%d %H:%M:%S")] $log" >> $log_file
}

# Writes command into run file in Logz.io temp directory
# Input:
#   command - The command to write into the file
function write_run () {
    local command="$1"
    echo -e "$command" >> $run_file
}

# Deletes the temp directory
function delete_temp_dir () {
    rm -R $logzio_temp_dir
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
        if [[ -z "$name" || "$name" = null ]]; then
            continue
        fi

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
#   Exit Code 1 if got timeout error, otherwise Exit Code according the executed command
function execute_task () {
    local command="$1"
    local desc="$2"
    local frame=("-" "\\" "|" "/")
    local frame_interval=0.25
    local is_timeout=false
    local timeout=30
    local counter=0

    tput civis -- invisible
    
    $command &
    local pid=$!

    while true; do
        echo -ne "\r[   ] $desc ..."

        for i in "${!frame[@]}"; do
            echo -ne "\r[ ${frame[i]} ]"
            sleep $frame_interval
        done

        let "counter++"

        if ! ps -p $pid &>/dev/null; then
            break
        fi

        if [[ $counter -eq $timeout ]]; then
            kill $pid
            is_timeout=true
            write_run "print_error \"utils_functions.bash (1): timeout error: the task was not completed in time\""
            break
        fi
    done

    wait $pid
    local exit_code=$?

    if [[ $exit_code -ne 0 ]] || $is_timeout; then
        echo -ne "\r[ \033[1;31m✗\033[0;37m ] \033[1;31m$desc ...\033[0;37m\n"
        tput cnorm -- normal
        
        source $run_file
        delete_temp_dir

        if $is_timeout; then
            exit 1
        fi

        exit $exit_code
    fi

    echo -ne "\r[ \033[1;32m✔\033[0;37m ] \033[1;32m$desc ...\033[0;37m\n"
    tput cnorm -- normal

    source $run_file
    > $run_file
}
