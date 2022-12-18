#!/bin/bash

#################################################################################################################################
############################################## LINUX Subtype Installer Functions ################################################
#################################################################################################################################

# Checks if Logz.io OTEL collector service exists
# Input:
#   ---
# Output:
#   IS_SERVICE_EXISTS - Tells if Logz.io OTEL collector service exists (true/false)
function is_logzio_otel_collector_service_exists {
    local func_name="${FUNCNAME[0]}"

    local message='Checking if Logz.io OTEL collector service exists ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    local service=$(systemctl | grep "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME")
    if [[ -z $service ]]; then
        message="'$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME' service does not exist"
        send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_log "$LOG_LEVEL_DEBUG" "$message"

        write_task_post_run "IS_SERVICE_EXISTS=false"
        return
    fi

    message="'$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME' service is already exists"
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    write_task_post_run "IS_SERVICE_EXISTS=true"
}

# Removes Logz.io OTEL collector service
# Input:
#   ---
# Output:
#   ---
function remove_logzio_otel_collector_service {
    local exit_code=1
    local func_name="${FUNCNAME[0]}"

    local message='Removing Logz.io OTEL collector service ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    systemctl stop "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error stopping '$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME' service: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    systemctl disable "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error disabling '$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME' service: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    rm "/etc/systemd/system/$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME.service" 2>/dev/null
    rm "/usr/lib/systemd/system/$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME.service" 2>/dev/null
    rm "/etc/init.d/$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 2>/dev/null

    systemctl daemon-reload 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error reloading the systemd manager configuration: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    systemctl reset-failed "$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error reseting the 'failed' state of unit '$LOGZIO_OTEL_COLLECTOR_SERVICE_NAME.service': $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Downloads OTEL collector binary
# Input:
#   ---
# Output:
#   OTEL collector exe in Logz.io temp directory
function download_otel_collector_binary {
    local exit_code=1
    local func_name="${FUNCNAME[0]}"

    local message='Downloading OTEL collector binary ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    curl -fsSL "$OTEL_COLLECTOR_URL_DOWNLOAD" >"$LOGZIO_TEMP_DIR/otelcol-logzio.tar.gz" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error downloading otelcol-logzio.tar.gz: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi

    tar -zxf "$LOGZIO_TEMP_DIR/otelcol-logzio.tar.gz" --directory "$LOGZIO_TEMP_DIR" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error extracting files from otelcol-logzio.tar.gz: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# Creates Logz.io AppData subdirectory
# Input:
#   ---
# Output:
#   ---
function create_logzio_opt_sub_dir {
    local exit_code=3
    local func_name="${FUNCNAME[0]}"

    local message='Creating Logz.io AppData subdirectory ...'
    send_log_to_logzio "$LOG_LEVEL_DEBUG" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
    write_log "$LOG_LEVEL_DEBUG" "$message"

    mkdir "$LOGZIO_OTEL_COLLECTOR_DIR" 2>"$TASK_ERROR_FILE"
    if [[ $? -ne 0 ]]; then
        message="installer.bash ($exit_code): error creating '$LOGZIO_OTEL_COLLECTOR_DIR' directory: $(get_task_error_message)"
        send_log_to_logzio "$LOG_LEVEL_ERROR" "$message" "$LOG_STEP_PRE_INSTALLATION" "$LOG_SCRIPT_INSTALLER" "$func_name" "$AGENT_ID" "$PLATFORM" "$SUB_TYPE"
        write_task_post_run "write_error \"$message\""

        return $exit_code
    fi
}

# # Copies OTEL files to AppData subdirectory
# # Input:
# #   ---
# # Output:
# #   ---
# function Copy-LogzioOtelFilesToAppDataSubDir {
#     local exit_code=5
#     local func_name="${FUNCNAME[0]}"

#     $local:Message = 'Copying Logz.io OTEL files to AppData subdirectory ...'
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
#     Write-Log $script:LogLevelDebug $Message

#     try {
#         Copy-Item -Path "$script:LogzioTempDir\$script:OtelCollectorExeName" -Destination $script:LogzioOtelCollectorDir -Force -ErrorAction Stop
#         Copy-Item -Path "$script:OtelResourcesDir\$script:OtelConfigName" -Destination $script:LogzioOtelCollectorDir -Force -ErrorAction Stop
#     }
#     catch {
#         $Message = "installer.ps1 ($ExitCode): error copying OTEL files to AppData subdirectory: $_"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
#         Write-TaskPostRun "Write-Error `"$Message`""

#         return $ExitCode
#     }
# }

# # Runs Logz.io OTEL collector service
# # Input:
# #   ---
# # Output:
# #   ---
# function Invoke-LogzioOtelCollectorService {
#     $local:ExitCode = 5
#     $local:FuncName = $MyInvocation.MyCommand.Name

#     $local:Message = 'Running Logz.io OTEL collector service ...'
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
#     Write-Log $script:LogLevelDebug $Message
#     $Message = Get-Content -Path $script:OtelConfig
#     Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
#     Write-Log $script:LogLevelDebug $Message

#     try {
#         New-Service -Name $script:LogzioOtelCollectorServiceName -BinaryPathName "$script:OtelCollectorExe --config $script:OtelConfig" -Description "Collects localhost logs/metrics and sends them to Logz.io." -ErrorAction Stop | Out-Null
#     }
#     catch {
#         $Message = "installer.ps1 ($ExitCode): error creating '$script:LogzioOtelCollectorServiceName' service: $_"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
#         Write-TaskPostRun "Write-Error `"$Message`""

#         sc.exe DELETE LogzioOTELCollector 2>$script:TaskErrorFile | Out-Null
#         if ($LASTEXITCODE -ne 0) {
#             $Message = "installer.ps1 ($ExitCode): error deleting '$script:LogzioOtelCollectorServiceName' service: $(Get-TaskErrorMessage)"
#             Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
#             Write-TaskPostRun "Write-Warning `"$Message`""
#         }

#         return $ExitCode
#     }

#     try {
#         Start-Service -Name $script:LogzioOtelCollectorServiceName -ErrorAction Stop | Out-Null
#     }
#     catch {
#         $Message = "installer.ps1 ($ExitCode): error starting '$script:LogzioOtelCollectorServiceName' service: $_"
#         Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
#         Write-TaskPostRun "Write-Error `"$Message`""

#         sc.exe DELETE LogzioOTELCollector 2>$script:TaskErrorFile | Out-Null
#         if ($LASTEXITCODE -ne 0) {
#             $Message = "installer.ps1 ($ExitCode): error deleting '$script:LogzioOtelCollectorServiceName' service: $(Get-TaskErrorMessage)"
#             Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
#             Write-TaskPostRun "Write-Warning `"$Message`""
#         }

#         return $ExitCode
#     }
# }
