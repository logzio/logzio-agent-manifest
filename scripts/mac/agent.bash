#!/bin/bash

#################################################################################################################################
####################################################### Agent Mac Script ########################################################
#################################################################################################################################

# Create temp directory
mkdir -p logzio-temp
touch logzio-temp/run_post_task

# Get functions scripts and load functions
source ./functions.bash
source ./utils_functions.bash
#curl -LSs https://raw.githubusercontent.com/logzio/logzio-agent-manifest/v0.2/scripts/mac/functions.bash > logzio-temp/agent_functions.bash
#curl -LSs https://raw.githubusercontent.com/logzio/logzio-agent-manifest/v0.2/scripts/mac/utils_functions.bash > logzio-temp/utils_functions.bash
#source ./utils_functions.bash

# Get arguments and check validation
get_arguments "$@"

# Print title
echo -e "Running $(tput setaf 4)Logz$(tput setaf 3).io$(tput setaf 7) Agent\n"

# Run prerequisite installations
echo -e "prerequisite installations:"
execute_task "install_homebrew" "installing homebrew"
execute_task "install_jq" "installing jq"
echo -e ""

# Get app JSON
execute_task "get_app_json" "getting app JSON"

# Build path to logzio-agent-scripts repo
execute_task "build_repo_path" "building path to logzio-agent-scripts repo"

# Get prerequisite scripts from logzio-agent-scripts repo
execute_task "get_prerequisite_scripts" "getting prerequisites scripts"

# Get installer scripts from logzio-agent-scripts repo


# Run prerequisites script
echo -e "\nprerequisites:"
source ./logzio-temp/prerequisites.bash

#echo -e "\n"
#read -p "Press anything to continue..."

# Delete 'logzio-temp' directory
#execute_task "delete_temp_dir" "delete temp dir"
