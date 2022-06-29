#!/bin/bash

#################################################################################################################################
#################################### Run Prerequisites Linux Script (Troubleshooting Tool) ######################################
#################################################################################################################################

# Gets utils functions script from logzio-agent-manifest repo to logzio-temp directory
# Error:
#   Exit Code 1
function get_utils_functions_script () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting utils functions script file from logzio-agent-manifest repo ..." >> $log_file
    curl -fsSL $repo_url/scripts/linux/utils_functions.bash > $logzio_temp_dir/utils_functions.bash 2>$task_error_file
    if [[ $? -eq 0 ]]; then
        return
    fi

    local err=$(cat $task_error_file)
    echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] run_prerequisites.bash (1): failed to get utils functions script file from logzio-agent-manifest repo.\n  $err" >> $log_file
    echo -e "\033[0;31mrun_prerequisites.bash (1): failed to get utils functions script file from logzio-agent-manifest repo.\n  $err\033[0;37m"
    rm -R logzio-temp
    exit 1
}

# Prints usage
# Output:
#   Help usage
function show_help () {
    echo "Usage: ./run_prerequisites.bash --path=<logzio_repo_datasource_path>"
    echo " --path=<logzio_repo_datasource_path>     logzio-agent-manifest repo datasource path (dir1/dir2/dir3)"
    echo " --help                                   Show usage"
}

# Gets arguments
# Input:
#   Run prerequisites script arguments ($@)
# Output:
#   repo_datasource_path - logzio-agent-manifest datasource path (dir1/dir2/dir3)
# Error:
#   Exit Code 2
function get_arguments () {
    write_log "INFO" "Getting arguments ..."

    while true; do
        case "$1" in
            --help)
                show_help
                delete_temp_dir
                exit
                ;;
            --path=*)
                repo_datasource_path=$(echo "$1" | cut -d "=" -f2)
                if [[ "$repo_datasource_path" = "" ]]; then
                    print_error "run_prerequisites.bash (2): no logzio-agent-manifest repo datasource path specified!"
                    delete_temp_dir
                    exit 2
                fi

                write_log "INFO" "path = $repo_datasource_path"
                ;;
            "")
                break
                ;;
            *)
                print_error "run_prerequisites.bash (2): unrecognized flag"
                print_error "run_prerequisites.bash (2): try './run_prerequisites.bash --help' for more information"
                delete_temp_dir
                exit 2
                ;;
        esac
        shift
    done

    check_validation
}

# Checks validation of the arguments
# Error:
#   Exit Code 2
function check_validation () {
    write_log "INFO" "Checking validation ..."

    if [[ -z "$repo_datasource_path" ]]; then
        print_error "run_prerequisites.bash (2): logzio-agent-manifest repo datasource path must be specified"
        print_error "run_prerequisites.bash (2): try './run_prerequisites.bash --help' for more information"
        delete_temp_dir
        exit 2
    fi
    if [[ "$repo_datasource_path" = *"/"*"/"* ]]; then
        return
    fi

    print_error "run_prerequisites.bash (2): logzio-agent-manifest repo datasource path's format must be 'dir1/dir2/dir3'"
    print_error "run_prerequisites.bash (2): try './run_prerequisites.bash --help' for more information"
    delete_temp_dir
    exit 2
}

# Builds path to logzio-agent-manifest repo according the app JSON
# Output:
#   repo_path - Path to logzio-agent-manifest repo using repo_datasource_path
function build_repo_path () {
    write_log "INFO" "Building repo path ..."
    
    local dir1=$(echo -e "$repo_datasource_path" | cut -d "/" -f1)
    local dir2=$(echo -e "$repo_datasource_path" | cut -d "/" -f2)
    local dir3=$(echo -e "$repo_datasource_path" | cut -d "/" -f3)
    local repo_path="$repo_url/$dir1/$dir2/$dir3"

    write_log "INFO" "repo_path = $repo_path"
    write_run "repo_path=\"$repo_path\""
}

# Gets prerequisites scripts from logzio-agent-manifest repo to logzio-temp directory
# Error:
#   Exit Code 3
function get_prerequisites_scripts () {
    write_log "INFO" "Getting prerequisites script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/prerequisites/linux/prerequisites.bash > $logzio_temp_dir/prerequisites.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"run_prerequisites.bash (3): failed to get prerequisites script file from logzio-agent-manifest repo.\n  $err\""
        return 3
    fi

    write_log "INFO" "Getting prerequisites functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/prerequisites/linux/functions.bash > $logzio_temp_dir/prerequisites_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"run_prerequisites.bash (3): failed to get prerequisites functions script file from logzio-agent-manifest repo.\n  $err\""
        return 3
    fi
}

# Consts
repo_url="https://raw.githubusercontent.com/logzio/logzio-agent-manifest/v0.2"      # logzio-agent-manifest repo URL
logzio_temp_dir="./logzio-temp"                                                     # Logz.io temp directory
log_file="./logzio_agent_troubleshooting.log"                                       # Log file path
run_file="$logzio_temp_dir/run"                                                     # Run file path
task_error_file="$logzio_temp_dir/task_error"                                       # Task error file path

# Create temp directory with files
mkdir -p $logzio_temp_dir
touch $run_file
touch $task_error_file

# Get utils functions script
get_utils_functions_script

# Load utils functions
echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Loading utils functions ..." >> $log_file
source $logzio_temp_dir/utils_functions.bash

# Get arguments and check validation
get_arguments "$@"

# Print title
echo -e "Running \033[0;36mLogz.io\033[0;37m Agent Troubleshooting Tool:\n"

# Run last preparations
echo -e "last preparations:"
execute_task "build_repo_path" "building path to logzio-agent-manifest repo"        # Build repo path to logzio-agent-manifest repo
execute_task "get_prerequisites_scripts" "getting prerequisites scripts"            # Get prerequisites scripts

# Run prerequisites script
write_log "INFO" "Running prerequisites script ..."
echo -e "\nprerequisites:"
source $logzio_temp_dir/prerequisites.bash

# Delete temp directory
delete_temp_dir

# Print success message
echo
print_info "##### Logz.io agent troubleshooting tool was finished successfully #####"
