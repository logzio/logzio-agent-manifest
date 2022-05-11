#!/bin/bash

#################################################################################################################################
####################################################### Agent Mac Script ########################################################
#################################################################################################################################

# Gets agent functions scripts from logzio-agent-scripts repo to logzio-temp directory
# Error:
#   Exit Code 1
function get_agent_functions_scripts () {
    echo -e "[INFO] Getting agent functions script file from logzio-agent-scripts repo ..." > logzio_agent.log
    curl -fsSL $repo_url/scripts/mac/functions.bash > logzio-temp/agent_functions.bash 2>logzio-temp/task_result
    if [ $? -ne 0 ]; then
        cat logzio-temp/task_result >> logzio_agent.log
        echo -e "[ERROR] agent.script (1): failed to get agnet functions script file from logzio-agent-scripts repo" >> logzio_agent.log

        cat logzio-temp/task_result
        echo -e "\033[0;31magent.script (1): failed to get agnet functions script file from logzio-agent-scripts repo\033[0;37m"
        rm -R logzio-temp
        exit 1
    fi

    echo -e "[INFO] Getting utils functions script file from logzio-agent-scripts repo ..." >> logzio_agent.log
    curl -fsSL $repo_url/scripts/mac/functions.bash > logzio-temp/utils_functions.bash 2>logzio-temp/task_result
    if [ $? -ne 0 ]; then
        cat logzio-temp/task_result >> logzio_agent.log
        echo -e "[ERROR] agent.script (1): failed to get utils functions script file from logzio-agent-scripts repo" >> logzio_agent.log

        cat logzio-temp/task_result
        echo -e "\033[0;31magent.script (1): failed to get utils functions script file from logzio-agent-scripts repo\033[0;37m"
        rm -R logzio-temp
        exit 1
    fi
}


# logzio-agent-scripts repo URL
repo_url="https://raw.githubusercontent.com/logzio/logzio-agent-manifest/v0.2"

# Create temp directory with run file
mkdir -p logzio-temp
touch logzio-temp/run

# Get agent functions scripts
get_agent_functions_scripts

# Load agent functions
echo -e "[INFO] Loading agent functions ..." >> logzio_agent.log
source ./logzio-temp/agent_functions.bash
source ./logzio-temp/utils_functions.bash

# Get arguments and check validation
get_arguments "$@"

# Print title
echo -e "Running \033[0;34mLogz\033[0;33m.io\033[0;37m Agent:\n"

# Run prerequisite installations
echo -e "prerequisite installations:"
execute_task "install_update_homebrew" "installing and updating Homebrew"           # Install and update Homebrew
execute_task "install_jq" "installing jq"                                           # Install jq

# Run last preparations
echo -e "\nlast preparations:"
execute_task "get_app_json" "getting application JSON"                              # Get app JSON
execute_task "build_repo_path" "building path to logzio-agent-scripts repo"         # Build repo path to logzio-agent-scripts repo
execute_task "get_prerequisite_scripts" "getting prerequisites scripts"             # Get prerequisites scripts
execute_task "get_installer_scripts" "getting installer scripts"                    # Get installer scripts

# Run prerequisites script
echo -e "[INFO] Running prerequisites script ..." >> logzio_agent.log
echo -e "\nprerequisites:"
source ./logzio-temp/prerequisites.bash

# Run installer script
echo -e "[INFO] Running installer script ..." >> logzio_agent.log
echo -e "\ninstaller:"
source ./logzio-temp/installer.bash

# Delete temp directory
delete_temp_dir
