#!/bin/bash

######################################################## Helper Functions #######################################################

# Prints usage
function show_help () {
    echo "Usage: ./mac.bash --url <logzio_api_url> --id <agent_id> [--debug <app_json>]"
    echo " --url <logzio_api_url>       Logz.io API URL"
    echo " --id <agent_id>              Logz.io agent ID"
    echo " --debug <app_json>           Debug run using a local application JSON"
    echo " --help                       Show usage"
}

# Runs commands
# Inputs:
# commands - The commands to run
function run_commands () {
    commands="$1"
    while read -r command; do
        full_command=""
        while read -r line; do
            full_command+=" $line"
        done < <(echo "$command" | jq -r ".[]")
        eval "$full_command"
    done < <(echo "$commands" | jq -c ".[].run")
}

# Finds the requested parameter of a product in the application json 
# Inputs: 
# product_name - The product name (logs/metrics/traces/datasources)
# product_params - The product parameters in the application json
# requested_name - The parameter name to find
# Output:
# If the requested parameter was found, returns the parameter object with the requested_name,
# otherwise exits with error
function find_param () {
    product_name="$1"
    product_params="$2"
    requested_name="$3"
    requested_param=""
    while read -r param; do
        name=$(echo "$param" | jq -r ".name")
        if [ "$name" = "$requested_name" ]; then
            requested_param="$param"
        fi
    done < <(echo "$product_params" | jq -c ".[]")
    echo "$requested_param"
}

#################################################################################################################################

######################################################## Get Arguments ##########################################################

while true; do
    case "$1" in
        --help)
            show_help
            exit
            ;;
        --url)
            shift
            if [ "$1" = "" ]; then
                echo "No Logz.io API URL specified!"
                exit 1
            fi
            API_URL="$1"
            ;;
        --id)
            shift
            if [ "$1" = "" ]; then
                echo "No agent ID specified!"
                exit 1
            fi
            AGENT_ID="$1"
            ;;
        --debug)
            shift
            if [ "$1" = "" ]; then
                echo "No JSON file specified!"
                exit 1
            fi
            APP_JSON_FILE="$1"
            break
            ;;
        --test)
            shift
            if [ "$1" = "" ]; then
                echo "No command number specified!"
                exit 1
            fi
            SECTION_NUM="$1"
            break
            ;;
        "")
            break
            ;;
        *)
            echo "Unrecognized flag"
            echo "Try './mac.bash --help' for more information"
            exit 1
            ;;
    esac
    shift
done

if [ "$APP_JSON_FILE" = "" ]; then
    if [ "$API_URL" = "" ]; then
        echo "Logz.io API URL must be specified"
        echo "Try './mac.bash --help' for more information"
        exit 1
    fi
    if [ "$AGENT_ID" = "" ]; then
        echo "Agent ID must be specified"
        echo "Try './mac.bash --help' for more information"
        exit 1
    fi
fi

#################################################################################################################################

################################################## Prerequisites Installations ##################################################

echo "Running prerequisites installations..."

which jq >/dev/null 2>&1
if [ $? -ne 0 ]; then
    which brew >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Installing Homebrew..."
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    echo "Installing JQ..."
    brew update
    brew install jq
else
    echo "JQ is already installed"
fi

#################################################################################################################################

########################################################## Get App JSON #########################################################

if [ "$APP_JSON_FILE" = "" ]; then
    echo "Getting app JSON from agent..."
    APP_JSON=$(curl -LSs $API_URL/telemetry-agent/public/agents/configuration/$AGENT_ID)
else
    echo "Using given app JSON..."
    APP_JSON=$(cat $APP_JSON_FILE)
fi

#################################################################################################################################

##################################################### Build Path to Manifest ####################################################

echo "Building manifest path..."
dir1=$(echo "$APP_JSON" | jq -r ".configuration.name")
dir2=$(echo "$APP_JSON" | jq -r ".configuration.subtypes[0].name")
dir3=$(echo "$APP_JSON" | jq -r ".configuration.subtypes[0].datasources[0].name")
manifest="https://raw.githubusercontent.com/logzio/logzio-agent-manifest/init/$dir1/$dir2/$dir3"

#################################################################################################################################

########################################################## Get Commands #########################################################

echo "Getting prerequisites commands..."
prerequisites=$(curl -LSs $manifest/prerequisites/mac.json | jq -r ".commands")

echo "Getting installer commands..."
installer=$(curl -LSs $manifest/telemetry/installer/mac.json | jq -r ".commands")

#################################################################################################################################

################################################## Run Prerequisites Commands ###################################################

echo "Running prerequisites commands..."
run_commands "$prerequisites"

#################################################################################################################################

##################################################### Run Installer Commands ####################################################

set -e

echo "Running installer commands..."
run_commands "$installer"

#################################################################################################################################
