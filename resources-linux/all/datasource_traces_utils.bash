#!/bin/bash

#################################################################################################################################
######################################### LINUX Datasource Traces Utils Functions ###############################################
#################################################################################################################################

# Gets Logz.io traces token
# Input:
#   ---
# Output:
#   TRACES_TOKEN - Logz.io traces token
function get_logzio_traces_token {
    local func_name="${FUNCNAME[0]}"

    local message='Getting Logz.io traces token ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    get_json_file_field_value "$AGENT_JSON" '.shippingTokens.TRACING'
    if [[ $? -ne 0 ]]; then
        message="traces.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    
    local shipping_token="$JSON_VALUE"

    message="Logz.io traces token is '$shipping_token'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "TRACES_TOKEN='$shipping_token'"
}

# Gets Logz.io metrics token
# Input:
#   ---
# Output:
#   METRICS_TOKEN - Logz.io metrics token
function get_logzio_metrics_token {
    local func_name="${FUNCNAME[0]}"

    local message='Getting Logz.io metrics token ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    get_json_file_field_value "$AGENT_JSON" '.shippingTokens.METRICS'
    if [[ $? -ne 0 ]]; then
        message="metrics.bash ($EXIT_CODE): $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_METRICS" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_task_post_run "write_error \"$message\""

        return $EXIT_CODE
    fi
    
    local shipping_token="$JSON_VALUE"

    message="Logz.io metrics token is '$shipping_token'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "METRICS_TOKEN='$shipping_token'"
}

# Gets the value for isSpanMetrics param
# Output: sets IS_SPAN_METRICS as "true" or "false" (string)
function get_is_span_metrics {
    local func_name="${FUNCNAME[0]}"
    local message="Getting 'isSpanMetrics' param for span metrics collection ..."
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    PARAMS=("${TRACES_PARAMS[@]}")
    get_param_value 'isSpanMetrics'
    local rc=$?
    if [[ $rc -ne 0 ]]; then
        IS_SPAN_METRICS="false"
        message="'isSpanMetrics' param not found, defaulting to false"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_log "$LOG_LEVEL_DEBUG" "$message"
    else
        IS_SPAN_METRICS="${PARAM_VALUE}"
        message="'isSpanMetrics' param found: $IS_SPAN_METRICS"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_log "$LOG_LEVEL_DEBUG" "$message"
    fi
    export IS_SPAN_METRICS
}

# Gets the value for samplingLatency param
# Output: sets SAMPLING_LATENCY as number (or default 0)
function get_sampling_latency {
    local func_name="${FUNCNAME[0]}"
    local message="Getting 'samplingLatency' param for trace sampling latency threshold ..."
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    PARAMS=("${TRACES_PARAMS[@]}")
    get_param_value 'samplingLatency'
    local rc=$?
    if [[ $rc -ne 0 ]]; then
        SAMPLING_LATENCY=200
        message="'samplingLatency' param not found, defaulting to 200"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_log "$LOG_LEVEL_DEBUG" "$message"
    else
        SAMPLING_LATENCY="${PARAM_VALUE}"
        message="'samplingLatency' param found: $SAMPLING_LATENCY"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_log "$LOG_LEVEL_DEBUG" "$message"
    fi
    export SAMPLING_LATENCY
}

# Gets the value for samplingPropability param
# Output: sets SAMPLING_PROPABILITY as number (or default 0)
function get_sampling_propability {
    local func_name="${FUNCNAME[0]}"
    local message="Getting 'samplingPropability' param for trace sampling propability ..."
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    PARAMS=("${TRACES_PARAMS[@]}")
    get_param_value 'samplingPropability'
    local rc=$?
    if [[ $rc -ne 0 ]]; then
        SAMPLING_PROPABILITY=10
        message="'samplingPropability' param not found, defaulting to 10"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_log "$LOG_LEVEL_DEBUG" "$message"
    else
        SAMPLING_PROPABILITY="${PARAM_VALUE}"
        message="'samplingPropability' param found: $SAMPLING_PROPABILITY"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_TRACES" "$LOG_SCRIPT_TRACES" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE" "$CURRENT_DATA_SOURCE"
        write_log "$LOG_LEVEL_DEBUG" "$message"
    fi
    export SAMPLING_PROPABILITY
}