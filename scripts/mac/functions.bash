#!/bin/bash

#################################################################################################################################
###################################################### Agent Mac Functions ######################################################
#################################################################################################################################

# Prints usage
function show_help () {
    echo "Usage: ./mac.bash --url=<logzio_app_url> --id=<agent_id> [--debug=<app_json>]"
    echo " --url=<logzio_app_url>       Logz.io app URL"
    echo " --id=<agent_id>              Logz.io agent ID"
    echo " --debug=<app_json>           Debug run using a local application JSON"
    echo " --help                       Show usage"
}

# Gets arguments
# Input:
#   Agent script arguments ($@)
# Error:
#   Status Code 1
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
                    echo "agent.bash (1): no Logz.io app URL specified!"
                    exit 1
                fi
                ;;
            --id=*)
                agent_id=$(echo "$1" | cut -d "=" -f2)
                if [ "$agent_id" = "" ]; then
                    echo "agent.bash (1): no agent ID specified!"
                    exit 1
                fi
                ;;
            --debug=*)
                app_json_file=$(echo "$1" | cut -d "=" -f2)
                if [ "$app_json_file" = "" ]; then
                    echo "agent.bash (1): no JSON file specified!"
                    exit 1
                fi
                break
                ;;
            "")
                break
                ;;
            *)
                echo "agent.bash (1): unrecognized flag"
                echo "agent.bash (1): try './mac.bash --help' for more information"
                exit 1
                ;;
        esac
        shift
    done
}

# Checks validation of the arguments
# Error:
#   Status Code 1
function check_validation () {
    if [ ! -z "$app_json_file" ]; then
        return
    fi

    local is_error=false

    if [ -z "$app_url" ]; then
        is_error=true
        echo "agent.bash (1): Logz.io app URL must be specified"
    fi
    if [ -z "$agent_id" ]; then
        is_error=true
        echo "agent.bash (1): agent ID must be specified"
    fi

    if $is_error; then
        echo "agent.bash (1): try './mac.bash --help' for more information"
        exit 1
    fi
}

print_progressbar_status ()
{
    local total_tasks=8
    local percentage=($completed_tasks/$total_tasks)*100
    local progress_squares=($percentage/25)*100/4
    local progress=""

    for i in {1...25}; do
        if [ i -le $progress_squares ]; then
            progress+="#"
            continue
        fi

        progress+=" "
    done

    # Save cursor position
    tput sc

    # Move cursor to last line of the screen
    tput cup $LINES 0;

    echo -n "[$progress] ${percentage%.*}"

    # Move cursor to last saved position
    tput rc
}

# Installs JQ
# Error:
#   Status Code 2
function install_jq () {
    which jq >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "JQ is already installed"
        return
    fi

    which brew >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Installing Homebrew..."
        ruby -e "$(curl -LSs https://raw.githubusercontent.com/Homebrew/install/master/install)"
        if [ $? -ne 0 ]; then
            echo "agent.bash (2): failed to install Homebrew"
            exit 2
        fi
    fi

    echo "Installing JQ..."
    brew update
    brew install jq

    print_progressbar_status
}

# Gets the app JSON from the agent/local file
# Error:
#   Status Code 3
function get_app_json () {
    if [ ! -z "$app_json_file" ]; then
        echo "Using local app JSON file..."
        if [ ! -f "$app_json_file" ]; then
            echo "agent.bash (3): the JSON file $app_json_file does not exist"
            exit 3
        fi

        app_json=$(cat $app_json_file)
        return
    fi

    echo "Getting app JSON from agent..."

    app_json=$(curl -LSs $api_url/telemetry-agent/public/agents/configuration/$agent_id)
    if [ $? -ne 0 ]; then
        echo "agent.bash (3): failed to get Logz.io app JSON from agent"
        exit 3
    fi

    print_progressbar_status
}

# Builds path to logzio-agent-scripts repo according the app JSON
# Error:
#   Status Code 4
function build_repo_path () {
    echo "Building path to logzio-agent-scripts repo..."
    local dir1=$(echo "$APP_JSON" | jq -r ".configuration.name")
    if [ $? -ne 0 ]; then
        echo "agent.bash (4): '.configuration.name' key not found in app JSON"
        exit 4
    fi

    local dir2=$(echo "$APP_JSON" | jq -r ".configuration.subtypes[0].name")
    if [ $? -ne 0 ]; then
        echo "agent.bash (4): '.configuration.subtypes[0].name' key not found in app JSON"
        exit 4
    fi

    local dir3=$(echo "$APP_JSON" | jq -r ".configuration.subtypes[0].datasources[0].name")
    if [ $? -ne 0 ]; then
        echo "agent.bash (4): '.configuration.subtypes[0].datasources[0].name' key not found in app JSON"
        exit 4
    fi

    repo_path="https://raw.githubusercontent.com/logzio/logzio-agent-manifest/v0.2/$dir1/$dir2/$dir3"
    print_progressbar_status
}

# Gets prerequisites script from logzio-agent-scripts repo
# Error:
#   Status Code 5
function get_prerequisite_script () {
    echo "Getting prerequisites script..."
    curl -LSs $repo_path/prerequisites/mac.json >> prerequisites.bash
    if [ $? -ne 0 ]; then
        echo "agent.script (5): failed to get prerequisites script file from logzio-agent-scripts repo"
        exit 5
    fi

    print_progressbar_status
}
