#!/bin/bash

#################################################################################################################################
######################################## MAC Subtype Post-requisites Utils Functions ############################################
#################################################################################################################################

# Checks if all pods are running or completed
# Input:
#   ---
# Output:
#   ARE_ALL_PODS_RUNNING_OR_COMPLETED - Tells if all pods are running or completed (true/false)
function are_all_pods_running_or_completed {
    local func_name="${FUNCNAME[0]}"

    local message='Checking if all pods are running or completed ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local retries=18
    while [[ $retries -ne 0 ]]; do
        local pod_statuses
        pod_statuses=$(kubectl get pods -n monitoring --no-headers -o custom-columns=':.status.phase' 2>"$TASK_ERROR_FILE")
        if [[ $? -ne 0 ]]; then
            local err=$(get_task_error_message)
            if [[ "$err" == *"ERROR"* ]]; then
                message="postrequisites.bash ($EXIT_CODE): error getting pod statuses: $err"
                send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
                write_task_post_run "write_error \"$message\""
            
                return $EXIT_CODE
            fi
        fi

        local bad_statuses=$(echo -e "$pod_statuses" | grep -v -e Running -e Completed -e Succeeded)
        if [[ -z "$bad_statuses" ]]; then
            message='All pods are running or completed'
            send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_log "$LOG_LEVEL_DEBUG" "$message"

            write_task_post_run 'ARE_ALL_PODS_RUNNING_OR_COMPLETED=true'
            return
        fi

        sleep 10
        ((retries--))
    done

    message='Not all pods are running or completed'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run 'ARE_ALL_PODS_RUNNING_OR_COMPLETED=false'
}

# Checks if any pod is pending
# Input:
#   ---
# Output:
#   ---
function is_any_pod_pending {
    local func_name="${FUNCNAME[0]}"

    local message='Checking if any pod is pending ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local err=''
    local pods
    pods=$(kubectl get pods -n monitoring --no-headers -o custom-columns=':.metadata.name,:.status.phase' 2>"$TASK_ERROR_FILE" | tr -s ' ')
    if [[ $? -ne 0 ]]; then
        local err=$(get_task_error_message)
        if [[ "$err" == *"ERROR"* ]]; then
            write_task_post_run 'IS_POSTREQUISITES_FAILED=true'
        
            message="postrequisites.bash ($EXIT_CODE): error getting pod names and statuses: $err"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi
    fi

    while read -r pod; do
        local pod_name=$(echo -e "$pod" | cut -d ' ' -f1)
        local pod_status=$(echo -e "$pod" | cut -d ' ' -f2)

        if [[ "$pod_status" != 'Pending' ]]; then
            continue
        fi
        
        local event_reason
        event_reason=$(kubectl get event -n monitoring --field-selector involvedObject.name="$pod_name" --no-headers -o custom-columns=':.reason' 2>"$TASK_ERROR_FILE" | head -n 1)
        if [[ $? -ne 0 ]]; then
            local err=$(get_task_error_message)
            if [[ "$err" == *"ERROR"* ]]; then
                write_task_post_run 'IS_POSTREQUISITES_FAILED=true'
        
                message="postrequisites.bash ($EXIT_CODE): error getting pending pod '$pod_name' reason: $err"
                send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
                write_task_post_run "write_error \"$message\""

                return $EXIT_CODE
            fi
        fi

        local event_message
        event_message=$(kubectl get event -n monitoring --field-selector involvedObject.name="$pod_name" --no-headers -o custom-columns=':.message' 2>"$TASK_ERROR_FILE" | head -n 1)
        if [[ $? -ne 0 ]]; then
            local err=$(get_task_error_message)
            if [[ "$err" == *"ERROR"* ]]; then
                write_task_post_run 'IS_POSTREQUISITES_FAILED=true'
        
                message="postrequisites.bash ($EXIT_CODE): error getting pending pod '$pod_name' message: $(get_task_error_message)"
                send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
                write_task_post_run "write_error \"$message\""

                return $EXIT_CODE
            fi
        fi

        err+="\n'$pod_name' pod status is 'Pending'. reason: $event_reason, message: $event_message"
    done < <(echo -e "$pods")

    if [[ -z "$err" ]]; then
        message='No pod is pending'
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        return
    fi

    write_task_post_run 'IS_POSTREQUISITES_FAILED=true'

    message="postrequisites.bash ($EXIT_CODE): found pending pods:$err"
    send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_task_post_run "write_error \"$message\""

    return $EXIT_CODE
}

# Checks if any pod is failed
# Input:
#   ---
# Output:
#   ---
function is_any_pod_failed {
    local func_name="${FUNCNAME[0]}"

    local message='Checking if any pod is failed ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local err=''
    local pods
    pods=$(kubectl get pods -n monitoring --no-headers -o custom-columns=':.metadata.name,:.status.phase' 2>"$TASK_ERROR_FILE" | tr -s ' ')
    if [[ $? -ne 0 ]]; then
        local err=$(get_task_error_message)
        if [[ "$err" == *"ERROR"* ]]; then
            write_task_post_run "IS_POSTREQUISITES_FAILED=true"
        
            message="postrequisites.bash ($EXIT_CODE): error getting pod names and statuses: $err"
            send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
            write_task_post_run "write_error \"$message\""

            return $EXIT_CODE
        fi
    fi

    while read -r pod; do
        local pod_name=$(echo -e "$pod" | cut -d ' ' -f1)
        local pod_status=$(echo -e "$pod" | cut -d ' ' -f2)

        if [[ "$pod_status" == 'Running' || "$pod_status" == 'Completed' || "$pod_status" == 'Succeeded' || "$pod_status" == 'Pending' ]]; then
            continue
        fi
        
        local pod_logs
        pod_logs=$(kubectl logs "$pod_name" -n monitoring 2>"$TASK_ERROR_FILE")
        if [[ $? -ne 0 ]]; then
            local err=$(get_task_error_message)
            if [[ "$err" == *"ERROR"* ]]; then
                write_task_post_run "IS_POSTREQUISITES_FAILED=true"
        
                message="postrequisites.bash ($EXIT_CODE): error getting pod '$pod_name' logs: $err"
                send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
                write_task_post_run "write_error \"$message\""

                return $EXIT_CODE
            fi
        fi

        err+="\n'$pod_name' pod status is '$pod_status': $pod_logs"
    done < <(echo -e "$pods")

    if [[ -z "$err" ]]; then
        message='No pod is failed'
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        return
    fi

    write_task_post_run 'IS_POSTREQUISITES_FAILED=true'

    message="postrequisites.bash ($EXIT_CODE): found failed pods:$err"
    send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_POSTREQUISITES" "$LOG_SCRIPT_POSTREQUISITES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_task_post_run "write_error \"$message\""
    
    return $EXIT_CODE
}
