#!/bin/bash
#set -e

########################################################## Arguments ############################################################

APP_JSON=$1                             # Application JSON file

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
    if [ "$requested_param" = "" ]; then
        echo "Did not find $requested_name parameter under $product_name in the application json"
        exit 1
    fi
    echo "$requested_param"
}

#################################################################################################################################

################################################## Prerequisites Installations ##################################################

echo "Running prerequisites installations..."

which jq >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Installing JQ..."
    which apt-get >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        sudo apt-get update
        sudo apt-get install -y jq
    else
        which yum >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            sudo yum update
            sudo yum install -y jq
        fi
    fi
else
    echo "JQ is already installed"
fi

#################################################################################################################################

#################################################### Build Path to Manifest ####################################################

echo "Building manifest path..."
dir1=$(jq -r ".name" $APP_JSON)
dir2=$(jq -r ".subtype.name" $APP_JSON)
dir3=$(jq -r ".subtype.datasources[0].name" $APP_JSON)
manifest="https://raw.githubusercontent.com/logzio/logzio-agent-manifest/init/$dir1/$dir2/$dir3"

#################################################################################################################################

########################################################## Get Commands #########################################################

echo "Getting prerequisites commands..."
prerequisites=$(curl -LSs $manifest/prerequisites/linux.json | jq -r ".commands")

echo "Getting installer commands..."
installer=$(curl -LSs $manifest/telemetry/installer/linux.json | jq -r ".commands")

#################################################################################################################################

################################################## Run Prerequisites Commands ###################################################

echo "Running prerequisites commands..."
run_commands "$prerequisites"

#################################################################################################################################

##################################################### Run Installer Commands ####################################################

echo "Running installer commands..."
run_commands "$installer"

#################################################################################################################################
