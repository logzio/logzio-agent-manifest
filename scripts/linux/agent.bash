#!/bin/bash

#################################################################################################################################
####################################################### LINUX Agent Script ######################################################
#################################################################################################################################

# Deletes Logz.io temp directory
# Input:
#   ---
# Output:
#   ---
function delete_temp_dir {
    rm -f -R $LOGZIO_TEMP_DIR 2>$TASK_ERROR_FILE
    if [[$? -ne 0]]; then
        write_warning "failed to delete Logz.io temp directory: $(get_task_error_message)"
    fi
}

# Prints agent final messages
# Input:
#   ---
# Output:
#   Agent final messages
function write_agent_final_messages {
    local func_name=$0

    if $IS_SHOW_HELP; then
        return
    fi
    if $IS_LOADING_AGENT_SCRIPTS_FAILED; then
        local message='Agent Failed'
        write_agent_status $message 'Red'
        write_agent_support
        return
    fi
    if $IS_REMOVE_LAST_RUN_ANSWER_NO; then
        write_agent_info
        write_agent_support
        return
    fi
    if $Is_AGENT_FAILED; then
        local message='Agent Failed'
        send_log_to_logzio $LOG_LEVEL_INFO $message $LOG_STEP_FINAL $LOG_SCRIPT_AGENT $func_name $AGENT_ID
        write_log $LOG_LEVEL_INFO $message

        write_agent_status $message 'Red'
        write_agent_support
        return
    fi
    if $IS_POSTREQUISITE_FAILED; then
        local message='Agent Failed'
        send_log_to_logzio $LOG_LEVEL_INFO $message $LOG_STEP_FINAL $LOG_SCRIPT_AGENT $func_name $AGENT_ID
        write_log $LOG_LEVEL_INFO $message

        write_agent_status $message 'Red'
        write_agent_info
        write_agent_support
        return
    fi
    if $IS_AGENT_COMPLETED; then
        local message='Agent Completed Successfully'
        send_log_to_logzio $LOG_LEVEL_INFO $message $LOG_STEP_FINAL $LOG_SCRIPT_AGENT $func_name $AGENT_ID
        write_log $LOG_LEVEL_INFO $message

        write_agent_status $message 'Green'
        write_agent_info
        write_agent_support
        return
    fi
}

# Prints agent interruption message
# Input:
#   ---
# Output:
#   Agent interruption message
function write_agent_interruption_message {
    trap SIGINT
    local message='Agent Stopped By User'
    
    if [[ $(type -t send_log_to_logzio) == function ]]; then
        send_log_to_logzio $LOG_LEVEL_INFO $message $LOG_STEP_FINAL $LOG_SCRIPT_AGENT $func_name $AGENT_ID
    fi

    write_agent_status $message 'Yellow'
}

# Prints agent status
# Input:
#   ---
# Ouput:
#   Agent status
function write_agent_status {
    local $message=$1
    local $color=$2

    echo
    echo

    local repeat=5
    while [[ $repeat -ne 0 ]]; do
        if [[ $((repeat%2)) -eq 0 ]]; then
            echo -e "\r##### $message #####"
        else
            echo -e "\r$color##### $message #####$WHITE_COLOR"
        fi

        sleep 250
        ((repeat--))
    done

    echo
    echo
}

