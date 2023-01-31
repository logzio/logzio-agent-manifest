#!/bin/bash

#################################################################################################################################
################################################## Logs Linux Functions ###################################################
#################################################################################################################################

pubsub_repo="https://github.com/logzio/logzio-google-pubsub/releases/latest/download/logzio-google-pubsub.zip"

# Get Google project Id
# Output:
# project_id - Google Project Id
# Error:
#   Exit Code 1
function get_project_id(){

    write_log "INFO" "Getting user project name ..."

    local project_name_param=$(find_param "$logs_params" "projectName")
    if [[ -z "$project_name_param" ]]; then
        write_run "print_error \"logs.bash (3): project name param was not found\""
        return 1
    fi

    local project_name=$(echo -e "$project_name_param" | jq -c '.value')
    if [[ "$project_name" = null ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=projectName}].value' was not found in application JSON\""
        return 1
    fi
    if [[ -z "$project_name" ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=projectName}].value' is empty in application JSON\""
        return 1
    fi
    
    write_log "INFO" "project_name = $project_name"
    write_run "project_name=\"$project_name\""
}

# Set to google cloud acc, relevant project ID 
# Output:
# Error:
#   Exit Code 1
function set_project_id(){
    write_log "INFO" "running command gcloud to define user relevant project id ..."

    gcloud_user_project_list=$(gcloud projects list --filter='projectName='"$project_name"'')
    if [[ -z "$gcloud_user_project_list" ]]; then
        write_run "print_error \"logs.bash (1): 'projectId is not exist of user's project list. Please check projectId\""
        return 1
    else
        last_element=4
        current=0
        project_list=$(echo $gcloud_user_project_list | tr " " "\n")

        for addr in $project_list
        do
            current=$((current + 1))
            if [ $current -eq $last_element ]; then
                project_id="${addr}"
            fi
        done	
        set_current_project_id="$(gcloud config set project $project_id)"
        write_log "INFO" "${set_current_project_id}"
        write_log "INFO" "project_id = $project_id"
        write_run "project_id=\"$project_id\""
    fi

}

# Gets Logz.io listener
# Output:
#   logzio_listener - Logz.io listener
# Error:
#   Exit Code 1
function get_logzio_listener () {
    write_log "INFO" "Getting Logz.io listener ..."

    local listener_url=$(jq -r '.listenerUrl' $app_json)
    if [[ "$listener_url" = null ]]; then
        write_run "print_error \"logs.bash (1): '.listenerUrl' was not found in application JSON\""
        return 1
    fi
    if [[ -z "$listener_url" ]]; then
        write_run "print_error \"logs.bash (1): '.listenerUrl' is empty in application JSON\""
        return 1
    fi

    write_log "INFO" "listener_url = $listener_url"
    write_run "listener_url=\"$listener_url\""
}

# Gets Logz.io logs token
# Output:
#   logs_token - Logz.io logs token
# Error:
#   Exit Code 2
function get_logzio_logs_token () {
    write_log "INFO" "Getting Logz.io shipping token ..."

    local shipping_token=$(jq -r '.shippingTokens.LOG_ANALYTICS' $app_json)
    if [[ "$shipping_token" = null ]]; then
        write_run "print_error \"logs.bash (2): '.shippingTokens.LOG_ANALYTICS' was not found in application JSON\""
        return 2
    fi
    if [[ -z "$shipping_token" ]]; then
        write_run "print_error \"logs.bash (2): '.shippingTokens.LOG_ANALYTICS' is empty in application JSON\""
        return 2
    fi

    write_log "INFO" "shipping_token = $shipping_token"
    write_run "shipping_token=\"$shipping_token\""
}

# Gets Function Name
# Output:
#   function_name - function name
# Error:
#   Exit Code 3
function get_google_cloud_fuction_name_from_id () {
    write_log "INFO" "Getting Google Cloud Function Name..."

    local function_name=$(jq -r '.id' $app_json)
    if [[ "$function_name" = null ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=functionName}].value' was not found in application JSON\""
        return 3
    fi
    if [[ -z "$function_name" ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=functionName}].value' is empty in application JSON\""
        return 3
    fi
    
    write_log "INFO" "function_name = $function_name"
    write_run "function_name=\"$function_name\""
}

