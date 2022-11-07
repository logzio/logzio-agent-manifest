#!/bin/bash

#################################################################################################################################
################################################## Prerequisites Linux Functions ###################################################
#################################################################################################################################


# Gets Logz.io region
# Output:
#   logzio_region - Logz.io region
# Error:
#   Exit Code 1
function get_logzio_region () {
    write_log "INFO" "Getting Logz.io region ..."

    local listener_url=$(jq -r '.listenerUrl' $app_json)
    if [[ "$listener_url" = null ]]; then
        write_run "print_error \"logs.bash (1): '.listenerUrl' was not found in application JSON\""
        return 1
    fi
    if [[ -z "$listener_url" ]]; then
        write_run "print_error \"logs.bash (1): '.listenerUrl' is empty in application JSON\""
        return 1
    fi

    local region="us"
    if [[ "$listener_url" = *"-"* ]]; then
        local listener_part=$(cut -d "." -f1 <<< "$listener_url")
        region=$(cut -d "-" -f2 <<< "$listener_part")
    fi

    write_log "INFO" "logzio_region = $region"
    write_run "logzio_region=\"$region\""
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

# Gets log sources
# Output:
#   log_sources - list of log sources
# Error:
#   Exit Code 3
function get_log_sources () {
    write_log "INFO" "Getting log sources ..."

    local log_sources_param=$(find_param "$logs_params" "logSources")
    if [[ -z "$log_sources_param" ]]; then
        write_run "print_error \"logs.bash (3): log sources param was not found\""
        return 3
    fi

    local log_sources_value=$(echo -e "$log_sources_param" | jq -c '.value[]')
    if [[ "$log_sources_value" = null ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=optional-log-sources}].value[]' was not found in application JSON\""
        return 3
    fi
    if [[ -z "$log_sources_value" ]]; then
        write_run "print_error \"logs.bash (3): '.configuration.subtypes[0].datasources[0].telemetries[{type=LOG_ANALYTICS}].params[{name=optional-log-sources}].value[]' is empty in application JSON\""
        return 3
    fi
    
    write_log "INFO" "log_sources = $log_sources_value"
    write_run "log_sources=\"$log_sources_value\""
}

function download_config(){
	
}





function populate_data_to_json (){
    write_log "[INFO] Сreate build file..."

    contents="$(jq --arg token "${token}" '.substitutions._LOGZIO_TOKEN = $token' config.json)"
    echo "${contents}" > config.json
    contents="$(jq  --arg type_of_log "${type}" '.substitutions._TYPE_NAME = $type_of_log' config.json)"
    echo "${contents}" > config.json
    contents="$(jq --arg region "${region}" '.substitutions._REGION = $region' config.json)"
    echo "${contents}" > config.json
    contents="$(jq --arg listener_url "${listener_url}" '.substitutions._LOGZIO_LISTENER = $listener_url' config.json)"
    echo "${contents}" > config.json
    contents="$(jq --arg function_name "${function_name}" '.substitutions._FUNCTION_NAME = $function_name+"-func_logzio"' config.json)"
    echo "${contents}" > config.json
    contents="$(jq --arg topic_prefix "${function_name}" '.substitutions._PUBSUB_TOPIC_NAME = $topic_prefix+"-pubsub-topic-logs-to-logzio"' config.json)"
    echo "${contents}" > config.json
    contents="$(jq --arg subscription_prefix "${function_name}" '.substitutions._PUBSUB_SUBSCRIPTION_NAME = $subscription_prefix+"-pubsub-subscription-logs-to-logzio"' config.json)"
    echo "${contents}" > config.json
    contents="$(jq --arg sink_prefix "${function_name}" '.substitutions._SINK_NAME = $sink_prefix+"-sink-logs-to-logzio"' config.json)"
    echo "${contents}" > config.json
    contents="$(jq --arg filter_log "${filter_log}" '.substitutions._FILTER_LOG = $filter_log' config.json)"
    echo "${contents}" > config.json
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Populate data to json finished."
}

function run_cloud_build(){
    
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Initialize Cloud Build ..."
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
    cmd_create_cloud_build="$(curl -X POST -T config.json -H "Authorization: Bearer $access_token" https://cloudbuild.googleapis.com/v1/projects/$project_id/builds)"

    echo "$cmd_create_cloud_build"
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Cloud Build Initialization is finished."
}