function write_agent_info {
    source "$LOGZIO_TEMP_DIR/$PLATFORM/$SUB_TYPE/$AGENT_INFO_FILE" 2>$TASK_ERROR_FILE
    if [[ $? -ne 0 ]]; then
        local message="failed to print agent info: $(get_task_error_message)"
        write_warning $message
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


# Agent version
AGENT_VERSION='v1.0.29'

# Settings
tput civis -- invisible

# Agent args
AGENT_ARGS="$@"

# Agent status flags
IS_SHOW_HELP=false
IS_LOADING_AGENT_SCRIPTS_FAILED=false
IS_REMOVE_LAST_RUN_ANSWER_NO=false
IS_AGENT_FAILED=false
IS_POSTREQUISITE_FAILED=false
IS_AGENT_COMPLETED=false

# Print main title
echo -e "\033[0;36m
    LLLLLLLLLLL                                                                             iiii                   
    L:::::::::L                                                                            i::::i                  
    L:::::::::L                                                                             iiii                   
    LL:::::::LL                                                                                                    
      L:::::L                  ooooooooooo      ggggggggg   gggggzzzzzzzzzzzzzzzzz        iiiiiii    ooooooooooo   
      L:::::L                oo:::::::::::oo   g:::::::::ggg::::gz:::::::::::::::z        i:::::i  oo:::::::::::oo 
      L:::::L               o:::::::::::::::o g:::::::::::::::::gz::::::::::::::z          i::::i o:::::::::::::::o
      L:::::L               o:::::ooooo:::::og::::::ggggg::::::ggzzzzzzzz::::::z           i::::i o:::::ooooo:::::o
      L:::::L               o::::o     o::::og:::::g     g:::::g       z::::::z            i::::i o::::o     o::::o
      L:::::L               o::::o     o::::og:::::g     g:::::g      z::::::z             i::::i o::::o     o::::o
      L:::::L               o::::o     o::::og:::::g     g:::::g     z::::::z              i::::i o::::o     o::::o
      L:::::L         LLLLLLo::::o     o::::og::::::g    g:::::g    z::::::z               i::::i o::::o     o::::o
    LL:::::::LLLLLLLLL:::::Lo:::::ooooo:::::og:::::::ggggg:::::g   z::::::zzzzzzzz        i::::::io:::::ooooo:::::o
    L::::::::::::::::::::::Lo:::::::::::::::o g::::::::::::::::g  z::::::::::::::z ...... i::::::io:::::::::::::::o
    L::::::::::::::::::::::L oo:::::::::::oo   gg::::::::::::::g z:::::::::::::::z .::::. i::::::i oo:::::::::::oo 
    LLLLLLLLLLLLLLLLLLLLLLLL   ooooooooooo       gggggggg::::::g zzzzzzzzzzzzzzzzz ...... iiiiiiii   ooooooooooo   
                                                         g:::::g                                                   
                                             gggggg      g:::::g                                                   
                                             g:::::gg   gg:::::g               Agent $AGENT_VERSION                                   
                                              g::::::ggg:::::::g                                                   
                                               gg:::::::::::::g                                                    
                                                 ggg::::::ggg                                                      
                                                    gggggg                                                          
\033[0;37m"
echo

# Load consts
source /tmp/logzio/consts.bash 2>/tmp/logzio/task_error.txt
if [[ $? -ne 0 ]]; then
    IS_LOADING_AGENT_SCRIPTS_FAILED=true
    echo -e "\033[0;31magent.ps1 (1): error loading agent scripts: $(cat /tmp/logzio/task_error.txt)\033[0;37m"

    exit 1
fi
# Load agent functions
source /tmp/logzio/functions.bash 2>/tmp/logzio/task_error.txt
if [[ $? -ne 0 ]]; then
    IS_LOADING_AGENT_SCRIPTS_FAILED=true
    echo -e "\033[0;31magent.ps1 (1): error loading agent scripts: $(cat /tmp/logzio/task_error.txt)\033[0;37m"

    exit 1
fi
# Load agent utils functions
source /tmp/logzio/utils_functions.bash 2>/tmp/logzio/task_error.txt
if [[ $? -ne 0 ]]; then
    IS_LOADING_AGENT_SCRIPTS_FAILED=true
    echo -e "${RED_COLOR}agent.bash (1): error loading agent scripts: $(cat /tmp/logzio/task_error.txt)$WHITE_COLOR"

    exit 1
fi

# Clears content of task post run script file if exists (happens if Logz.io temp directory was not deleted)
if [[ -f $TASK_POST_RUN_FILE ]]; then
    >$TASK_POST_RUN_FILE
fi

# Write agent running log
write_log $LOG_LEVEL_INFO 'Start running Logz.io agent ...'

# Print title
echo -e '##########################'
echo -e "###$PURPLE_COLOR Pre-Initialization $WHITE_COLOR###"
echo -e '##########################'

# Get Linux info
execute_task 'get_linux_info' 'Getting Linux info'
# Check if script was run as root
execute_task 'check_is_elevated' 'Checking if script was run as root'
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




# # Run last preparations
# echo -e "\nlast preparations:"
# execute_task "get_app_json" "getting application JSON"                                          # Get app JSON
# execute_task "build_repo_path" "building path to logzio-agent-manifest repo"                    # Build repo path to logzio-agent-manifest repo
# execute_task "get_prerequisites_scripts" "getting prerequisites scripts"                        # Get prerequisites scripts
# execute_task "get_installer_scripts" "getting installer scripts"                                # Get installer scripts

# # Run prerequisites script
# write_log "INFO" "Running prerequisites script ..."
# echo -e "\nprerequisites:"
# source $logzio_temp_dir/prerequisites.bash

# # Run installer script
# write_log "INFO" "Running installer script ..."
# echo -e "\ninstaller:"
# source $logzio_temp_dir/installer.bash

# # Delete temp directory
# delete_temp_dir
