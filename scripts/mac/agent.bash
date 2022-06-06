#!/bin/bash

#################################################################################################################################
####################################################### Agent Mac Script ########################################################
#################################################################################################################################

# Gets agent functions scripts from logzio-agent-manifest repo to logzio-temp directory
# Error:
#   Exit Code 1
function get_agent_functions_scripts () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting agent functions script file from logzio-agent-manifest repo ..." >> $log_file
    curl -fsSL $repo_url/scripts/mac/functions.bash > $logzio_temp_dir/agent_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] agent.bash (1): failed to get agnet functions script file from logzio-agent-manifest repo.\n  $err" >> $log_file
        echo -e "\033[0;31magent.bash (1): failed to get agnet functions script file from logzio-agent-manifest repo.\n  $err\033[0;37m"
        rm -R logzio-temp
        exit 1
    fi

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting utils functions script file from logzio-agent-manifest repo ..." >> $log_file
    curl -fsSL $repo_url/scripts/mac/utils_functions.bash > $logzio_temp_dir/utils_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] agent.bash (1): failed to get utils functions script file from logzio-agent-manifest repo.\n  $err" >> $log_file
        echo -e "\033[0;31magent.bash (1): failed to get utils functions script file from logzio-agent-manifest repo.\n  $err\033[0;37m"
        rm -R logzio-temp
        exit 1
    fi
}

# Consts
repo_url="https://raw.githubusercontent.com/logzio/logzio-agent-manifest/v0.2"      # logzio-agent-manifest repo URL
logzio_temp_dir = "./logzio-temp"                                                   # Logz.io temp directory
log_file = "./logzio_agent.log"                                                     # Log file path
run_file = "$logzio_temp_dir/run"                                                   # Run file path
task_error_file = "$logzio_temp_dir/task_error"                                     # Task error file path
app_json = "$logzio_temp_dir/app.json"                                              # App JSON path

# Create temp directory with files
mkdir -p $logzio_temp_dir
touch $run_file
touch $task_error_file

# Get agent functions scripts
get_agent_functions_scripts

# Load agent functions
echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Loading agent functions ..." >> logzio_agent.log
source ./logzio-temp/agent_functions.bash
source ./logzio-temp/utils_functions.bash

# Get arguments and check validation
get_arguments "$@"

# Print title
echo -e "Running \033[0;36mLogz\033[0;33m.io\033[0;37m Agent:\n"

# Run prerequisite installations
echo -e "prerequisite installations:"
execute_task "install_jq" "installing jq"                                           # Install jq

# Run last preparations
echo -e "\nlast preparations:"
execute_task "get_app_json" "getting application JSON"                              # Get app JSON
execute_task "build_repo_path" "building path to logzio-agent-manifest repo"        # Build repo path to logzio-agent-manifest repo
execute_task "get_prerequisites_scripts" "getting prerequisites scripts"            # Get prerequisites scripts
execute_task "get_installer_scripts" "getting installer scripts"                    # Get installer scripts

# Run prerequisites script
write_log "INFO" "Running prerequisites script ..."
echo -e "\nprerequisites:"
source $logzio_temp_dir/prerequisites.bash

# Run installer script
write_log "INFO" "Running installer script ..."
echo -e "\ninstaller:"
source $logzio_temp_dir/installer.bash

# Delete temp directory
delete_temp_dir
