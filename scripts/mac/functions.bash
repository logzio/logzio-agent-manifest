#!/bin/bash

#################################################################################################################################
###################################################### Agent Mac Functions ######################################################
#################################################################################################################################

# Prints usage
# Output:
#   Help usage
function show_help () {
    echo "Usage: ./agent.bash --url=<logzio_app_url> --id=<agent_id> [--debug=<app_json>]"
    echo " --url=<logzio_app_url>       Logz.io app URL (https://app.logz.io)"
    echo " --id=<agent_id>              Logz.io agent ID"
    echo " --debug=<app_json>           Debug run using a local application JSON"
    echo " --help                       Show usage"
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
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting arguments ..." >> logzio_agent.log

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

                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] url = $app_url" >> logzio_agent.log
                ;;
            --id=*)
                agent_id=$(echo "$1" | cut -d "=" -f2)
                if [[ "$agent_id" = "" ]]; then
                    print_error "agent.bash (2): no agent ID specified!"
                    delete_temp_dir
                    exit 2
                fi

                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] id = $agent_id" >> logzio_agent.log
                ;;
            --debug=*)
                app_json_file=$(echo "$1" | cut -d "=" -f2)
                if [[ "$app_json_file" = "" ]]; then
                    print_error "agent.bash (2): no JSON file specified!"
                    delete_temp_dir
                    exit 2
                fi

                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] debug = $app_json_file" >> logzio_agent.log
                break
                ;;
            "")
                break
                ;;
            *)
                print_error "agent.bash (2): unrecognized flag"
                print_error "agent.bash (2): try './mac.bash --help' for more information"
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
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Checking validation ..." >> logzio_agent.log

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
        print_error "agent.bash (2): try './mac.bash --help' for more information"
        delete_temp_dir
        exit 2
    fi
}

# Installs and updates Homebrew
# Error:
#   Exit Code 3
function install_update_homebrew () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Checking if Homebrew is installed ..." >> logzio_agent.log
    which brew >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Installing Hombrew ..." >> logzio_agent.log
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash > logzio-temp/task_result 2>&1
        if [[ $? -ne 0 ]]; then
            cat logzio-temp/task_result >> logzio_agent.log

            echo -e "cat logzio-temp/task_result" > logzio-temp/run
            echo -e "print_error \"agent.bash (3): failed to install Homebrew\"" >> logzio-temp/run
            return 3
        fi
    fi

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Updating Hombrew ..." >> logzio_agent.log
    brew update > logzio-temp/task_result 2>&1
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"agent.bash (3): failed to update Homebrew\"" >> logzio-temp/run
        return 3
    fi
}

# Installs jq
# Error:
#   Exit Code 3
function install_jq () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Checking if jq is installed ..." >> logzio_agent.log
    which jq >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        return
    fi

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Installing jq ..." >> logzio_agent.log
    brew install jq > logzio-temp/task_result 2>&1
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"agent.bash (3): failed to install jq\"" >> logzio-temp/run
        return 3
    fi
}

# Gets the application JSON from the agent/local file into logzio-temp directory
# Error:
#   Exit Code 4
function get_app_json () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting application JSON ..." >> logzio_agent.log

    if [[ ! -z "$app_json_file" ]]; then
        # Using local app JSON file
        echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Using local application JSON file ..." >> logzio_agent.log
        cp $app_json_file logzio-temp/app.json
        return
    fi

    # Getting app JSON from agent
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting application JSON from agent ..." >> logzio_agent.log
    curl -fsSL $app_url/telemetry-agent/public/agents/configuration/$agent_id > logzio-temp/app.json 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"agent.bash (4): failed to get Logz.io application JSON from agent. make sure your URL is valid\"" >> logzio-temp/run
        return 4
    fi

    local status_code=$(echo -e "$app_json" | jq -r '.statusCode')
    if [[ "$status_code" != null ]]; then
        echo -e "print_error \"agent.bash (4): failed to get Logz.io application JSON from agent (statusCode $status_code). make sure your ID is valid\"" > logzio-temp/run
        return 4
    fi

    echo -e "$app_json" > logzio-temp/app.json
}

