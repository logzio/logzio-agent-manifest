  #################################################################################################################################
###################################################### Agent Windows Script #####################################################
#################################################################################################################################

# Gets agent functions scripts from logzio-agent-manifest repo to logzio-temp directory
# Error:
#   Exit Code 1
function Get-AgentFunctionsScripts {
    Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Getting agent functions script file from logzio-agent-manifest repo ..." >> $logFile
    try {
        Invoke-WebRequest -Uri $repoURL/scripts/windows/functions.ps1 -OutFile logzio-temp/agent_functions.ps1 | Out-Null
    }
    catch {
        $_ >> $logFile
        Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (1): failed to get agnet functions script file from logzio-agent-manifest repo" >> $logFile

        Write-Output $_
        Write-Host "agent.ps1 (1): failed to get agnet functions script file from logzio-agent-manifest repo" -ForegroundColor Red
        Remove-Item -Path logzio-temp -Recurse
        Exit 1
    }

    Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Getting utils functions script file from logzio-agent-manifest repo ..." >> $logFile
    try {
        Invoke-WebRequest -Uri $repoURL/scripts/windows/utils_functions.ps1 -OutFile logzio-temp/utils_functions.ps1 | Out-Null
    }
    catch {
        $_ >> $logFile
        Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (1): failed to get utils functions script file from logzio-agent-manifest repo" >> $logFile

        Write-Output $_
        Write-Host "agent.ps1 (1): failed to get utils functions script file from logzio-agent-manifest repo" -ForegroundColor Red
        Remove-Item -Path logzio-temp -Recurse
        Exit 1
    }
}


# Remove last run globals
Clear-Variable -Name appURL, agentID, appJsonFile -Force 2>&1 | Out-Null

# logzio-agent-manifest repo URL
$global:repoURL = "https://raw.githubusercontent.com/logzio/logzio-agent-manifest/v0.2"

# Log file path
$global:logFile = "logzio_agent.log"

# Create temp directory with run file
mkdir -p logzio-temp | Out-Null
$null > logzio-temp\run.ps1

# Get agent functions scripts
#Get-AgentFunctionsScripts

# Load agent functions
Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Loading agent functions ..." >> $logFile
. .\functions.ps1
. .\utils_functions.ps1
#. ./logzio-temp/agent_functions.ps1
#. ./logzio-temp/utils_functions.ps1

# Get arguments and check validation
Get-Arguments $args

# Print title
Write-Host "Running " -NoNewline
Write-Host "Logz" -ForegroundColor Blue -NoNewline
Write-Host ".io " -ForegroundColor Yellow -NoNewline
Write-Host "Agent:`n`n" -NoNewline

# Run prerequisite installations
Write-Host "prerequisite installations:"
Invoke-Task "Install-JQ" "installing jq"
#Invoke-Task "Install-Chocolatey" "installing Chocolatey"                          # install Chocolatey
<#
Invoke-Task "install_jq" "installing jq"                                           # Install jq

<#
# Run last preparations
echo -e "\nlast preparations:"
execute_task "get_app_json" "getting application JSON"                              # Get app JSON
execute_task "build_repo_path" "building path to logzio-agent-manifest repo"        # Build repo path to logzio-agent-manifest repo
execute_task "get_prerequisite_scripts" "getting prerequisites scripts"             # Get prerequisites scripts
execute_task "get_installer_scripts" "getting installer scripts"                    # Get installer scripts

# Run prerequisites script
echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Running prerequisites script ..." >> logzio_agent.log
echo -e "\nprerequisites:"
source ./logzio-temp/prerequisites.bash

# Run installer script
echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Running installer script ..." >> logzio_agent.log
echo -e "\ninstaller:"
source ./logzio-temp/installer.bash

# Delete temp directory
delete_temp_dir
#> 
 
