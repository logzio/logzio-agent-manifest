#!/bin/bash

################################################## Prerequisites Installations ##################################################

which jq
if [ $? -ne 0 ]; then
    brew install jq
fi

#################################################################################################################################

########################################################## Arguments ############################################################

app_json=$1                             # Application JSON file

#################################################################################################################################

#################################################### Build Paths to Manifest ####################################################

dir1=$(jq -r ".name $app_json")
dir2=$(jq -r ".subtype.name $app_json")
dir3=$(jq -r ".subtype.datasources[0].name $app_json")

manifest="https://raw.githubusercontent.com/logzio/logzio-agent-manifest/init/$dir1/$dir2/$dir3"
prerequisites=$(curl $manifest/prerequisites/mac.json?token=GHSAT0AAAAAABJEBVXLYPXRR7DJ3YIKATMOYSFR3AA | jq -r ".commands")
installer=$(curl $manifest/telemetry/installer/mac.json?token=GHSAT0AAAAAABJEBVXKGQSM663BXP7ICA6UYSMJBJQ | jq -r ".commands")

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