# Builds path to logzio-agent-scripts repo according the app JSON
# Output:
#   repo_path - Path to logzio-agent-scripts repo according the app JSON
# Error:
#   Exit Code 5
function build_repo_path () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Building repo path ..." >> logzio_agent.log
    
    local dir1=$(jq -r '.configuration.name' logzio-temp/app.json)
    if [[ "$dir1" = null ]]; then
        echo -e "print_error \"agent.bash (5): '.configuration.name' was not found in application JSON\"" > logzio-temp/run
        return 5
    fi
    if [[ -z "$dir1" ]]; then
        echo -e "print_error \"agent.bash (5): '.configuration.name' is empty in application JSON\"" > logzio-temp/run
        return 5
    fi

    local dir2=$(jq -r '.configuration.subtypes[0].name' logzio-temp/app.json)
    if [[ "$dir2" = null ]]; then
        echo -e "print_error \"agent.bash (5): '.configuration.subtypes[0].name' was not found in application JSON\"" > logzio-temp/run
        return 5
    fi
    if [[ -z "$dir2" ]]; then
        echo -e "print_error \"agent.bash (5): '.configuration.subtypes[0].name' is empty in application JSON\"" > logzio-temp/run
        return 5
    fi

    local dir3=$(jq -r '.configuration.subtypes[0].datasources[0].name' logzio-temp/app.json)
    if [[ "$dir3" = null ]]; then
        echo -e "print_error \"agent.bash (5): '.configuration.subtypes[0].datasources[0].name' was not found in application JSON\"" > logzio-temp/run
        return 5
    fi
    if [[ -z "$dir3" ]]; then
        echo -e "print_error \"agent.bash (5): '.configuration.subtypes[0].datasources[0].name' is empty in application JSON\"" > logzio-temp/run
        return 5
    fi

    local repo_path="$repo_url/$dir1/$dir2/$dir3"
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] repo_path = $repo_path" >> logzio_agent.log
    echo -e "repo_path=\"$repo_path\"" > logzio-temp/run
}

# Gets prerequisites scripts from logzio-agent-scripts repo to logzio-temp directory
# Error:
#   Exit Code 6
function get_prerequisite_scripts () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting prerequisites script file from logzio-agent-scripts repo ..." >> logzio_agent.log
    curl -fsSL $repo_path/prerequisites/mac/prerequisites.bash > logzio-temp/prerequisites.bash 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"agent.bash (6): failed to get prerequisites script file from logzio-agent-scripts repo\"" >> logzio-temp/run
        return 6
    fi

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting prerequisites functions script file from logzio-agent-scripts repo ..." >> logzio_agent.log
    curl -fsSL $repo_path/prerequisites/mac/functions.bash > logzio-temp/prerequisites_functions.bash 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"agent.bash (6): failed to get prerequisites functions script file from logzio-agent-scripts repo\"" >> logzio-temp/run
        return 6
    fi
}

# Gets installer scripts from logzio-agent-scripts repo to logzio-temp directory
# Error:
#   Exit Code 7
function get_installer_scripts () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting installer script file from logzio-agent-scripts repo ..." >> logzio_agent.log
    curl -fsSL $repo_path/telemetry/installer/mac/installer.bash > logzio-temp/installer.bash 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"agent.bash (7): failed to get installer script file from logzio-agent-scripts repo\"" > logzio-temp/run
        return 7
    fi

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting installer functions script file from logzio-agent-scripts repo ..." >> logzio_agent.log
    curl -fsSL $repo_path/telemetry/installer/mac/functions.bash > logzio-temp/installer_functions.bash 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"agent.bash (7): failed to get installer functions script file from logzio-agent-scripts repo\"" > logzio-temp/run
        return 7
    fi
}
