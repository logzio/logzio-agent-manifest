#!/bin/bash

#################################################################################################################################
###################################################### LINUX Agent Functions ####################################################
#################################################################################################################################

# Gets Linux info
# Input:
#   ---
# Output:
#   LINUX_NAME - Linux name
#   LINUX_VERSION - Linux version
#   CPU_ARCH - Linux cpu architecture
function get_linux_info {
    local exit_code=2
    local func_name="${FUNCNAME[0]}"

    local message='Getting Linux info ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local linux_info=$(cat /etc/os-release 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error getting Linux info: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    local linux_name=$(echo -e "$linux_info" | grep -oP '(?<=^NAME=").*?(?=")')
    write_task_post_run "LINUX_NAME=\"$linux_name\""

    message="Linux name is '$linux_name'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local linux_version=$(echo -e "$linux_info" | grep -oP '(?<=^VERSION=").*?(?=")')
    write_task_post_run "LINUX_VERSION=\"$linux_version\""

    message="Linux version is '$linux_version'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local cpu_arch=$(uname -p 2>"$TASK_ERROR_FILE")
    if [[ $? -ne 0 ]]; then
        message="agent.bash ($exit_code): error getting cpu arch: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
    
    message="CPU architecture is '$cpu_arch'"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "CPU_ARCH=\"$cpu_arch\""
}

# Checks if script was run as root
# Input:
#   ---
# Output:
#   ---
function check_is_elevated {
    local exit_code=3
    local func_name="${FUNCNAME[0]}"

    local message='Checking if script was run as root ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local id=$(id -u)
    if [[ $id -eq 0 ]]; then
        return
    fi

    message="agent.bash ($exit_code): agent script was not run as root. please rerun the agent script with 'sudo' command"
    send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_task_post_run "write_error \"$message\""

    return $exit_code
}

# Prints usage
# Input:
#   ---
# Output:
#   Help usage
function show_help {
    write_task_post_run "echo -e \"Usage: .\agent.bash --url=<logzio_app_url> --id=<agent_id> [--debug=<agent_json>] [--release<repo_release>]\""
    write_task_post_run "echo -e ' --url=<logzio_app_url>       Logz.io app URL (https://app.logz.io)'"
    write_task_post_run "echo -e ' --id=<agent_id>              Logz.io agent ID'"
    write_task_post_run "echo -e ' --debug=<agent_json>         Debug run using a local agent json file'"
    write_task_post_run "echo -e ' --release=<repo_release>     The release of Logz.io repo. Default is latest release'"
    write_task_post_run "echo -e ' --help                       Show usage'"
}

