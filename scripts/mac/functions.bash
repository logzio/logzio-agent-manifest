#!/bin/bash

#################################################################################################################################
########################################################### Functions ###########################################################
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
}

# Gets the app JSON from the agent/local file
# Error:
#   Status Code 3
function get_app_json () {
    if [ ! -z "$app_json_file" ]; then
        echo "Using local app JSON file..."
        echo $app_json_file
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
}
