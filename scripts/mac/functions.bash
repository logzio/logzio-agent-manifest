#!/bin/bash

#################################################################################################################################
###################################################### Agent Mac Functions ######################################################
#################################################################################################################################

# Prints usage
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
# Error:
#   Exit Code 1
function get_arguments () {
    while true; do
        case "$1" in
            --help)
                show_help
                exit
                ;;
            --url=*)
                app_url=$(echo "$1" | cut -d "=" -f2)
                if [ "$app_url" = "" ]; then
                    print_error "agent.bash (1): no Logz.io app URL specified!"
                    exit 1
                fi
                ;;
            --id=*)
                agent_id=$(echo "$1" | cut -d "=" -f2)
                if [ "$agent_id" = "" ]; then
                    print_error "agent.bash (1): no agent ID specified!"
                    exit 1
                fi
                ;;
            --debug=*)
                app_json_file=$(echo "$1" | cut -d "=" -f2)
                if [ "$app_json_file" = "" ]; then
                    print_error "agent.bash (1): no JSON file specified!"
                    exit 1
                fi
                break
                ;;
            "")
                break
                ;;
            *)
                print_error "agent.bash (1): unrecognized flag"
                print_error "agent.bash (1): try './mac.bash --help' for more information"
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
    if [ ! -z "$app_json_file" ]; then
        return
    fi

    local is_error=false

    if [ -z "$app_url" ]; then
        is_error=true
        print_error "agent.bash (1): Logz.io app URL must be specified"
    fi
    if [ -z "$agent_id" ]; then
        is_error=true
        print_error "agent.bash (1): agent ID must be specified"
    fi

    if $is_error; then
        print_error "agent.bash (1): try './mac.bash --help' for more information"
        exit 1
    fi
}

# Installs Homebrew
# Error
#   Exit Code 2
function install_homebrew () {
    which brew >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash > logzio-temp/task_result 2>&1
        if [ $? -ne 0 ]; then
            local result=$(cat logzio-temp/task_result)
            echo -e "echo -e \"$result\""  > logzio-temp/run_post_task
            echo -e "print_error \"agent.bash (2): failed to install Homebrew\"" >> logzio-temp/run_post_task
            exit 2
        fi
    fi
}

# Installs JQ
function install_jq () {
    which jq >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        return
    fi

    brew update
    brew install jq
}

# Gets the app JSON from the agent/local file into logzio-temp directory
# Error:
#   Exit Code 3
function get_app_json () {
    if [ ! -z "$app_json_file" ]; then
        # Using local app JSON file
        if [ ! -f "$app_json_file" ]; then
            echo -e "print_error \"agent.bash (3): the JSON file $app_json_file does not exist\"" > logzio-temp/run_post_task
            exit 3
        fi

        cp $app_json_file logzio-temp/app.json
        return
    fi

    # Getting app JSON from agent
    curl -fsSL $app_url/telemetry-agent/public/agents/configuration/$agent_id > logzio-temp/app.json 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "print_error \"agent.bash (3): failed to get Logz.io app JSON from agent. make sure your url is valid\"" > logzio-temp/run_post_task
        exit 3
    fi

    local status_code=$(echo "$app_json" | jq -r 'select(.statusCode != null) | .statusCode')
    if [ ! -z "$status_code" ] ; then
        echo -e "print_error \"agent.bash (3): failed to get Logz.io app JSON from agent (statusCode $status_code). make sure your id is valid\"" > logzio-temp/run_post_task
        exit 3
    fi

    echo -e "$app_json" > logzio-temp/app.json
}

# Builds path to logzio-agent-scripts repo according the app JSON
# Error:
#   Exit Code 4
function build_repo_path () {
    #echo "Building path to logzio-agent-scripts repo..."
    local dir1=$(jq -r '.configuration.name' logzio-temp/app.json)
    if [ $? -ne 0 ]; then
        echo -e "print_error \"agent.bash (4): '.configuration.name' key not found in app JSON\"" > logzio-temp/run_post_task
        exit 4
    fi

    local dir2=$(jq -r '.configuration.subtypes[0].name' logzio-temp/app.json)
    if [ $? -ne 0 ]; then
        echo -r "print_error \"agent.bash (4): '.configuration.subtypes[0].name' key not found in app JSON\"" > logzio-temp/run_post_task
        exit 4
    fi

    local dir3=$(jq -r '.configuration.subtypes[0].datasources[0].name' logzio-temp/app.json)
    if [ $? -ne 0 ]; then
        echo -e "print_error \"agent.bash (4): '.configuration.subtypes[0].datasources[0].name' key not found in app JSON\"" > logzio-temp/run_post_task
        exit 4
    fi

    echo -e "repo_path=\"https://raw.githubusercontent.com/logzio/logzio-agent-manifest/v0.2/$dir1/$dir2/$dir3\"" > logzio-temp/run_post_task
}

# Gets prerequisites script from logzio-agent-scripts repo
# Error:
#   Exit Code 5
function get_prerequisite_scripts () {
    curl -LSs $repo_path/prerequisites/mac/prerequisites.bash > logzio-temp/prerequisites.bash
    if [ $? -ne 0 ]; then
        echo -e "print_error \"agent.script (5): failed to get prerequisites script file from logzio-agent-scripts repo\"" > logzio-temp/run_post_task
        exit 5
    fi

    curl -LSs $repo_path/prerequisites/mac/functions.bash > logzio-temp/prerequisites_functions.bash
    if [ $? -ne 0 ]; then
        echo -e "print_error \"agent.script (5): failed to get prerequisites script file from logzio-agent-scripts repo\"" > logzio-temp/run_post_task
        exit 5
    fi
}
