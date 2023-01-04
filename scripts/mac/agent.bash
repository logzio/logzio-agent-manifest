#!/bin/bash

#################################################################################################################################
####################################################### Agent Mac Script ########################################################
#################################################################################################################################

# Prints usage
# Output:
#   Help usage
function show_help () {
    echo -e "Usage: ./agent.bash --url=<logzio_app_url> --id=<agent_id> [--debug=<app_json>] [--branch<repo_branch>]"
    echo -e " --url=<logzio_app_url>       Logz.io app URL (https://app.logz.io)"
    echo -e " --id=<agent_id>              Logz.io agent ID"
    echo -e " --debug=<app_json>           Debug run using a local application JSON"
    echo -e " --branch=<repo_branch>       The branch of Logz.io repo. Default is master"
    echo -e " --help                       Show usage"
}

# Gets arguments
# Input:
#   Agent script arguments ($@)
# Output:
#   app_url - Logz.io app URL
#   agent_id - Logz.io agent ID
#   app_json_file - App JSON (only in debug)
#   repo_branch - Repo branch (for tests)
# Error:
#   Exit Code 1
function get_arguments () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting arguments ..." >> $log_file

    while true; do
        case "$1" in
            --help)
                show_help
                exit
                ;;
            --url=*)
                app_url=$(echo "$1" | cut -d "=" -f2)
                if [[ "$app_url" = "" ]]; then
                    echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] agent.bash (1): no Logz.io app URL specified!" >> $log_file
                    echo -e "\033[0;31magent.bash (1): no Logz.io app URL specified!\033[0;37m"
                    exit 1
                fi

                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] url = $app_url" >> $log_file
                ;;
            --id=*)
                agent_id=$(echo "$1" | cut -d "=" -f2)
                if [[ "$agent_id" = "" ]]; then
                    echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] agent.bash (1): no agent ID specified!" >> $log_file
                    echo -e "\033[0;31magent.bash (1): no agent ID specified!\033[0;37m"
                    exit 1
                fi

                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] id = $agent_id" >> $log_file
                ;;
            --debug=*)
                app_json_file=$(echo "$1" | cut -d "=" -f2)
                if [[ "$app_json_file" = "" ]]; then
                    echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] agent.bash (1): no JSON file specified!" >> $log_file
                    echo -e "\033[0;31magent.bash (1): no JSON file specified!\033[0;37m"
                    exit 1
                fi

                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] debug = $app_json_file" >> $log_file
                ;;
            --branch=*)
                repo_branch=$(echo "$1" | cut -d "=" -f2)
                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] branch = $repo_branch" >> $log_file
                ;;
            "")
                break
                ;;
            *)
                echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] agent.bash (1): unrecognized flag" >> $log_file
                echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] agent.bash (1): try './agent.bash --help' for more information" >> $log_file
                echo -e "\033[0;31magent.bash (1): unrecognized flag\033[0;37m"
                echo -e "\033[0;31magent.bash (1): agent.bash (1): try './agent.bash --help' for more information\033[0;37m"
                exit 1
                ;;
        esac
        shift
    done

    check_validation
}

# Checks validation of the arguments
# Error:
#   Exit Code 1
function check_validation () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Checking validation ..." >> $log_file

    if [[ ! -z "$app_json_file" ]]; then
        if [[ -f "$app_json_file" ]]; then
            return
        fi

        echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] agent.bash (1): the JSON file $app_json_file does not exist" >> $log_file
        echo -e "\033[0;31magent.bash (1): the JSON file $app_json_file does not exist\033[0;37m"
        exit 1
    fi

    local is_error=false

    if [[ -z "$app_url" ]]; then
        is_error=true
        echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] agent.bash (1): Logz.io app URL must be specified" >> $log_file
        echo -e "\033[0;31magent.bash (1): Logz.io app URL must be specified\033[0;37m"
    fi
    if [[ -z "$agent_id" ]]; then
        is_error=true
        echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] agent.bash (1): agent ID must be specified" >> $log_file
        echo -e "\033[0;31magent.bash (1): agent ID must be specified\033[0;37m"
    fi

    if $is_error; then
        echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] agent.bash (1): try './agent.bash --help' for more information" >> $log_file
        echo -e "\033[0;31magent.bash (1): try './agent.bash --help' for more information\033[0;37m"
        exit 1
    fi
}

# Gets agent functions scripts from logzio-agent-manifest repo to logzio-temp directory
# Error:
#   Exit Code 2
function get_agent_functions_scripts () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting agent functions script file from logzio-agent-manifest repo ..." >> $log_file
    curl -fsSL $repo_url/scripts/mac/functions.bash > $logzio_temp_dir/agent_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] agent.bash (2): failed to get agnet functions script file from logzio-agent-manifest repo.\n  $err" >> $log_file
        echo -e "\033[0;31magent.bash (2): failed to get agnet functions script file from logzio-agent-manifest repo.\n  $err\033[0;37m"
        rm -R logzio-temp
        exit 2
    fi

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting utils functions script file from logzio-agent-manifest repo ..." >> $log_file
    curl -fsSL $repo_url/scripts/mac/utils_functions.bash > $logzio_temp_dir/utils_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] agent.bash (2): failed to get utils functions script file from logzio-agent-manifest repo.\n  $err" >> $log_file
        echo -e "\033[0;31magent.bash (2): failed to get utils functions script file from logzio-agent-manifest repo.\n  $err\033[0;37m"
        rm -R logzio-temp
        exit 2
    fi
}

function get_logo_theme () {
    curl -fsSL $repo_url/scripts/mac/logo-themes/christmas.bash > $logzio_temp_dir/christmas.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        echo -e "\033[0;36mLogz.io Agent\033[0;37m"
    fi
}


# Consts
logzio_temp_dir="./logzio-temp"                                                                 # Logz.io temp directory
log_file="./logzio_agent.log"                                                                   # Log file path
run_file="$logzio_temp_dir/run"                                                                 # Run file path
task_error_file="$logzio_temp_dir/task_error"                                                   # Task error file path
app_json="$logzio_temp_dir/app.json"                                                            # App JSON path

# Get arguments and check validation
get_arguments "$@"

# Set default repo branch
if [[ -z "$repo_branch" ]]; then
    repo_branch="master"
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] branch = master (default)" >> $log_file
fi

# Consts
repo_url="https://raw.githubusercontent.com/logzio/logzio-agent-manifest/$repo_branch"          # logzio-agent-manifest repo URL

# Create temp directory with files
mkdir -p $logzio_temp_dir
touch $run_file
touch $task_error_file

# Get agent functions scripts
get_agent_functions_scripts

# Load agent functions
echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Loading agent functions ..." >> $log_file
source ./logzio-temp/agent_functions.bash
source ./logzio-temp/utils_functions.bash

# Get logo theme script
get_logo_theme

# Print main title
source ./logzio-temp/christmas.bash

# Run prerequisite installations
echo -e "prerequisite installations:"
execute_task "install_jq" "installing jq"                                                       # Install jq

# Run last preparations
echo -e "\nlast preparations:"
execute_task "get_app_json" "getting application JSON"                                          # Get app JSON
execute_task "build_repo_path" "building path to logzio-agent-manifest repo"                    # Build repo path to logzio-agent-manifest repo
execute_task "get_prerequisites_scripts" "getting prerequisites scripts"                        # Get prerequisites scripts
execute_task "get_installer_scripts" "getting installer scripts"                                # Get installer scripts

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
