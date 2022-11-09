#!/bin/bash

#################################################################################################################################
################################################## Prerequisites Linux Functions ###################################################
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


function is_gcloud_install(){

}

function is_gcloud_user_login(){

}