# Gets Filter for logs
# Output:
#   filter_log - filter logs
# Error:
#   Exit Code 3
function get_resources_type () {
    write_log "INFO" "Getting log resource type ..."

    local resource_type_param=$(find_param "$logs_params" "resourceType")
    if [[ -z "$resource_type_param" ]]; then
        write_run "print_error \"logs.bash (3): resourceType log param was not found\""
        return 3
    fi

    local resource_types=$(echo -e "$resource_type_param" | jq -c '.value[]')
    if [[ "$resource_types" = null ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=functionName}].value' was not found in application JSON\""
        return 3
    fi
    if [[ -z "$resource_types" ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=functionName}].value' is empty in application JSON\""
        return 3
    fi
    write_log "INFO" "resource_types = $resource_types"
    write_run "resource_types=\"$resource_types\""
}

# Gets Google Cloud Function Region
# Output:
#   region - google cloud function region
# Error:
#   Exit Code 3
function get_gcloud_function_region_log () {
    write_log "INFO" "Getting Google Cloud Function Region ..."

    local region_param=$(find_param "$logs_params" "functionNameRegion")
    if [[ -z "$region_param" ]]; then
        write_run "print_error \"logs.bash (3): region param was not found.\""
        return 3
    fi

    local region=$(echo -e "$region_param" | jq -c '.value')
    if [[ "$region" = null ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=functionNameRegion}].value' was not found in application JSON\""
        return 3
    fi
    
    write_log "INFO" "region = $region"
    write_run "region=\"$region\""
}


function download_logzio_pubsub_integration(){
	
    write_log "INFO" "Download pubsub integration files from Github ..."
    curl -fsSL $pubsub_repo > $logzio_temp_dir/logzio-google-pubsub.zip 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (1): failed to get last integration file from Github.\n  $err\""
        return 3
    fi

	
    # Unzip Integration release file 
    tar -zxf $logzio_temp_dir/logzio-google-pubsub.zip --directory $logzio_temp_dir 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (1): Failed to unzip Integration release file.\n  $err\""
        return 3
    fi

    # Add permission to execute file run.sh
    chmod +x $logzio_temp_dir/logzio-google-pubsub/run.sh 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (1): Failed to add permission to execution file.\n  $err\""
        return 3
    fi
}

# Download Last release of integration
# Output:
#   config.json file with related data
# Error:
#   Exit Code 3
function run_logzio_pubsub_integration(){
    write_log "INFO" "Run execution command to deploy integration to GCP account  ..."

    $logzio_temp_dir/logzio-google-pubsub/run.sh --listener_url=$listener_url --token=$shipping_token --gcp_region=$region --log_type=gcp_agent --function_name=$function_name --resource_list=$resource_type 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"logs.bash (1): Failed to run command for create Google Cloud function.\n  $err\""
        return 3
    fi
}

# Populate from resource type to filter by resource type pattern
# Output:
#   resource_type - resource type from filter
function populate_filter_for_service_name(){
    all_services="all_services"
    local resource_type=""
    current_bulk=0
    last_bulk_element=$(echo "$resource_types" | wc -l)

    while read -r resource_type_item; do
        if [[ ! -z "$resource_type_item" ]]; then

            current_bulk=$((current_bulk + 1))
            array_filter_bulk_names=(${resource_type_item//,/ })

                last_element=${#array_filter_bulk_names[@]}
                current=0
                for name in "${array_filter_bulk_names[@]}"
                do
                    current=$((current + 1))
                    if [ $current -eq $last_element ]; then
                        filter+="${name}"
                    else
                        filter+="${name},"
                    fi
            done
                if [ ! $current_bulk -eq $last_bulk_element ]; then
                    filter+=","
                fi	
        resource_type=$filter
        fi
        if [[ $filter == *"all_services"* ]]; then
            resource_type=""
        fi
    done < <(echo -e "$resource_types")
    write_log "INFO" "resource_type = $resource_type"
    write_run "resource_type=\"$resource_type\""
}
