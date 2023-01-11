#!/bin/bash

#################################################################################################################################
################################################## Prerequisites Linux Functions ###################################################
#################################################################################################################################

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
        write_run "print_error \"logs.bash (3): region param was not found\""
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

# Download  cloud function to temp directory
# Output:
#   function cloud files
# Error:
#   Exit Code 3
function download_cloud_funcion_to_temp_directory (){
    write_log "[INFO] Download from github cloud function..."

	mkdir $logzio_temp_dir/function_cloud
	if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to create folder for cloud function files.\n  $err\""
        return 3
    fi

    curl -fsSL $repo_path/telemetry/logs/function_cloud/function.go > $logzio_temp_dir/function_cloud/function.go 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to get function.go file from Github.\n  $err\""
        return 3
    fi
	 curl -fsSL $repo_path/telemetry/logs/function_cloud/go.mod > $logzio_temp_dir/function_cloud/go.mod 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to get go.mod file from Github.\n  $err\""
        return 3
    fi
}


# Populate data to config file
# Output:
#   config.json file with related data
# Error:
#   Exit Code 3
function populate_data_to_config (){
    write_log "[INFO] Сreate build file..."
    tmpfile=$(mktemp)
    curl -fsSL $repo_path/telemetry/logs/config.json > $logzio_temp_dir/config.json 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to get config.json file from Github.\n  $err\""
        return 3
    fi

    jq --arg topic_prefix "${function_name}" '.substitutions._PUBSUB_TOPIC_NAME = "p"+$topic_prefix+"-topic-logzio"' $logzio_temp_dir/config.json >"$tmpfile" && mv -- "$tmpfile" $logzio_temp_dir/config.json
    if [ $? -eq 0 ]; then
        write_log "INFO" "_PUBSUB_TOPIC_NAME updated"

    else
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to write _PUBSUB_TOPIC_NAME to the config file.\n  $err\""
        return 3
    fi   

      
    jq --arg sink_prefix "${function_name}" '.substitutions._SINK_NAME = "sink-"+$sink_prefix+"-sink-logzio"' $logzio_temp_dir/config.json >"$tmpfile" && mv -- "$tmpfile" $logzio_temp_dir/config.json
    if [ $? -eq 0 ]; then
        write_log "INFO" "_SINK_NAME updated"
    else
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to write _SINK_NAME to the config file.\n  $err\""
        return 3
    fi   
    
    jq --arg resource_type "${resource_type}" '.substitutions._FILTER_LOG = $resource_type' $logzio_temp_dir/config.json >"$tmpfile" && mv -- "$tmpfile" $logzio_temp_dir/config.json
    if [ $? -eq 0 ]; then
        write_log "INFO" "_FILTER_LOG updated"
    else
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to write _FILTER_LOG to the config file.\n  $err\""
        return 3
    fi  

    write_log "[INFO] Populate data to json finished."
}

# Populate from resource type to filter by resource type pattern
# Output:
#   resource_type - resource type from filter
function populate_filter_for_service_name(){
    all_services="all_services"
    local resource_type=""
    while read -r resource_type_item; do
        if [[ ! -z "$resource_type_item" ]]; then
            array_filter_bulk_names=(${resource_type_item//,/ })
            last_bulk_element=${#array_filter_bulk_names[@]}
            current_bulk=0
            filter=" AND"
            for resource_bulk_type in "${array_filter_bulk_names[@]}"
            do
                array_filter_names=(${resource_bulk_type//,/ })
                last_element=${#array_filter_names[@]}
				write_log "[INFO] Populate data v2=> $array_filter_names"
					write_log "[INFO] Populate filter v2=> $filter"
                current_bulk=$((current_bulk + 1))
                current=0
                for name in "${array_filter_names[@]}"
                do
					write_log "[INFO] Populate data v3=> $name"
					write_log "[INFO] Populate filter v3=> $filter"
                    current=$((current + 1))
                    if [ $current -eq $last_element ]; then
					write_log "[INFO] Populate data v4=> $name"
					write_log "[INFO] Populate filter v4=> $filter"
                        filter+=" resource.type=${name}"
                    else
					write_log "[INFO] Populate data v5=> $name"
					write_log "[INFO] Populate filter v5=> $filter"
                        filter+=" resource.type=${name} OR"
                    fi
                done
                if [ ! $current_bulk -eq $last_bulk_element ]; then
                    filter+=" OR"
                fi	
            done
        resource_type=$filter
        fi
        if [[ $filter == *"all_services"* ]]; then
            resource_type=""
        fi
    done < <(echo -e "$resource_types")
    write_log "INFO" "resource_type = $resource_type"
    write_run "resource_type=\"$resource_type\""
}

# Deploy
# Output:
#   filter_log - filter logs
# Error:
#   Exit Code 3
function deploy_settings_to_gcp(){
    write_log "[INFO] Initialize Cloud Build ..."
    # Take project ID and project Number
    project_number="$(gcloud projects list \
    --filter="$(gcloud config get-value project)" \
    --format="value(PROJECT_NUMBER)")"
 
    # Give permission for Cloud Build to assign proper roles
    cmd_enable_cloudresourcemanager="$(gcloud services enable cloudresourcemanager.googleapis.com)"
    cmd_enable_cloudbuild="$(gcloud services enable cloudbuild.googleapis.com)"
    cmd_enable_cloudfunction="$(gcloud services enable cloudfunctions.googleapis.com)"

    cmd_add_policy="$(gcloud projects add-iam-policy-binding $project_id --member serviceAccount:$project_number@cloudbuild.gserviceaccount.com --role roles/resourcemanager.projectIamAdmin)"
    cmd_enable_policy_function="$(gcloud iam service-accounts add-iam-policy-binding $project_id@appspot.gserviceaccount.com --member serviceAccount:$project_number@cloudbuild.gserviceaccount.com --role roles/iam.serviceAccountUser)"

    #Get Access Token for upload
    access_token="$(gcloud config config-helper --format='value(credential.access_token)')"
    # Run project
    cmd_create_cloud_build="$(curl -X POST -T $logzio_temp_dir/config.json -H "Authorization: Bearer $access_token" https://cloudbuild.googleapis.com/v1/projects/$project_id/builds)"

    function_name_sufix="f${function_name}_func_logzio"
    topic_prefix="p$function_name-topic-logzio"

    gcloud functions deploy $function_name_sufix --region=$region --trigger-topic=$topic_prefix --entry-point=LogzioHandler --runtime=go116  --source=$logzio_temp_dir/function_cloud  --no-allow-unauthenticated --set-env-vars=token=$shipping_token --set-env-vars=type=gcp_agent --set-env-vars=listener=$listener_url
    if [[ $? -ne 0 ]]; then
        echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] Failed to create Cloud Function."
        exit 1
    fi

    write_log "[INFO] Cloud Build Initialization is finished."
}