# Gets arguments
# Input:
#   func_args - Dictionary (agent_args = $@)
# Output:
#   app_url - Logz.io app url
#   agent_id - Logz.io agent id
#   agent_json_file - Agent json file path (for debug)
#   repo_release - Repo release (for debug)
function get_arguments {
    local func_args=$1

    echo -e "${#func_args}" > ./args.txt

    local exit_code=4
    local func_name="${FUNCNAME[0]}"

    local message='Getting arguments ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INIT" "$LOG_SCRIPT_AGENT" "$func_name"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    #local err=$(are_func_args_exist $func_args ('AgentArgs'))
    # if ($Err.Count -ne 0) {
    #     $Message = "agent.ps1 ($ExitCode): $($Err[0])"
    #     Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
    #     Write-TaskPostRun "Write-Error `"$Message`""

    #     return $ExitCode
    # }

    # $local:AgentArgs = $FuncArgs.AgentArgs

    # foreach ($Arg in $AgentArgs) {
    #     switch -Regex ($Arg) {
    #         --help {
    #             Show-Help
    #             Write-TaskPostRun "`$script:IsShowHelp = `$true"

    #             return
    #         }
    #         --url=* {
    #             $local:AppUrl = $Arg.Split('=', 2)[1]
    #             if ([string]::IsNullOrEmpty($AppUrl)) {
    #                 $Message = "agent.ps1 ($ExitCode): no Logz.io app URL specified!"
    #                 Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
    #                 Write-TaskPostRun "Write-Error `"$Message`""

    #                 return $ExitCode
    #             }
                
    #             $Message = "Agent argument 'url' is '$AppUrl'"
    #             Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
    #             Write-Log $script:LogLevelDebug $Message

    #             Write-TaskPostRun "`$script:AppUrl = '$AppUrl'"
    #             continue
    #         }
    #         --id=* {
    #             $local:AgentId = $Arg.Split('=', 2)[1]
    #             if ([string]::IsNullOrEmpty($AgentId)) {
    #                 $Message = "agent.ps1 ($ExitCode): no agent ID specified!"
    #                 Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
    #                 Write-TaskPostRun "Write-Error `"$Message`""

    #                 return $ExitCode
    #             }
                
    #             $Message = "Agent argument 'id' is '$AgentId'"
    #             Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
    #             Write-Log $script:LogLevelDebug $Message

    #             Write-TaskPostRun "`$script:AgentId = '$AgentId'"
    #             continue
    #         }
    #         --debug=* {
    #             $local:AgentJsonFile = $Arg.Split('=', 2)[1]
    #             if ([string]::IsNullOrEmpty($AgentJsonFile)) {
    #                 $Message = "agent.ps1 ($ExitCode): no json file specified!"
    #                 Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
    #                 Write-TaskPostRun "Write-Error `"$Message`""

    #                 return $ExitCode
    #             }

    #             $Message = "Agent argument 'debug' is '$AgentJsonFile'"
    #             Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
    #             Write-Log $script:LogLevelDebug $Message

    #             Write-TaskPostRun "`$script:AgentJsonFile = '$AgentJsonFile'"
    #             continue
    #         }
    #         --release=* {
    #             $local:RepoRelease = $Arg.Split('=', 2)[1]

    #             $Message = "Agent argument 'release' is '$RepoRelease'"
    #             Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
    #             Write-Log $script:LogLevelDebug $Message

    #             Write-TaskPostRun "`$script:RepoRelease = '$RepoRelease'"
    #             continue
    #         }
    #         default {
    #             $Message = "agent.ps1 ($ExitCode): unrecognized flag"
    #             Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
    #             Write-TaskPostRun "Write-Error `"$Message`""
    #             $Message = "agent.ps1 ($ExitCode): try running the agent with '--help' flag for more information"
    #             Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
    #             Write-TaskPostRun "Write-Error `"$Message`""

    #             return $ExitCode
    #         }
    #     }
    # }
}

# # Checks validation of the arguments
# # Input:
# #   FuncArgs - Hashtable {AppUrl = $script:AppUrl; AgentId = $script:AgentId; AgentJsonFile = $script:AgentJsonFile}
# # Output:
# #   ---
# function Test-ArgumentsValidation {
#     param (
#         [hashtable]$FuncArgs
#     )

#     $local:ExitCode = 5
#     $local:FuncName = $MyInvocation.MyCommand.Name

#     $local:Message = 'Checking validation ...'
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
#     Write-Log $script:LogLevelDebug $Message

#     $local:Err = Test-AreFuncArgsExist $FuncArgs @('AppUrl', 'AgentId', 'AgentJsonFile')
#     if ($Err.Count -ne 0) {
#         $Message = "agent.ps1 ($ExitCode): $($Err[0])"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
#         Write-TaskPostRun "Write-Error `"$Message`""

#         return $ExitCode
#     }

#     $local:AppUrl = $FuncArgs.AppUrl
#     $local:AgentId = $FuncArgs.AgentId
#     $local:AgentJsonFile = $FuncArgs.AgentJsonFile

#     if (-Not [string]::IsNullOrEmpty($AgentJsonFile)) {
#         if (Test-Path -Path $AgentJsonFile -PathType Leaf) {
#             return
#         }

#         $Message = "agent.ps1 ($ExitCode): the json file '$AgentJsonFile' does not exist"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
#         Write-TaskPostRun "Write-Error `"$Message`""

#         return $ExitCode
#     }

#     $local:IsError = $false

#     if ([string]::IsNullOrEmpty($AppUrl)) {
#         $IsError = $true
#         $Message = "agent.ps1 ($ExitCode): Logz.io app url must be specified"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
#         Write-TaskPostRun "Write-Error `"$Message`""
#     }
#     if ([string]::IsNullOrEmpty($AgentId)) {
#         $IsError = $true
#         $Message = "agent.ps1 ($ExitCode): agent id must be specified"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
#         Write-TaskPostRun "Write-Error `"$Message`""
#     }

