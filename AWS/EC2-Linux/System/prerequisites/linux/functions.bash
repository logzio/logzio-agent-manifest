#!/bin/bash

#################################################################################################################################
################################################ Prerequisites Linux Functions ##################################################
#################################################################################################################################

# Installs yq
# Output:
#   yq_bin - The yq binary file path
# Error:
#   Exit Code 1
function install_yq () {
    write_log "INFO" "Installing yq ..."
    curl -fsSL https://github.com/mikefarah/yq/releases/download/v4.27.2/yq_linux_amd64.tar.gz > $logzio_temp_dir/yq.tar.gz 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to get yq binary file from Github.\n  $err\""
        return 1
    fi

    yq_bin="$logzio_temp_dir/yq_linux_amd64"
    tar -zxf $logzio_temp_dir/yq.tar.gz --directory $logzio_temp_dir
    write_run "yq_bin=\"$yq_bin\""
}

# Checks if EC2 server can connect to Logz.io logs (port 8071)
# Error:
#   Exit Code 2
function can_ec2_server_connect_to_logzio_logs () {
    write_log "INFO" "Checking if EC2 server can connect to Logz.io logs (port 8071) ..."

    wget -q -t 3 --timeout=5 listener.logz.io:8071
    if [[ $? -eq 8 ]]; then
        return
    fi

    write_run "print_error \"prerequisites.bash (2): EC2 server cannot connect to Logz.io logs. please check your network for port 8071\""
    return 2
}

# Checks if EC2 server can connect to Logz.io metrics (port 8053)
# Error:
#   Exit Code 2
function can_ec2_server_connect_to_logzio_metrics () {
    write_log "INFO" "Checking if EC2 server can connect to Logz.io metrics (port 8053) ..."

    wget -q -t 3 --timeout=5 listener.logz.io:8053
    if [[ $? -eq 8 ]]; then
        return
    fi

    write_run "print_error \"prerequisites.bash (2): EC2 server cannot connect to Logz.io logs. please check your network for port 8053\""
    return 2
}
