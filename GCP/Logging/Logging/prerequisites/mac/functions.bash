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

# Ping Gcloud
# Output:
# Error:
#   Exit Code 1
function is_gcloud_install(){
    write_log "INFO" "running command gcloud -v ..."

	gcloud_ping=`gcloud -v 2>/dev/null | wc -w`

	if [ $gcloud_ping -gt 0 ]
	then
		return
	else
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed Gcloud CLI is not installed on running machine.\n  $err\""
        return 1	
	fi
}

# Display gcloud account
# Output:
# Error:
#   Exit Code 1
function is_gcloud_user_login(){
    write_log "INFO" "running command gcloud config get-value account ..."

	gcloud_user_active=`gcloud auth login`

	if [[ ! $(gcloud config get-value account &> /dev/null) ]]
	then
		write_run "Logged in to account = ${gcloud_user_active}"
	else
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to get Google Cloud User.\n  $err\""
        return 1	
	fi
}





