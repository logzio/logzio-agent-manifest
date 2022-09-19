#!/bin/bash

#################################################################################################################################
################################################# Postrequisites Mac Functions ###################################################
#################################################################################################################################

# Checks if all pods are running or completed 
# Output:
#   are_all_pods_running_or_completed - Tells if all pods are running or completed (true/false)
function are_all_pods_running_or_completed () {
    retries=0
    while [ $retries -lt 3 ]; do
        let "retries++"
        local pod_statuses=$(kubectl -n monitoring get pods --no-headers -o custom-columns=":.status.phase")
        echo -e "$pod_statuses" >> ./test.txt
        local is_any_pod_with_bad_status=$(echo -e "$pod_statuses" | grep -v -e Running -e Completed -e Succeeded)
        echo -e "---- $is_any_pod_with_bad_status" >> ./test.txt
        if [[ -z "$is_any_pod_with_bad_status" ]]; then
            write_log "INFO" "are_all_pods_running_or_completed = true"
            write_run "are_all_pods_running_or_completed=true"
            return
        fi

        sleep 10
    done

    write_log "INFO" "are_all_pods_running_or_completed = false"
    write_run "are_all_pods_running_or_completed=false"
}

# Checks if any pod is pending
# Output:
#   is_any_pod_pending - Tells if any pod is pending (true/false)
function is_any_pod_pending () {
    local err=""
    local pods=$(kubectl -n monitoring get pods --no-headers -o custom-columns=":.metadata.name,:.status.phase" | tr -s ' ')
    while read -r pod; do
        local pod_name=$(echo -e "$pod" | cut -d ' ' -f1)
        local pod_status=$(echo -e "$pod" | cut -d ' ' -f2)

        if [[ "$pod_status" != "Pending" ]]; then
            continue
        fi

        local event_reason=$(kubectl get event -n monitoring --field-selector involvedObject.name=$pod_name --no-headers -o custom-columns=":.reason" | tail -1)
        local event_message=$(kubectl get event -n monitoring --field-selector involvedObject.name=$pod_name --no-headers -o custom-columns=":.message" | tail -1)
        err+="\n  pod $pod_name status is Pending. reason: $event_reason, message: $event_message"
    done < <(echo -e "$pods")

    if [[ -z "$err" ]]; then
        write_log "INFO" "is_any_pod_pending = false"
        write_run "is_any_pod_pending=false"
        return
    fi

    write_log "INFO" "is_any_pod_pending = true"
    write_run "is_any_pod_pending=true"
    write_run "print_error \"found pending pods:$err\""
}

# Checks if any pod is failed
# Output:
#   is_any_pod_failed - Tells if any pod is failed (true/false)
function is_any_pod_failed () {
    local err=""
    local pods=$(kubectl -n monitoring get pods --no-headers -o custom-columns=":.metadata.name,:.status.phase" | tr -s ' ')
    while read -r pod; do
        local pod_name=$(echo -e "$pod" | cut -d ' ' -f1)
        local pod_status=$(echo -e "$pod" | cut -d ' ' -f2)

        if [[ "$pod_status" != "Running" || "$pod_status" != "Completed" || "$pod_status" != "Succeeded" || "$pod_status" != "Pending" ]]; then
            continue
        fi

        err+="\n  pod $pod_name status is $pod_status"
    done < <(echo -e "$pods")

    if [[ -z "$err" ]]; then
        write_log "INFO" "is_any_pod_failed = false"
        write_run "is_any_pod_failed=false"
        return
    fi

    write_log "INFO" "is_any_pod_failed = true"
    write_run "is_any_pod_failed=true"
    write_run "print_error \"\nfound failed pods (run kubectl -n monitorin logs <<POD_NAME>> to see why):$err\""
}