#     if (-Not $IsError) {
#         return
#     }

#     $Message = "agent.ps1 ($ExitCode): try running the agent with '--help' flag for more information"
#     Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
#     Write-TaskPostRun "Write-Error `"$Message`""

#     return $ExitCode
# }

# # Sets agent id const
# # Input:
# #   FuncArgs - Hashtable {AgentId = $script:AgentId}
# # Output:
# #   AgentId - Agent id
# function Set-AgentIdConst {
#     param (
#         [hashtable]$FuncArgs
#     )

#     $local:ExitCode = 6
#     $local:FuncName = $MyInvocation.MyCommand.Name

#     $local:Message = 'Setting agent id const ...'
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
#     Write-Log $script:LogLevelDebug $Message

#     $local:Err = Test-AreFuncArgsExist $FuncArgs @('AgentId')
#     if ($Err.Count -ne 0) {
#         $Message = "agent.ps1 ($ExitCode): $($Err[0])"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
#         Write-TaskPostRun "Write-Error `"$Message`""

#         return $ExitCode
#     }

#     $local:AgentId = $FuncArgs.AgentId

#     if ([string]::IsNullOrEmpty($AgentId)) {
#         $AgentId = 'Debug'
#     }

#     $local:Message = "Agent id is '$AgentId'"
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName
#     Write-Log $LogLevelDebug $Message

#     $local:Command = "`$script:AgentId = '$AgentId'"
#     Write-TaskPostRun $Command
#     $Command | Out-File -FilePath $script:ConstsFile -Append -Encoding utf8
# }

# # Downloads jq
# # Input:
# #   ---
# # Output:
# #   Jq exe file in Logz.io temp directory
# function Get-JQ {
#     $local:ExitCode = 7
#     $local:FuncName = $MyInvocation.MyCommand.Name

#     $local:Message = 'Downloading jq ...'
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepDownloads $script:LogScriptAgent $FuncName $script:AgentId
#     Write-Log $script:LogLevelDebug $Message

#     try {
#         Invoke-WebRequest -Uri $script:JqUrlDownload -OutFile $script:JqExe | Out-Null
#     }
#     catch {
#         $Message = "error downloading jq exe: $_"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepDownloads $script:LogScriptAgent $FuncName $script:AgentId
#         Write-TaskPostRun "Write-Error `"$Message`""

#         return $ExitCode
#     }
# }

# # Downloads yq
# # Input:
# #   ---
# # Output:
# #   Yq exe file in Logz.io temp directory
# function Get-Yq {
#     $local:ExitCode = 8
#     $local:FuncName = $MyInvocation.MyCommand.Name

#     $local:Message = 'Downloading yq ...'
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepDownloads $script:LogScriptAgent $FuncName $script:AgentId
#     Write-Log $script:LogLevelDebug $Message

#     try {
#         Invoke-WebRequest -Uri $script:YqUrlDownload -OutFile $script:YqExe | Out-Null
#     }
#     catch {
#         $Message = "error downloading yq exe: $_"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepDownloads $script:LogScriptAgent $FuncName $script:AgentId
#         Write-TaskPostRun "Write-Error `"$Message`""

#         return $ExitCode
#     }
# }

# # Gets the agent json from the agent or local file
# # Input:
# #   FuncArgs - Hashtable {AppUrl = $script:AppUrl; AgentJsonFile = $script:AgentJsonFile}
# # Output:
# #   Agent json file in Logz.io temp directory
# function Get-AgentJson {
#     param (
#         [hashtable]$FuncArgs
#     )

#     $local:ExitCode = 9
#     $local:FuncName = $MyInvocation.MyCommand.Name

#     $local:Message = 'Getting agent json ...'
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#     Write-Log $script:LogLevelDebug $Message

#     $local:Err = Test-AreFuncArgsExist $FuncArgs @('AppUrl', 'AgentJsonFile')
#     if ($Err.Count -ne 0) {
#         $Message = "agent.ps1 ($ExitCode): $(Err[0])"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#         Write-TaskPostRun "Write-Error `"$Message`""
#     }

#     $local:AppUrl = $FuncArgs.AppUrl
#     $local:AgentJsonFile = $FuncArgs.AgentJsonFile

