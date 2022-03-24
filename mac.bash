#!/bin/bash

######################################################## JQ Installation ########################################################

where jq
if [ $? -ne 0 ]; then
    brew install jq
fi

#################################################################################################################################

#################################################### Build Paths to Manifest ####################################################

app_json=$1                             # Application JSON file
dir1=$(jq -r .name $app_json)
dir2=$(jq -r .subtype.name $app_json)
dir3=$(jq -r .subtype.datasources[0].name $app_json)

manifest="https://raw.githubusercontent.com/logzio/logzio-agent-manifest/init/$dir1/$dir2/$dir3"
prerequisites=$(curl $manifest/prerequisites/mac.json?token=GHSAT0AAAAAABJEBVXK64AYDDFCSPXEQZRGYSB3BXA | jq -r .commands)
#installer=$(curl $manifest/telemetry/installer/mac.json?token=GHSAT0AAAAAABJEBVXK64AYDDFCSPXEQZRGYSB3BXA | jq -r .commands)

#################################################################################################################################

################################################## Run Prerequisites Commands ###################################################

while read line; do
    full_command=""
    while read command; do
        full_command+=" $command"
    done <<< "$(echo $line | jq -r .[])"
    eval $full_command
done <<< "$(echo $prerequisites | jq -c .[].run)"

#################################################################################################################################




