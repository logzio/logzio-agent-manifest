#!/bin/bash

#################################################################################################################################
###################################################### Agent Linux Functions ####################################################
#################################################################################################################################

# Checks if one of the package managers (apt-get/yum) is installed
# Error:
#   Exit Code 3
function is_package_manager_installed () {
    write_log "INFO" "Checking if apt-get is installed ..."
    which apt-get >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        write_log "INFO" "package_manager = apt-get"
        write_run "package_manager=\"apt-get\""
        return
    fi

    write_log "INFO" "Checking if yum is installed ..."
    which yum >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        write_log "INFO" "package_manager = yum"
        write_run "package_manager=\"yum\""
        return
    fi

    write_run "print_error \"agent.bash (3): did not find apt-get or yum package managers\""
    return 3
}

# Installs jq
# Error:
#   Exit Code 3
function install_jq () {
    write_log "INFO" "Checking if jq is installed ..."
    which jq >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        return
    fi

    write_log "INFO" "Installing jq ..."
    local result=0 

    if [[ "$package_manager" = "apt-get" ]]; then
        sudo apt-get install -y jq >/dev/null 2>$task_error_file
        if [[ $? -eq 0 ]]; then
            echo "success apt-get" >> test.txt
            return
        fi

        local err=$(cat $task_error_file)
        write_run "print_error \"agent.bash (3): failed to install jq.\n  $err\""
        return 3
    fi

    if [[ "$package_manager" = "yum" ]]; then
        sudo yum install -y jq >/dev/null 2>$task_error_file
        if [[ $? -eq 0 ]]; then
            echo "success yum" >> test.txt
            return
        fi

        local err=$(cat $task_error_file)
        write_run "print_error \"agent.bash (3): failed to install jq.\n  $err\""
        return 3
    fi
}

# Gets the application JSON from the agent/local file into logzio-temp directory
# Error:
#   Exit Code 4
function get_app_json () {
    write_log "INFO" "Getting application JSON ..."

    if [[ ! -z "$app_json_file" ]]; then
        # Using local app JSON file
        write_log "INFO" "Using local application JSON file ..."
        cp $app_json_file $app_json
        return
    fi

    # Getting app JSON from agent
    write_log "INFO" "Getting application JSON from agent ..."
    curl -fsSL $app_url/telemetry-agent/public/agents/configuration/$agent_id > $app_json 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"agent.bash (4): failed to get Logz.io application JSON from agent. make sure your URL is valid.\n  $err\""
        return 4
    fi

    local status_code=$(jq -r '.statusCode' $app_json)
    if [[ "$status_code" = null ]]; then
        return
    fi

    write_run "print_error \"agent.bash (4): failed to get Logz.io application JSON from agent (statusCode $status_code). make sure your ID is valid\""
    return 4
}

# Builds path to logzio-agent-manifest repo according the app JSON
# Output:
#   repo_path - Path to logzio-agent-manifest repo according the app JSON
# Error:
#   Exit Code 5
function build_repo_path () {
    write_log "INFO" "Building repo path ..."
    
    local dir1=$(jq -r '.configuration.name' $app_json)
    if [[ "$dir1" = null ]]; then
        write_run "print_error \"agent.bash (5): '.configuration.name' was not found in application JSON\""
        return 5
    fi
    if [[ -z "$dir1" ]]; then
        write_run "print_error \"agent.bash (5): '.configuration.name' is empty in application JSON\""
        return 5
    fi

    local dir2=$(jq -r '.configuration.subtypes[0].name' $app_json)
    if [[ "$dir2" = null ]]; then
        write_run "print_error \"agent.bash (5): '.configuration.subtypes[0].name' was not found in application JSON\""
        return 5
    fi
    if [[ -z "$dir2" ]]; then
        write_run "print_error \"agent.bash (5): '.configuration.subtypes[0].name' is empty in application JSON\""
        return 5
    fi

    local dir3=$(jq -r '.configuration.subtypes[0].datasources[0].name' $app_json)
    if [[ "$dir3" = null ]]; then
        write_run "print_error \"agent.bash (5): '.configuration.subtypes[0].datasources[0].name' was not found in application JSON\""
        return 5
    fi
    if [[ -z "$dir3" ]]; then
        write_run "print_error \"agent.bash (5): '.configuration.subtypes[0].datasources[0].name' is empty in application JSON\""
        return 5
    fi

    local repo_path="$repo_url/$dir1/$dir2/$dir3"
    write_log "INFO" "repo_path = $repo_path"
    write_run "repo_path=\"$repo_path\""
}

# Gets prerequisites scripts from logzio-agent-manifest repo to logzio-temp directory
# Error:
#   Exit Code 6
function get_prerequisites_scripts () {
    write_log "INFO" "Getting prerequisites script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/prerequisites/linux/prerequisites.bash > $logzio_temp_dir/prerequisites.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"agent.bash (6): failed to get prerequisites script file from logzio-agent-manifest repo.\n  $err\""
        return 6
    fi

    write_log "INFO" "Getting prerequisites functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/prerequisites/linux/functions.bash > $logzio_temp_dir/prerequisites_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"agent.bash (6): failed to get prerequisites functions script file from logzio-agent-manifest repo.\n  $err\""
        return 6
    fi
}

# Gets installer scripts from logzio-agent-manifest repo to logzio-temp directory
# Error:
#   Exit Code 7
function get_installer_scripts () {
    write_log "INFO" "Getting installer script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/installer/linux/installer.bash > $logzio_temp_dir/installer.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"agent.bash (7): failed to get installer script file from logzio-agent-manifest repo.\n  $err\""
        return 7
    fi

    write_log "INFO" "Getting installer functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/installer/linux/functions.bash > $logzio_temp_dir/installer_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"agent.bash (7): failed to get installer functions script file from logzio-agent-manifest repo.\n  $err\""
        return 7
    fi
}