#     if (-Not [string]::IsNullOrEmpty($AgentJsonFile)) {
#         # Using local app json file
#         $Message = 'Using local agent json file ...'
#         Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#         Write-Log $script:LogLevelDebug $Message

#         try {
#             Copy-Item -Path $AgentJsonFile -Destination $script:AgentJson -ErrorAction Stop
#         }
#         catch {
#             $Message = "agent.ps1 ($ExitCode): error copying '$AgentJsonFile' to '$script:AgentJson': $_"
#             Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#             Write-TaskPostRun "Write-Error `"$Message`""

#             return $ExitCode
#         }

#         return
#     }

#     # Getting agent json from agent
#     $Message = 'Getting agent json from agent ...'
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#     Write-Log $LogLevelDebug $Message

#     try {
#         Invoke-WebRequest -Uri "$AppUrl/telemetry-agent/public/agents/configuration/$script:AgentID" -OutFile $script:AgentJson | Out-Null
#     }
#     catch {
#         $Message = "agent.ps1 ($ExitCode): error getting Logz.io agent json from agent. make sure your url is valid: $_"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#         Write-TaskPostRun "Write-Error `"$Message`""

#         return $ExitCode
#     }

#     $local:Err = Get-JsonFileFieldValue $script:AgentJson '.statusCode'
#     if ($Err.Count -ne 0 -and $Err[1] -eq 1) {
#         $Message = "agent.ps1 ($ExitCode): $($Err[0])"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#         Write-TaskPostRun "Write-Error `"$Message`""

#         return $ExitCode
#     }
#     if ($Err.Count -ne 0 -and $Err[1] -eq 3) {
#         return
#     }

#     $local:StatusCode = $script:JsonValue

#     $Message = "agent.ps1 ($ExitCode): error getting Logz.io agent json from agent (statusCode '$StatusCode'). make sure your id is valid."
#     Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#     Write-TaskPostRun "Write-Error `"$Message`""

#     return $ExitCode
# }

# # Sets agent json consts
# # input:
# #   ---
# # Output:
# #   Platform - Platfrom name
# #   SubType - Subtype name
# #   DataSourceNames - List of datasource names
# function Set-AgentJsonConsts {
#     $local:ExitCode = 10
#     $local:FuncName = $MyInvocation.MyCommand.Name

#     $local:Message = 'Setting agent json consts ...'
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#     Write-Log $script:LogLevelDebug $Message
    
#     $local:Err = Get-JsonFileFieldValue $script:AgentJson '.configuration.name'
#     if ($Err.Count -ne 0) {
#         $Message = "agent.ps1 ($ExitCode): $($Err[0])"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#         Write-TaskPostRun "Write-Error `"$Message`""

#         return $ExitCode
#     }

#     $local:Platform = $script:JsonValue

#     $Message = "Platform is '$Platform'"
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#     Write-Log $script:LogLevelDebug $Message

#     $local:Command = "`$script:Platform = '$Platform'"
#     Write-TaskPostRun $Command
#     $Command | Out-File -FilePath $script:ConstsFile -Append -Encoding utf8

#     $Err = Get-JsonFileFieldValue $script:AgentJson '.configuration.subtypes[0].name'
#     if ($Err.Count -ne 0) {
#         $Message = "agent.ps1 ($ExitCode): $($Err[0])"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#         Write-TaskPostRun "Write-Error `"$Message`""

#         return $ExitCode
#     }
    
#     $local:SubType = $script:JsonValue

#     $Message = "Subtype is '$SubType'"
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#     Write-Log $script:LogLevelDebug $Message

#     $Command = "`$script:SubType = '$SubType'"
#     Write-TaskPostRun $Command
#     $Command | Out-File -FilePath $script:ConstsFile -Append -Encoding utf8
    
#     $local:Err = Get-JsonFileFieldValueList $script:AgentJson '.configuration.subtypes[0].datasources[]'
#     if ($Err.Count -ne 0) {
#         $Message = "agent.ps1 ($ExitCode): $($Err[0])"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#         Write-TaskPostRun "Write-Error `"$Message`""

#         return $ExitCode
#     }

#     $local:DataSources = $script:JsonValue

#     $local:Index = 0
#     $local:DataSourceNames = @()
#     foreach ($DataSource in $DataSources) {
#         $Err = Get-JsonStrFieldValue $Datasource '.name'
#         if ($Err.Count -ne 0) {
#             $Message = "agent.ps1 ($ExitCode): $($Err[0])"
#             Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#             Write-TaskPostRun "Write-Error `"$Message`""
    
