#################################################################################################################################
###################################################### Agent Windows Script #####################################################
#################################################################################################################################

# Gets agent functions scripts from logzio-agent-manifest repo to logzio-temp directory
# Error:
#   Exit Code 1
function Get-AgentFunctionsScripts {
    Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Getting agent functions script file from logzio-agent-manifest repo ..." >> $logFile
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $repoURL/scripts/windows/functions.ps1 -OutFile $logzioTempDir\agent_functions.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (1): failed to get agnet functions script file from logzio-agent-manifest repo. error: $_" >> $logFile

        Write-Host "agent.ps1 (1): failed to get agnet functions script file from logzio-agent-manifest repo. $_" -ForegroundColor Red
        Remove-Item -Path $logzioTempDir -Recurse
        Exit 1
    }

    Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Getting utils functions script file from logzio-agent-manifest repo ..." >> $logFile
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $repoURL/scripts/windows/utils_functions.ps1 -OutFile $logzioTempDir\utils_functions.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        $_ >> $logFile
        Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (1): failed to get utils functions script file from logzio-agent-manifest repo. error: $_" >> $logFile

        Write-Host "agent.ps1 (1): failed to get utils functions script file from logzio-agent-manifest repo. $_" -ForegroundColor Red
        Remove-Item -Path $logzioTempDir -Recurse
        Exit 1
    }
}


# Consts
$script:repoURL = "https://raw.githubusercontent.com/logzio/logzio-agent-manifest/v0.2"     # logzio-agent-manifest repo URL
$script:logzioTempDir = ".\logzio-temp"                                                     # Logz.io temp directory
$script:logFile = ".\logzio_agent.log"                                                      # Log file path
$script:runFile = "$logzioTempDir\run.ps1"                                                  # Run file path
$script:taskResultFile = "$logzioTempDir\task_result.txt"                                   # Task result file path

# Create temp directory with run file
if (-Not (Test-Path logzio-temp)) {
    New-Item -Path $logzioTempDir -ItemType Directory | Out-Null    
}

$null > $runFile

# Get agent functions scripts
Get-AgentFunctionsScripts

# Load agent functions
Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Loading agent functions ..." >> $logFile
. $logzioTempDir\agent_functions.ps1
. $logzioTempDir\utils_functions.ps1

# Get arguments and check validation
Get-Arguments $args

# Print title
Write-Host "Running " -NoNewline
Write-Host "Logz" -ForegroundColor Blue -NoNewline
Write-Host ".io " -ForegroundColor Yellow -NoNewline
Write-Host "Agent:`n`n" -NoNewline

# Run prerequisite installations
Write-Host "prerequisite installations:"
Invoke-Task "Install-Chocolatey" "installing Chocolatey"                                    # Install Chocolatey
Invoke-Task "Install-JQ" "installing jq"                                                    # Install jq

# Run last preparations
Write-Host "`nlast preparations:"
Invoke-Task "Get-AppJSON" "getting application JSON"                                        # Get app JSON
Invoke-Task "Build-RepoPath" "building path to logzio-agent-manifest repo"                  # Build repo path to logzio-agent-manifest rep
Invoke-Task "Get-PrerequisitesScripts" "getting prerequisites scripts"                      # Get prerequisites scripts
#execute_task "get_installer_scripts" "getting installer scripts"                           # Get installer scripts

# Run prerequisites script
Write-Log "INFO" "Running prerequisites script ..."
Write-Host "`nprerequisites:"
. $logzioTempDir\prerequisites.ps1

<#
# Run installer script
echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Running installer script ..." >> logzio_agent.log
echo -e "\ninstaller:"
source ./logzio-temp/installer.bash

# Delete temp directory
delete_temp_dir
#>
