#!/bin/bash

#################################################################################################################################
################################################## Prerequisites Linux Functions ###################################################
#################################################################################################################################


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
function get_google_cloud_fuction_name () {
    write_log "INFO" "Getting Google Cloud Function Name..."

    local function_name_param=$(find_param "$logs_params" "functionName")
    if [[ -z "$function_name_param" ]]; then
        write_run "print_error \"logs.bash (3): function name param was not found\""
        return 3
    fi

    local function_name=$(echo -e "$function_name_param" | jq -c '.value')
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


# Gets Log Type
# Output:
#   type_log - type log
# Error:
#   Exit Code 3
function get_logzio_log_type () {
    write_log "INFO" "Getting type log ..."

    local type_log_param=$(find_param "$logs_params" "typeLog")
    if [[ -z "$type_log_param" ]]; then
        write_run "print_error \"logs.bash (3): Log type param was not found\""
        return 3
    fi

    local type_log=$(echo -e "$type_log_param" | jq -c '.value')
    if [[ "$type_log" = null ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=typeLog}].value' was not found in application JSON\""
        return 3
    fi
    
    write_log "INFO" "type_log = $type_log"
    write_run "type_log=\"$type_log\""
}



# Gets Filter for logs
# Output:
#   filter_log - filter logs
# Error:
#   Exit Code 3
function get_filter_log () {
    write_log "INFO" "Getting log filter ..."

    local filter_log_param=$(find_param "$logs_params" "filterLog")
    if [[ -z "$filter_log_param" ]]; then
        write_run "print_error \"logs.bash (3): filters log param was not found\""
        return 3
    fi

    local filter_log=$(echo -e "$filter_log_param" | jq -c '.value')
    if [[ "$filter_log" = null ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=filterLog}].value' was not found in application JSON\""
        return 3
    fi
    
    write_log "INFO" "filter_log = $filter_log"
    write_run "filter_log=\"$filter_log\""
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

# Populate data to config file
# Output:
#   config.json file with related data
# Error:
#   Exit Code 3
function populate_data_to_config (){
    write_log "[INFO] Сreate build file..."
    curl -fsSL $repo_path/telemetry/logs/config.json > $logzio_temp_dir/config.json 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to get config.json file from Github.\n  $err\""
        return 3
    fi
	# test
	# echo $repo_path
    jq --arg shipping_token "${shipping_token}" '.substitutions._LOGZIO_TOKEN = $shipping_token' $logzio_temp_dir/config.json > "$tmp" && mv "$tmp" $logzio_temp_dir/config.json
    if [ $? -eq 0 ]; then
    # echo $? >  $logzio_temp_dir/config.json
        write_log "INFO" "_LOGZIO_TOKEN updated"
    else
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to write shipping_token to the config file.\n  $err\""
        return 3
    fi

    jq  --arg type_log "${type_log}" '.substitutions._TYPE_NAME = $type_log' $logzio_temp_dir/config.json > "$tmp" && mv "$tmp" $logzio_temp_dir/config.json
    if [ $? -eq 0 ]; then
        # echo "$?" >  $logzio_temp_dir/config.json
        write_log "INFO" "_TYPE_NAME updated"
    else
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to write type_log to the config file.\n  $err\""
        return 3
    fi

    jq --arg region "${region}" '.substitutions._REGION = $region' $logzio_temp_dir/config.json > "$tmp" && mv "$tmp" $logzio_temp_dir/config.json
    if [ $? -eq 0 ]; then
        write_log "INFO" "_REGION updated"
    else
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to write region to the config file.\n  $err\""
        return 3
    fi
    # echo "${contents}" >  $logzio_temp_dir/config.json

    jq --arg listener_url "${listener_url}" '.substitutions._LOGZIO_LISTENER = $listener_url' $logzio_temp_dir/config.json > "$tmp" && mv "$tmp" $logzio_temp_dir/config.json
    if [ $? -eq 0 ]; then
        write_log "INFO" "_LOGZIO_LISTENER updated"

    else
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to write listener_url to the config file.\n  $err\""
        return 3
    fi
    # echo "${contents}" >  $logzio_temp_dir/config.json

    jq --arg function_name "${function_name}" '.substitutions._FUNCTION_NAME = $function_name+"-func_logzio"' $logzio_temp_dir/config.json > "$tmp" && mv "$tmp" $logzio_temp_dir/config.json
    if [ $? -eq 0 ]; then
        write_log "INFO" "_FUNCTION_NAME updated"

    else
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to write function_name to the config file.\n  $err\""
        return 3
    fi   
    # echo "${contents}" >  $logzio_temp_dir/config.json

    jq --arg topic_prefix "${function_name}" '.substitutions._PUBSUB_TOPIC_NAME = $topic_prefix+"-pubsub-topic-logs-to-logzio"' $logzio_temp_dir/config.json > "$tmp" && mv "$tmp" $logzio_temp_dir/config.json
    if [ $? -eq 0 ]; then
        write_log "INFO" "_PUBSUB_TOPIC_NAME updated"

    else
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to write _PUBSUB_TOPIC_NAME to the config file.\n  $err\""
        return 3
    fi   
    # echo "${contents}" >  $logzio_temp_dir/config.json

    jq --arg subscription_prefix "${function_name}" '.substitutions._PUBSUB_SUBSCRIPTION_NAME = $subscription_prefix+"-pubsub-subscription-logs-to-logzio"' $logzio_temp_dir/config.json > "$tmp" && mv "$tmp" $logzio_temp_dir/config.json
    if [ $? -eq 0 ]; then
        write_log "INFO" "_PUBSUB_SUBSCRIPTION_NAME updated"

    else
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to write _PUBSUB_SUBSCRIPTION_NAME to the config file.\n  $err\""
        return 3
    fi   
    # echo "${contents}" >  $logzio_temp_dir/config.json
    
    jq --arg sink_prefix "${function_name}" '.substitutions._SINK_NAME = $sink_prefix+"-sink-logs-to-logzio"' $logzio_temp_dir/config.json > "$tmp" && mv "$tmp" $logzio_temp_dir/config.json
    if [ $? -eq 0 ]; then
        write_log "INFO" "_SINK_NAME updated"
    else
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to write _SINK_NAME to the config file.\n  $err\""
        return 3
    fi   
    # echo "${contents}" >  $logzio_temp_dir/config.json
    
    jq --arg filter_log "${filter_log}" '.substitutions._FILTER_LOG = $filter_log' $logzio_temp_dir/config.json > "$tmp" && mv "$tmp" $logzio_temp_dir/config.json
    if [ $? -eq 0 ]; then
        write_log "INFO" "_FILTER_LOG updated"
    else
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to write _FILTER_LOG to the config file.\n  $err\""
        return 3
    fi  
	# echo "${contents}" >  $logzio_temp_dir/config.json

    write_log "[INFO] Populate data to json finished."
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

    project_id="$(gcloud config get-value project)"
 
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

    write_log "$cmd_create_cloud_build"
    write_log "[INFO] Cloud Build Initialization is finished."
}