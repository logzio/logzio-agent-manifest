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
    write_log "INFO" "Getting Logz.io logs token ..."

    local shipping_token=$(jq -r '.shippingTokens.LOG_ANALYTICS' $app_json)
    if [[ "$shipping_token" = null ]]; then
        write_run "print_error \"logs.bash (2): '.shippingTokens.LOG_ANALYTICS' was not found in application JSON\""
        return 2
    fi
    if [[ -z "$shipping_token" ]]; then
        write_run "print_error \"logs.bash (2): '.shippingTokens.LOG_ANALYTICS' is empty in application JSON\""
        return 2
    fi

    write_log "INFO" "logs_token = $shipping_token"
    write_run "logs_token=\"$shipping_token\""
}

# Gets Function Name
# Output:
#   function_name - function name
# Error:
#   Exit Code 3
function get_function_name () {
    write_log "INFO" "Getting log sources ..."

    local function_name_param=$(find_param "$logs_params" "functionName")
    if [[ -z "$function_name_param" ]]; then
        write_run "print_error \"logs.bash (3): function name param was not found\""
        return 3
    fi

    local function_name_value=$(echo -e "$function_name_param" | jq -c '.value')
    if [[ "$function_name_value" = null ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=functionName}].value' was not found in application JSON\""
        return 3
    fi
    if [[ -z "$function_name_value" ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=functionName}].value' is empty in application JSON\""
        return 3
    fi
    
    write_log "INFO" "function_name = $function_name_value"
    write_run "function_name=\"$function_name_value\""
}

# Gets Function Name
# Output:
#   filter_log - function name
# Error:
#   Exit Code 3
function get_filter_log () {
    write_log "INFO" "Getting log sources ..."

    local filter_log_param=$(find_param "$logs_params" "filterLog")
    if [[ -z "$filter_log_param" ]]; then
        write_run "print_error \"logs.bash (3): filters log param was not found\""
        return 3
    fi

    local filter_log_value=$(echo -e "$ffilter_log_param" | jq -c '.value')
    if [[ "$function_name_value" = null ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=filterLog}].value' was not found in application JSON\""
        return 3
    fi
    if [[ -z "$filter_log_value" ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=filterLog}].value' is empty in application JSON\""
        return 3
    fi
    
    write_log "INFO" "filter_log = $filter_log_value"
    write_run "filter_log=\"$filter_log_value\""
}



function populate_data_to_json (){
    write_log "[INFO] Сreate build file..."
    curl -fsSL https://github.com/logzio/logzio-google-pubsub/archive/refs/tags/v1.0.0.tar.gz > $logzio_temp_dir/otelcol-logzio.tar.gz 2>$task_error_file

    contents="$(jq --arg token "${token}" '.substitutions._LOGZIO_TOKEN = $token'  $logzio_temp_dir/config.json)"
    echo "${contents}" >  $logzio_temp_dir/config.json
    contents="$(jq  --arg type_of_log "${type}" '.substitutions._TYPE_NAME = $type_of_log'  $logzio_temp_dir/config.json)"
    echo "${contents}" >  $logzio_temp_dir/config.json
    contents="$(jq --arg region "${region}" '.substitutions._REGION = $region'  $logzio_temp_dir/config.json)"
    echo "${contents}" >  $logzio_temp_dir/config.json
    contents="$(jq --arg listener_url "${listener_url}" '.substitutions._LOGZIO_LISTENER = $listener_url'  $logzio_temp_dir/config.json)"
    echo "${contents}" >  $logzio_temp_dir/config.json
    contents="$(jq --arg function_name "${function_name}" '.substitutions._FUNCTION_NAME = $function_name+"-func_logzio"'  $logzio_temp_dir/config.json)"
    echo "${contents}" >  $logzio_temp_dir/config.json
    contents="$(jq --arg topic_prefix "${function_name}" '.substitutions._PUBSUB_TOPIC_NAME = $topic_prefix+"-pubsub-topic-logs-to-logzio"'  $logzio_temp_dir/config.json)"
    echo "${contents}" >  $logzio_temp_dir/config.json
    contents="$(jq --arg subscription_prefix "${function_name}" '.substitutions._PUBSUB_SUBSCRIPTION_NAME = $subscription_prefix+"-pubsub-subscription-logs-to-logzio"'  $logzio_temp_dir/config.json)"
    echo "${contents}" >  $logzio_temp_dir/config.json
    contents="$(jq --arg sink_prefix "${function_name}" '.substitutions._SINK_NAME = $sink_prefix+"-sink-logs-to-logzio"'  $logzio_temp_dir/config.json)"
    echo "${contents}" >  $logzio_temp_dir/config.json
    contents="$(jq --arg filter_log "${filter_log}" '.substitutions._FILTER_LOG = $filter_log' config.json)"
    echo "${contents}" >  $logzio_temp_dir/config.json

    write_log "[INFO] Populate data to json finished."
}

function run_cloud_build(){
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