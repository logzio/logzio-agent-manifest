#!/bin/bash

################################################## Prerequisites Installations ##################################################

which jq >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Installing JQ..."
    brew install jq
else
    echo "JQ is already installed"
fi

#################################################################################################################################

########################################################## Arguments ############################################################

appJson=$1                             # Application JSON file

#################################################################################################################################

#################################################### Build Paths to Manifest ####################################################

dir1=$(jq -r ".name" $appJson)
dir2=$(jq -r ".subtype.name" $appJson)
dir3=$(jq -r ".subtype.datasources[0].name" $appJson)

manifest="https://raw.githubusercontent.com/logzio/logzio-agent-manifest/init/$dir1/$dir2/$dir3"
prerequisites=$(curl -LSs $manifest/prerequisites/mac.json | jq -r ".commands")
installer=$(curl -LSs \"$manifest/telemetry/installer/mac.json\" | jq -r ".commands")

#################################################################################################################################

################################################## Run Prerequisites Commands ###################################################

while read -r command; do
    fullCommand=""
    while read -r line; do
        fullCommand+=" $line"
    done < <(echo $command | jq -r ".[]")
    eval $fullCommand
done < <(echo $prerequisites | jq -c ".[].run")

#################################################################################################################################

##################################################### Run Installer Commands ####################################################

while read -r command; do
    fullCommand=""
    while read -r line; do
        fullCommand+=" $line"
    done < <(echo $command | jq -r ".[]")
    eval $fullCommand
done < <(echo $installer | jq -c ".[].run")

#################################################################################################################################
