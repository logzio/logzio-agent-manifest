#!/bin/bash

#################################################################################################################################
###################################################### Agent Mac Functions ######################################################
#################################################################################################################################

# Installs jq
#   Output:
#   jq_bin - The jq binary file path 
# Error:
#   Exit Code 3
function install_jq () {
    write_log "INFO" "Installing jq ..."

    jq_bin="$logzio_temp_dir/jq"
    curl -fsSL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64 > $jq_bin 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"agent.bash (3): failed to get jq binary file from Github.\n  $err\""
        return 3
    fi

    chmod +x $jq_bin
    write_run "jq_bin=\"$jq_bin\""
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

    local status_code=$($jq_bin -r '.statusCode' $app_json)
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
    
    local dir1=$($jq_bin -r '.configuration.name' $app_json)
    if [[ "$dir1" = null ]]; then
        write_run "print_error \"agent.bash (5): '.configuration.name' was not found in application JSON\""
        return 5
    fi
    if [[ -z "$dir1" ]]; then
        write_run "print_error \"agent.bash (5): '.configuration.name' is empty in application JSON\""
        return 5
    fi

    local dir2=$($jq_bin -r '.configuration.subtypes[0].name' $app_json)
    if [[ "$dir2" = null ]]; then
        write_run "print_error \"agent.bash (5): '.configuration.subtypes[0].name' was not found in application JSON\""
        return 5
    fi
    if [[ -z "$dir2" ]]; then
        write_run "print_error \"agent.bash (5): '.configuration.subtypes[0].name' is empty in application JSON\""
        return 5
    fi

    local dir3=$($jq_bin -r '.configuration.subtypes[0].datasources[0].name' $app_json)
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
    curl -fsSL $repo_path/prerequisites/mac/prerequisites.bash > $logzio_temp_dir/prerequisites.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"agent.bash (6): failed to get prerequisites script file from logzio-agent-manifest repo.\n  $err\""
        return 6
    fi

    write_log "INFO" "Getting prerequisites functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/prerequisites/mac/functions.bash > $logzio_temp_dir/prerequisites_functions.bash 2>$task_error_file
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
    curl -fsSL $repo_path/telemetry/installer/mac/installer.bash > $logzio_temp_dir/installer.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"agent.bash (7): failed to get installer script file from logzio-agent-manifest repo.\n  $err\""
        return 7
    fi

    write_log "INFO" "Getting installer functions script file from logzio-agent-manifest repo ..."
    curl -fsSL $repo_path/telemetry/installer/mac/functions.bash > $logzio_temp_dir/installer_functions.bash 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"agent.bash (7): failed to get installer functions script file from logzio-agent-manifest repo.\n  $err\""
        return 7
    fi
}
