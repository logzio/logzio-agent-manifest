#!/bin/bash

#################################################################################################################################
###################################################### Agent Mac Functions ######################################################
#################################################################################################################################

# Prints usage
# Output:
#   Help usage
function show_help () {
    echo -e "Usage: ./agent.bash --url=<logzio_app_url> --id=<agent_id> [--debug=<app_json>]"
    echo -e " --url=<logzio_app_url>       Logz.io app URL (https://app.logz.io)"
    echo -e " --id=<agent_id>              Logz.io agent ID"
    echo -e " --debug=<app_json>           Debug run using a local application JSON"
    echo -e " --help                       Show usage"
}

# Gets arguments
# Input:
#   Agent script arguments ($@)
# Output:
#   app_url - Logz.io app URL
#   agent_id - Logz.io agent ID
#   app_json_file - App JSON (only in debug)
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
            --url=*)
                app_url=$(echo "$1" | cut -d "=" -f2)
                if [[ "$app_url" = "" ]]; then
                    print_error "agent.bash (2): no Logz.io app URL specified!"
                    delete_temp_dir
                    exit 2
                fi

                write_log "INFO" "url = $app_url"
                ;;
            --id=*)
                agent_id=$(echo "$1" | cut -d "=" -f2)
                if [[ "$agent_id" = "" ]]; then
                    print_error "agent.bash (2): no agent ID specified!"
                    delete_temp_dir
                    exit 2
                fi

                write_log "INFO" "id = $agent_id"
                ;;
            --debug=*)
                app_json_file=$(echo "$1" | cut -d "=" -f2)
                if [[ "$app_json_file" = "" ]]; then
                    print_error "agent.bash (2): no JSON file specified!"
                    delete_temp_dir
                    exit 2
                fi

                write_log "INFO" "debug = $app_json_file"
                break
                ;;
            "")
                break
                ;;
            *)
                print_error "agent.bash (2): unrecognized flag"
                print_error "agent.bash (2): try './agent.bash --help' for more information"
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

    if [[ ! -z "$app_json_file" ]]; then
        if [[ -f "$app_json_file" ]]; then
            return
        fi

        print_error "agent.bash (2): the JSON file $app_json_file does not exist"
        delete_temp_dir
        exit 2
    fi

    local is_error=false

    if [[ -z "$app_url" ]]; then
        is_error=true
        print_error "agent.bash (2): Logz.io app URL must be specified"
    fi
    if [[ -z "$agent_id" ]]; then
        is_error=true
        print_error "agent.bash (2): agent ID must be specified"
    fi

    if $is_error; then
        print_error "agent.bash (2): try './agent.bash --help' for more information"
        delete_temp_dir
        exit 2
    fi
}

# Installs Homebrew
# Error:
#   Exit Code 3
function install_homebrew () {
    write_log "INFO" "Checking if Homebrew is installed ..."
    which brew >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        return
    fi

    write_log "INFO" "Installing Hombrew ..."
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash >/dev/null 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"agent.bash (3): failed to install Homebrew.\n  $err\""
        return 3
    fi
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

    install_homebrew

    write_log "INFO" "Installing jq ..."
    brew install jq >/dev/null 2>$task_error_file
    if [[ $? -eq 0 ]]; then
        return
    fi

    local err=$(cat $task_error_file)
    write_run "print_error \"agent.bash (3): failed to install jq.\n  $err\""
    return 3
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