#             return $ExitCode
#         }
        
#         $local:DataSourceName = $script:JsonValue

#         $Message = "DataSource #$($Index+1) is '$DataSourceName'"
#         Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
#         Write-Log $script:LogLevelDebug $Message

#         $DataSourceNames += $DataSourceName
#         $Index++
#     }

#     $local:DataSourcesStr = Convert-ListToStr $DataSourceNames

#     $Command = "`$script:DataSources = $DataSourcesStr"
#     Write-TaskPostRun $Command
#     $Command | Out-File -FilePath $script:ConstsFile -Append -Encoding utf8
# }

# # Gets Logz.io listener url
# # Input:
# #   ---
# # Ouput:
# #   ListenerUrl - Logz.io listener url
# function Get-LogzioListenerUrl {
#     $local:ExitCode = 11
#     $local:FuncName = $MyInvocation.MyCommand.Name

#     $local:Message = 'Getting Logz.io listener url ...'
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
#     Write-Log $script:LogLevelDebug $Message

#     $local:Err = Get-JsonFileFieldValue $script:AgentJson '.listenerUrl'
#     if ($Err.Count -ne 0) {
#         $Message = "agent.ps1 ($ExitCode): $($Err[0])"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
#         Write-TaskPostRun "Write-Error `"$Message`""

#         return $ExitCode
#     }

#     $local:ListenerUrl = $script:JsonValue

#     $Message = "Logz.io listener url is '$ListenerUrl'"
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
#     Write-Log $script:LogLevelDebug $Message

#     Write-TaskPostRun "`$script:ListenerUrl = '$ListenerUrl'"
# }

# # Downloads subtype files
# # Input:
# #   FuncArgs - Hashtable {RepoRelease = $RepoRelease}
# # Output:
# #   Subtype files in Logz.io temp directory
# function Get-SubTypeFiles {
#     param (
#         [hashtable]$FuncArgs
#     )

#     $local:ExitCode = 12
#     $local:FuncName = $MyInvocation.MyCommand.Name

#     $local:Message = 'Donwloading subtype files ...'
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
#     Write-Log $script:LogLevelDebug $Message

#     $local:Err = Test-AreFuncArgsExist $FuncArgs @('RepoRelease')
#     if ($Err.Count -ne 0) {
#         $Message = "agent.ps1 ($ExitCode): $($Err[0])"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
#         Write-TaskPostRun "Write-Error `"$Message`""

#         return $ExitCode
#     }

#     $local:RepoRelease = $FuncArgs.RepoRelease

#     try {
#         if ([string]::IsNullOrEmpty($RepoRelease)) {
#             Invoke-WebRequest -Uri "https://github.com/logzio/logzio-agent-manifest/releases/latest/download/windows_$($script:Platform.ToLower())_$($script:SubType.ToLower()).tar.gz" -OutFile $script:LogzioTempDir\windows_$($script:Platform.ToLower())_$($script:SubType.ToLower()).tar.gz | Out-Null
#         }
#         else {
#             Invoke-WebRequest -Uri "https://github.com/logzio/logzio-agent-manifest/releases/download/$RepoRelease/windows_$($script:Platform.ToLower())_$($script:SubType.ToLower()).tar.gz" -OutFile $script:LogzioTempDir\windows_$($script:Platform.ToLower())_$($script:SubType.ToLower()).tar.gz | Out-Null
#         }
#     }
#     catch {
#         $Message = "agent.ps1 ($ExitCode): error downloading subtype tar.gz file from Logz.io repo: $_"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
#         Write-TaskPostRun "Write-Error `"$Message`""

#         return $ExitCode
#     }
    
#     tar -zxf $script:LogzioTempDir\windows_$script:Platform`_$script:SubType.tar.gz --directory $script:LogzioTempDir 2>$script:TaskErrorFile | Out-Null
#     if ($LASTEXITCODE -eq 0) {
#         return
#     }

#     $Message = "agent.ps1 ($ExitCode): error extracting files from tar.gz: $(Get-TaskErrorMessage)"
#     Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
#     Write-TaskPostRun "Write-Error `"$Message`""

#     return $ExitCode
# }

