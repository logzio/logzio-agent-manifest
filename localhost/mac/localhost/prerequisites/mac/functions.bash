#!/bin/bash

#################################################################################################################################
################################################# Prerequisites Mac Functions ###################################################
#################################################################################################################################

# Checks if yq is installed
# Error:
#   Exit Code 1
function is_yq_installed () {
    write_log "INFO" "Checking if yq is installed ..."

    which yq >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        return
    fi

    install_homebrew

    write_log "INFO" "Installing yq ..."
    brew install yq >/dev/null 2>$task_error_file
    if [[ $? -eq 0 ]]; then
        return
    fi

    local err=$(cat $task_error_file)
    write_run "print_error \"prerequisites.bash (1): failed to install yq.\n  $err\""
    return 1
}

# Checks if localhost can connect to Logz.io logs (port 8071)
# Error:
#   Exit Code 2
function can_localhost_connect_to_logzio_logs () {
    write_log "INFO" "Checking if localhost can connect to Logz.io logs (port 8071) ..."

    local result=$(nc -v -G 2 -w 2 -z listener.logz.io 8071 2>&1 | grep succeeded)
    if [[ ! -z "$result" ]]; then
        return
    fi

    write_run "print_error \"prerequisites.bash (2): localhost cannot connect to Logz.io logs. please check your network for port 8071\""
    return 2
}

# Checks if localhost can connect to Logz.io metrics (port 8053)
# Error:
#   Exit Code 2
function can_localhost_connect_to_logzio_metrics () {
    write_log "INFO" "Checking if localhost can connect to Logz.io metrics (port 8053) ..."

    local result=$(nc -v -G 2 -w 2 -z listener.logz.io 8053 2>&1 | grep succeeded)
    if [[ ! -z "$result" ]]; then
        return
    fi

    write_run "print_error \"prerequisites.bash (2): localhost cannot connect to Logz.io logs. please check your network for port 8053\""
    return 2
}
