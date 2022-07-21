#!/bin/bash

#################################################################################################################################
################################################# Prerequisites Mac Functions ###################################################
#################################################################################################################################

# Gets otelcontribcol binary from logzio-agent-manifest repo
# Error:
#   Exit Code 1
function get_otelcontribcol_binary () {
    write_log "INFO" "Getting otelcontribcol binary ..."
    curl -fsSL $repo_path/prerequisites/otelcontribcol_darwin_amd64 > ./otelcontribcol_darwin_amd64 2>$task_error_file
    if [[ $? -eq 0 ]]; then
        return
    fi

    local err=$(cat $task_error_file)
    write_run "print_error \"prerequisites.bash (1): failed to get otelcontribcol binary file from logzio-agent-manifest repo.\n  $err\""
    return 1
}

# Checks if localhost can connect to Logz.io logs (port 8071)
# Error:
#   Exit Code 2
function can_localhost_connect_to_logzio_logs () {
    write_log "INFO" "Checking if localhost can connect to Logz.io logs (port 8071) ..."

    local result=$(sleep 1 | telnet listener.logz.io 8071 | grep Connected)
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

    local result=$(sleep 1 | telnet listener.logz.io 8053 | grep Connected)
    if [[ ! -z "$result" ]]; then
        return
    fi

    write_run "print_error \"prerequisites.bash (2): localhost cannot connect to Logz.io logs. please check your network for port 8053\""
    return 2
}