# # Runs subtype prerequisites
# # Input:
# #   ---
# # Output:
# #   ---
# function Invoke-SubTypePrerequisites {
#     $local:ExitCode = 13
#     $local:FuncName = $MyInvocation.MyCommand.Name

#     $local:Message = 'Running subtype prerequisites ...'
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
#     Write-Log $LogLevelDebug $Message

#     try {
#         . "$script:LogzioTempDir\$script:Platform\$script:SubType\$script:PrerequisitesFile" -ErrorAction Stop
#         if ($LASTEXITCODE -ne 0) {
#             Exit $LASTEXITCODE
#         }
#     }
#     catch {
#         $Message = "agent.ps1 ($ExitCode): error running subtype prerequisites: $_"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
#         Write-Error $Message

#         $script:IsAgentFailed = $true
#         Exit $ExitCode
#     }
# }

# # Runs subtype installer
# # Input:
# #   ---
# # Output:
# #   ---
# function Invoke-SubTypeInstaller {
#     $local:ExitCode = 14
#     $local:FuncName = $MyInvocation.MyCommand.Name

#     $local:Message = 'Running subtype installer ...'
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
#     Write-Log $script:LogLevelDebug $Message

#     try {
#         . "$script:LogzioTempDir\$script:Platform\$script:SubType\$script:InstallerFile" -ErrorAction Stop
#         if ($LASTEXITCODE -ne 0) {
#             Exit $LASTEXITCODE
#         }
#     }
#     catch {
#         $Message = "agent.ps1 ($ExitCode): error running subtype installer: $_"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
#         Write-Error $Message

#         $script:IsAgentFailed = $true
#         Exit $ExitCode
#     }
# }

# # Runs subtype post-requisites
# # Input:
# #   ---
# # Output:
# #   ---
# function Invoke-SubTypePostrequisites {
#     $local:ExitCode = 15
#     $local:FuncName = $MyInvocation.MyCommand.Name

#     $local:Message = 'Running subtype post-requisites ...'
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
#     Write-Log $script:LogLevelDebug $Message

#     try {
#         . "$script:LogzioTempDir\$script:Platform\$script:SubType\$script:PostrequisitesFile" -ErrorAction Stop
#         if ($LASTEXITCODE -ne 0) {
#             Exit $LASTEXITCODE
#         }
#     }
#     catch {
#         $Message = "agent.ps1 ($ExitCode): error running subtype post-requisites: $_"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
#         Write-Error $Message

#         $script:IsAgentFailed = $true
#         Exit $ExitCode
#     }
# }






























# # Installs jq
# # Error:
# #   Exit Code 3
# function install_jq () {
#     write_log "INFO" "Installing jq ..."

#     jq_bin="$logzio_temp_dir/jq"
#     curl -fsSL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 > $jq_bin 2>$task_error_file
#     if [[ $? -ne 0 ]]; then
#         local err=$(cat $task_error_file)
#         write_run "print_error \"agent.bash (3): failed to get jq binary file from Github.\n  $err\""
#         return 3
#     fi

#     chmod +x $jq_bin
#     write_run "jq_bin=\"$jq_bin\""
# }

# # Gets the application JSON from the agent/local file into logzio-temp directory
# # Error:
# #   Exit Code 4
# function get_app_json () {
#     write_log "INFO" "Getting application JSON ..."

#     if [[ ! -z "$app_json_file" ]]; then
#         # Using local app JSON file
#         write_log "INFO" "Using local application JSON file ..."
#         cp $app_json_file $app_json
#         return
#     fi

#     # Getting app JSON from agent
#     write_log "INFO" "Getting application JSON from agent ..."
#     curl -fsSL $app_url/telemetry-agent/public/agents/configuration/$agent_id > $app_json 2>$task_error_file
#     if [[ $? -ne 0 ]]; then
#         local err=$(cat $task_error_file)
#         write_run "print_error \"agent.bash (4): failed to get Logz.io application JSON from agent. make sure your URL is valid.\n  $err\""
#         return 4
#     fi

#     local status_code=$($jq_bin -r '.statusCode' $app_json)
#     if [[ "$status_code" = null ]]; then
#         return
#     fi

#     write_run "print_error \"agent.bash (4): failed to get Logz.io application JSON from agent (statusCode $status_code). make sure your ID is valid\""
#     return 4
# }

