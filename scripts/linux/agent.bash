#!/bin/bash

#################################################################################################################################
####################################################### LINUX Agent Script ######################################################
#################################################################################################################################

# Gets agent id
# Input:
#   ---
# Output:
#   AGENT_ID - Logz.io agent id
function get_agent_id {
    for arg in "${AGENT_ARGS[@]}"; do
        case "$arg" in
            --id=*)
                local agent_id=$(echo "$arg" | cut -d '=' -f2)
                AGENT_ID="$agent_id"
                return
        esac
    done
}

# Gets temp destination path
# Input:
#   ---
# Output:
#   LOGZIO_TEMP_DIR - temp destination path
function get_temp_dest {
    for arg in "${AGENT_ARGS[@]}"; do
        case "$arg" in
            --temp_dest=*)
                local temp_dest=$(echo "$arg" | cut -d '=' -f2)
                if [[ ! -d "$temp_dest" ]]; then
                    return
                fi

                LOGZIO_TEMP_DIR="$temp_dest/logzio"
                return
        esac
    done
}

# Run final commands
# Input:
#   ---
# Ouput:
#   ---
function run_final {
    write_agent_final_messages
    delete_temp_dir

    tput cnorm -- normal 2>/dev/null
}

# Deletes Logz.io temp directory
# Input:
#   ---
# Output:
#   ---
function delete_temp_dir {
    rm -f -R "$LOGZIO_TEMP_DIR" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        write_warning "failed to delete Logz.io temp directory"
    fi
}

# Prints agent final messages
# Input:
#   ---
# Output:
#   Agent final messages
function write_agent_final_messages {
    local func_name="${FUNCNAME[0]}"

    if $IS_SHOW_HELP; then
        return
    fi
    if $IS_LOADING_AGENT_SCRIPTS_FAILED; then
        local message='Agent Failed'
        write_agent_status "$message" '\033[0;31m'
        write_agent_support
        return
    fi
    if $IS_REMOVE_LAST_RUN_ANSWER_NO; then
        write_agent_info
        write_agent_support
        return
    fi
    if $IS_POSTREQUISITES_FAILED; then
        local message='Agent Failed'
        send_log_to_logzio "$LOG_LEVEL_INFO" "$message" "$LOG_STEP_FINAL" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_log "$LOG_LEVEL_INFO" "$message"

        write_agent_status "$message" '\033[0;31m'
        write_agent_info
        write_agent_support
        return
    fi
    if $IS_AGENT_FAILED; then
        local message='Agent Failed'
        send_log_to_logzio "$LOG_LEVEL_INFO" "$message" "$LOG_STEP_FINAL" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        write_log "$LOG_LEVEL_INFO" "$message"

        write_agent_status "$message" '\033[0;31m'
        write_agent_support
        return
    fi
    if $IS_AGENT_STOPPED; then
        local message='Agent Stopped By User'
    
        if [[ $(type -t send_log_to_logzio) == function ]]; then
            send_log_to_logzio "$LOG_LEVEL_INFO" "$message" "$LOG_STEP_FINAL" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
        fi

        write_agent_status "$message" '\033[0;33m'
        return
    fi

    local message='Agent Completed Successfully'
    send_log_to_logzio "$LOG_LEVEL_INFO" "$message" "$LOG_STEP_FINAL" "$LOG_SCRIPT_AGENT" "$func_name" "$AGENT_ID"
    write_log "$LOG_LEVEL_INFO" "$message"
    
    write_agent_status "$message" '\033[0;32m'
    write_agent_info
    write_agent_support
}

# Prints agent interruption message
# Input:
#   ---
# Output:
#   Agent interruption message
function write_agent_interruption_message {
    trap SIGINT

    IS_AGENT_STOPPED=true
    run_final

    exit
}

# Prints agent status
# Input:
#   ---
# Ouput:
#   Agent status
function write_agent_status {
    local message="$1"
    local color="$2"

    echo
    echo

    local repeat=5
    while [[ $repeat -ne 0 ]]; do
        if [[ $((repeat%2)) -eq 0 ]]; then
            echo -ne "\r##### $message #####"
        else
            echo -ne "\r$color##### $message #####\033[0;37m"
        fi

        sleep 0.25
        ((repeat--))
    done

    echo
    echo
}

# Prints agent info
# Input:
#   ---
# Ouput:
#   Agent info message
function write_agent_info {
    source "$LOGZIO_TEMP_DIR/${PLATFORM,,}/${SUB_TYPE,,}/$AGENT_INFO_FILE" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        local message="failed to print agent info: $(get_task_error_message)"
        write_warning "$message"
    fi
}

# Prints agent support message
# Input:
#   ---
# Output:
#   Support message 
function write_agent_support {
    echo
    echo -e '###############'
    echo -e "###$PURPLE_COLOR Support $WHITE_COLOR###"
    echo -e '###############'
    echo -e 'If you have any issue, request or additional questions, our Amazing Support Team will be more than happy to assist.'
    echo -e "You can contact us via 'help@logz.io' email or chat in Logz.io application under 'Need help?'."
    echo
}


