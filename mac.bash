#!/bin/bash

########################################################## Arguments ############################################################

AGENT_ID=$1                             # Agent ID
APP_JSON_FILE=$2                        # App JSON file (for tests)

#################################################################################################################################

######################################################## Helper Functions #######################################################

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

if [ $# -eq 1 ]; then
    echo "Getting app JSON from agent..."
    APP_JSON=$(curl -LSs https://app-ca.logz.io/telemetry-agent/public/agents/configuration/$AGENT_ID)
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
prerequisites=$(curl -LSs -H "Cache-Control: no-cache, no-store" $manifest/prerequisites/mac.json | jq -r ".commands")

echo "Getting installer commands..."
installer=$(curl -LSs -H "Cache-Control: no-cache, no-store" $manifest/telemetry/installer/mac.json | jq -r ".commands")

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