# # Builds path to logzio-agent-manifest repo according the app JSON
# # Output:
# #   repo_path - Path to logzio-agent-manifest repo according the app JSON
# # Error:
# #   Exit Code 5
# function build_repo_path () {
#     write_log "INFO" "Building repo path ..."
    
#     local dir1=$($jq_bin -r '.configuration.name' $app_json)
#     if [[ "$dir1" = null ]]; then
#         write_run "print_error \"agent.bash (5): '.configuration.name' was not found in application JSON\""
#         return 5
#     fi
#     if [[ -z "$dir1" ]]; then
#         write_run "print_error \"agent.bash (5): '.configuration.name' is empty in application JSON\""
#         return 5
#     fi

#     local dir2=$($jq_bin -r '.configuration.subtypes[0].name' $app_json)
#     if [[ "$dir2" = null ]]; then
#         write_run "print_error \"agent.bash (5): '.configuration.subtypes[0].name' was not found in application JSON\""
#         return 5
#     fi
#     if [[ -z "$dir2" ]]; then
#         write_run "print_error \"agent.bash (5): '.configuration.subtypes[0].name' is empty in application JSON\""
#         return 5
#     fi

#     local dir3=$($jq_bin -r '.configuration.subtypes[0].datasources[0].name' $app_json)
#     if [[ "$dir3" = null ]]; then
#         write_run "print_error \"agent.bash (5): '.configuration.subtypes[0].datasources[0].name' was not found in application JSON\""
#         return 5
#     fi
#     if [[ -z "$dir3" ]]; then
#         write_run "print_error \"agent.bash (5): '.configuration.subtypes[0].datasources[0].name' is empty in application JSON\""
#         return 5
#     fi

#     local repo_path="$repo_url/$dir1/$dir2/$dir3"
#     write_log "INFO" "repo_path = $repo_path"
#     write_run "repo_path=\"$repo_path\""
# }

# # Gets prerequisites scripts from logzio-agent-manifest repo to logzio-temp directory
# # Error:
# #   Exit Code 6
# function get_prerequisites_scripts () {
#     write_log "INFO" "Getting prerequisites script file from logzio-agent-manifest repo ..."
#     curl -fsSL $repo_path/prerequisites/linux/prerequisites.bash > $logzio_temp_dir/prerequisites.bash 2>$task_error_file
#     if [[ $? -ne 0 ]]; then
#         local err=$(cat $task_error_file)
#         write_run "print_error \"agent.bash (6): failed to get prerequisites script file from logzio-agent-manifest repo.\n  $err\""
#         return 6
#     fi

#     write_log "INFO" "Getting prerequisites functions script file from logzio-agent-manifest repo ..."
#     curl -fsSL $repo_path/prerequisites/linux/functions.bash > $logzio_temp_dir/prerequisites_functions.bash 2>$task_error_file
#     if [[ $? -ne 0 ]]; then
#         local err=$(cat $task_error_file)
#         write_run "print_error \"agent.bash (6): failed to get prerequisites functions script file from logzio-agent-manifest repo.\n  $err\""
#         return 6
#     fi
# }

# # Gets installer scripts from logzio-agent-manifest repo to logzio-temp directory
# # Error:
# #   Exit Code 7
# function get_installer_scripts () {
#     write_log "INFO" "Getting installer script file from logzio-agent-manifest repo ..."
#     curl -fsSL $repo_path/telemetry/installer/linux/installer.bash > $logzio_temp_dir/installer.bash 2>$task_error_file
#     if [[ $? -ne 0 ]]; then
#         local err=$(cat $task_error_file)
#         write_run "print_error \"agent.bash (7): failed to get installer script file from logzio-agent-manifest repo.\n  $err\""
#         return 7
#     fi

#     write_log "INFO" "Getting installer functions script file from logzio-agent-manifest repo ..."
#     curl -fsSL $repo_path/telemetry/installer/linux/functions.bash > $logzio_temp_dir/installer_functions.bash 2>$task_error_file
#     if [[ $? -ne 0 ]]; then
#         local err=$(cat $task_error_file)
#         write_run "print_error \"agent.bash (7): failed to get installer functions script file from logzio-agent-manifest repo.\n  $err\""
#         return 7
#     fi
# }
