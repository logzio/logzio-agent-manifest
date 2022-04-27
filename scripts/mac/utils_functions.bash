#!/bin/bash

#################################################################################################################################
###################################################### Utils Mac Functions ######################################################
#################################################################################################################################

# Prints error message in red
# Input:
#   Message text
function print_error () {
    local message="$1"

    tput setaf 1
    echo -e "$message"
    tput setaf 7
}

# Prints success message in green
# Input:
#   Message text
function print_success () {
    local message="$1"

    tput setaf 2
    echo -e "$message"
    tput setaf 7
}

function delete_temp_dir () {
    rm -R logzio-temp
}

# Executes command with progress indicator
# Input:
#   Command to execute
#   Step description
# Error:
#   Exit Code according the executed command
function execute_task () {
    local command="$1"
    local step="$2"
    local frame=("-" "\\" "|" "/")
    local frame_interval=0.25

    tput civis -- invisible
    
    #$command > logzio-temp/result &
    $command &
    local pid=$!

    while true; do
        echo -ne "\r[   ] $step ..."

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
    local result=$(cat logzio-temp/run_post_task)

    if [ $status -ne 0 ]; then
        echo -ne "\r[ $(tput setaf 1)✗$(tput setaf 7) ] $step\n"
        eval "$result"
        #delete_temp_dir

        tput cnorm -- normal
        exit $status
    fi

    echo -ne "\r[ $(tput setaf 2)✔$(tput setaf 7) ] $step\n"
    eval "$result"
    #> logzio-temp/run_post_task

    tput cnorm -- normal
}
