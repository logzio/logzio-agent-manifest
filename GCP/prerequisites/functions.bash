#!/bin/bash

#################################################################################################################################
################################################## Prerequisites Linux Functions ###################################################
#################################################################################################################################

# Installs yq
# Output:
#   yq_bin - The yq binary file path
# Error:
#   Exit Code 1
function install_yq () {
    write_log "INFO" "Installing yq ..."
    curl -fsSL https://github.com/mikefarah/yq/releases/download/v4.27.2/yq_linux_amd64.tar.gz > $logzio_temp_dir/yq.tar.gz 2>$task_error_file
    if [[ $? -ne 0 ]]; then
        local err=$(cat $task_error_file)
        write_run "print_error \"prerequisites.bash (1): failed to get yq binary file from Github.\n  $err\""
        return 1
    fi

    yq_bin="$logzio_temp_dir/yq_linux_amd64"
    tar -zxf $logzio_temp_dir/yq.tar.gz --directory $logzio_temp_dir
    write_run "yq_bin=\"$yq_bin\""
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