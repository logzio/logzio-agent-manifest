#!/bin/bash

#################################################################################################################################
################################################## Prerequisites Linux Functions ###################################################
#################################################################################################################################

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