# Settings
trap "write_agent_interruption_message" INT 
tput civis -- invisible 2>/dev/null

# Agent args
AGENT_ARGS=("$@")
Agent_ID=''

# Logz.io temp directory
LOGZIO_TEMP_DIR='/tmp/logzio'

# proxy ip
PROXY=''

# Exit code
EXIT_CODE=1

# Agent status flags
IS_SHOW_HELP=false
IS_LOADING_AGENT_SCRIPTS_FAILED=false
IS_REMOVE_LAST_RUN_ANSWER_NO=false
IS_AGENT_STOPPED=false
IS_AGENT_FAILED=false
IS_POSTREQUISITES_STEP=false
IS_POSTREQUISITES_FAILED=false
CONTINUE_IF_FAILED=false
IS_AGENT_COMPLETED=false

# Get temp destination path
get_temp_dest

# Agent version
AGENT_VERSION=$(cat "$LOGZIO_TEMP_DIR/version")

# Print main title - Christmas theme
source "$LOGZIO_TEMP_DIR/logo-themes/default.bash" 2>"$LOGZIO_TEMP_DIR/task_error.txt"
if [[ $? -ne 0 ]]; then
    echo
    echo -e "\033[0;36mLogz.io Agent $AGENT_VERSION\033[0;37m"
    echo
fi

# Load consts
source "$LOGZIO_TEMP_DIR/consts.bash" 2>"$LOGZIO_TEMP_DIR/task_error.txt"
if [[ $? -ne 0 ]]; then
    IS_LOADING_AGENT_SCRIPTS_FAILED=true
    echo -e "\033[0;31magent.bash ($EXIT_CODE): error loading agent scripts: $(cat $LOGZIO_TEMP_DIR/task_error.txt)\033[0;37m"

    exit $EXIT_CODE
fi
# Load agent functions
source "$LOGZIO_TEMP_DIR/functions.bash" 2>"$LOGZIO_TEMP_DIR/task_error.txt"
if [[ $? -ne 0 ]]; then
    IS_LOADING_AGENT_SCRIPTS_FAILED=true
    echo -e "\033[0;31magent.bash ($EXIT_CODE): error loading agent scripts: $(cat $LOGZIO_TEMP_DIR/task_error.txt)\033[0;37m"

    exit $EXIT_CODE
fi
# Load agent utils functions
source "$LOGZIO_TEMP_DIR/utils_functions.bash" 2>"$LOGZIO_TEMP_DIR/task_error.txt"
if [[ $? -ne 0 ]]; then
    IS_LOADING_AGENT_SCRIPTS_FAILED=true
    echo -e "${RED_COLOR}agent.bash ($EXIT_CODE): error loading agent scripts: $(cat $LOGZIO_TEMP_DIR/task_error.txt)$WHITE_COLOR"

    exit $EXIT_CODE
fi

# Clears content of task post run script file if exists (happens if Logz.io temp directory was not deleted)
if [[ -f "$TASK_POST_RUN_FILE" ]]; then
    >"$TASK_POST_RUN_FILE"
fi

# Get agent id
get_agent_id

# Write agent running log
send_log_to_logzio "$LOG_LEVEL_INFO" 'Start running Logz.io agent ...' "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" '' "$AGENT_ID"
write_log "$LOG_LEVEL_INFO" 'Start running Logz.io agent ...'

# Print title
echo -e '##########################'
echo -e "###$PURPLE_COLOR Pre-Initialization $WHITE_COLOR###"
echo -e '##########################'

# Get Linux info
execute_task 'get_linux_info' 'Getting Linux info'
# Check if bash version is 4.0 or above
execute_task 'is_bash_version_4_or_above' 'Checking if bash version is 4.0 or above'
# Get arguments
execute_task 'get_arguments' 'Getting arguments'
# Check arguments validation
execute_task 'check_arguments_validation' 'Checking arguments validation'

# Print title
echo
echo -e '#################'
echo -e "###$PURPLE_COLOR Downloads $WHITE_COLOR###"
echo -e '#################'

# Download jq
execute_task 'download_jq' 'Downloading jq'
# Download yq
execute_task 'download_yq' 'Downloading yq'

# Print title
echo
echo -e '######################'
echo -e "###$PURPLE_COLOR Initialization $WHITE_COLOR###"
echo -e '######################'

# Get agent json
execute_task 'get_agent_json' 'Getting agent json'
# Get agent json info
execute_task 'get_agent_json_info' 'Getting agent json info'
# Get Logz.io listener url
execute_task 'get_logzio_listener_url' 'Getting Logz.io listener url'
# Download subtype files
execute_task 'download_sub_type_files' 'Downloading subtype files'

AGENT_EXIT_CODE=$EXIT_CODE

# Run subtype prerequisites
run_sub_type_prerequisites

# Run subtype installer
run_sub_type_installer

if ! $IS_REMOVE_LAST_RUN_ANSWER_NO; then
    # Run subtype post-requisites
    run_sub_type_postrequisites
fi

# Run final commands
run_final
