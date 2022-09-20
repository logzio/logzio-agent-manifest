#################################################################################################################################
###################################################### Agent Windows Script #####################################################
#################################################################################################################################

# Checks if PowerShell was run as Administrator
# Error:
#   Exit Code 1
function Test-IsElevated {
    Write-Output "[INFO]" "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Checking if PowerShell was run as Administrator ..." >> $logFile

    $local:id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $local:principal = New-Object System.Security.Principal.WindowsPrincipal($id)

    if (-Not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Output "[ERROR]" "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (1): PowerShell was not run as Administrator. Please run Powershell as Administrator and rerun the agent script." >> $logFile
        Write-Host "agent.ps1 (1): PowerShell was not run as Administrator. Please run Powershell as Administrator and rerun the agent script." -ForegroundColor Red
        Exit 1
    }
}

# Prints usage
# Output:
#   Help usage
function Show-Help {
    Write-Host "Usage: .\agent.ps1 --url=<logzio_app_url> --id=<agent_id> [--debug=<app_json>] [--branch<repo_branch>]"
    Write-Host " --url=<logzio_app_url>       Logz.io app URL (https://app.logz.io)"
    Write-Host " --id=<agent_id>              Logz.io agent ID"
    Write-Host " --debug=<app_json>           Debug run using a local application JSON"
    Write-Host " --branch=<repo_branch>       The branch of Logz.io repo. Default is master"
    Write-Host " --help                       Show usage"
}

# Gets arguments
# Input:
#   Agent script arguments ($args)
# Output:
#   appURL - Logz.io app URL
#   agentID - Logz.io agent ID
#   appJsonFile - App JSON (only in debug)
#   repoBranch - Repo branch (for tests)
# Error:
#   Exit Code 2
function Get-Arguments ([string[]]$agentArgs) {
    Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Getting arguments ..." >> $logFile

    $script:appURL = ""
    $script:agentID = ""
    $script:appJsonFile = ""

    for ($i=0; $i -lt $agentArgs.Count; $i++) {
        switch -Regex ($agentArgs[$i]) {
            --help {
                Show-Help
                Remove-TempDir
                Exit
            }
            --url=* {
                $script:appURL = (Write-Output $agentArgs[$i]).Split("=", 2)[1]
                if ([string]::IsNullOrEmpty($appURL)) {
                    Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (2): no Logz.io app URL specified!" >> $logFile
                    Write-Host "agent.ps1 (2): no Logz.io app URL specified!" -ForegroundColor Red
                    Exit 2
                }

                Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] url = $appURL" >> $logFile
                continue
            }
            --id=* {
                $script:agentID = (Write-Output $agentArgs[$i]).Split("=", 2)[1]
                if ([string]::IsNullOrEmpty($agentID)) {
                    Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (2): no agent ID specified!" >> $logFile
                    Write-Host "agent.ps1 (2): no agent ID specified!" -ForegroundColor Red
                    Exit 2
                }

                Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] id = $agentID" >> $logFile
                continue
            }
            --debug=* {
                $script:appJsonFile = (Write-Output $agentArgs[$i]).Split("=", 2)[1]
                if ([string]::IsNullOrEmpty($appJsonFile)) {
                    Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (2): no JSON file specified!" >> $logFile
                    Write-Host "agent.ps1 (2): no JSON file specified!" -ForegroundColor Red
                    Exit 2
                }

                Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] debug = $appJsonFile" >> $logFile
                continue
            }
            --branch=* {
                $script:repoBranch = (Write-Output $agentArgs[$i]).Split("=", 2)[1]
                Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] branch = $repoBranch" >> $logFile
                continue
            }
            default {
                Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (2): unrecognized flag" >> $logFile
                Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (2): try '.\agent.ps1 --help' for more information" >> $logFile
                Write-Host "agent.ps1 (2): unrecognized flag" -ForegroundColor Red
                Write-Host "agent.ps1 (2): try '.\agent.ps1 --help' for more information" -ForegroundColor Red
                Exit 2
            }
        }
    }

    Test-ArgumentsValidation
}

# Checks validation of the arguments
# Error:
#   Exit Code 2
function Test-ArgumentsValidation {
    Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Checking validation ..." >> $logFile

    if (-Not [string]::IsNullOrEmpty($appJsonFile)) {
        if (Test-Path -Path $appJsonFile -PathType Leaf) {
            return
        }

        Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (2): the JSON file $appJsonFile does not exist" >> $logFile
        Write-Host "agent.ps1 (2): the JSON file $appJsonFile does not exist" -ForegroundColor Red
        Exit 2
    }

    $local:isError = $false

    if ([string]::IsNullOrEmpty($appURL)) {
        $isError = $true
        Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (2): Logz.io app URL must be specified" >> $logFile
        Write-Host "agent.ps1 (2): Logz.io app URL must be specified" -ForegroundColor Red
    }
    if ([string]::IsNullOrEmpty($agentID)) {
        $isError = $true
        Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (2): agent ID must be specified" >> $logFile
        Write-Host "agent.ps1 (2): agent ID must be specified" -ForegroundColor Red
    }

    if ($isError) {
        Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (2): try '.\agent.ps1 --help' for more information" >> $logFile
        Write-Host "agent.ps1 (2): try '.\agent.ps1 --help' for more information" -ForegroundColor Red
        Exit 2
    }
}

# Gets agent functions scripts from logzio-agent-manifest repo to logzio-temp directory
# Error:
#   Exit Code 3
function Get-AgentFunctionsScripts {
    Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Getting agent functions script file from logzio-agent-manifest repo ..." >> $logFile
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $repoURL/scripts/windows/functions.ps1 -OutFile $logzioTempDir\agent_functions.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (1): failed to get agnet functions script file from logzio-agent-manifest repo.`n  $_" >> $logFile

        Write-Host "agent.ps1 (3): failed to get agnet functions script file from logzio-agent-manifest repo.`n  $_" -ForegroundColor Red
        Remove-Item -Path $logzioTempDir -Recurse
        Exit 3
    }

    Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Getting utils functions script file from logzio-agent-manifest repo ..." >> $logFile
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $repoURL/scripts/windows/utils_functions.ps1 -OutFile $logzioTempDir\utils_functions.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        $_ >> $logFile
        Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (1): failed to get utils functions script file from logzio-agent-manifest repo.`n  $_" >> $logFile

        Write-Host "agent.ps1 (3): failed to get utils functions script file from logzio-agent-manifest repo.`n  $_" -ForegroundColor Red
        Remove-Item -Path $logzioTempDir -Recurse
        Exit 3
    }
}


# Consts
$script:logzioTempDir = ".\logzio-temp"                                                                 # Logz.io temp directory
$script:logFile = ".\logzio_agent.log"                                                                  # Log file path
$script:runFile = "$logzioTempDir\run.ps1"                                                              # Run file path
$script:taskErrorFile = "$logzioTempDir\task_error.txt"                                                 # Task error file path
$script:appJSON = "$logzioTempDir\app.json"                                                             # App JSON path

# Move to Documents directory
Set-Location -Path $env:UserProfile\Documents

# Check if PowerShell was run as Administrator
Test-IsElevated

# Get arguments and check validation
Get-Arguments $args

# Set default repo branch
if ([string]::IsNullOrEmpty($repoBranch)) {
    $repoBranch = "master"
    Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] branch = master (default)" >> $logFile
}

# Consts
$script:repoURL = "https://raw.githubusercontent.com/logzio/logzio-agent-manifest/$repoBranch"          # logzio-agent-manifest repo URL

# Create temp directory with files
if (-Not (Test-Path $logzioTempDir)) {
    New-Item -Path $logzioTempDir -ItemType Directory | Out-Null    
}

$null > $runFile
$null > $taskErrorFile

# Get agent functions scripts
Get-AgentFunctionsScripts

# Load agent functions
Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Loading agent functions ..." >> $logFile
. $logzioTempDir\agent_functions.ps1
. $logzioTempDir\utils_functions.ps1

# Append environment variable Path
if ($env:Path -notcontains "C:\ProgramData\chocolatey\bin") {
    $env:Path += ";C:\ProgramData\chocolatey\bin"
}

# Print title
Write-Host "
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
                                         g:::::gg   gg:::::g                                                   
                                          g::::::ggg:::::::g                                                   
                                           gg:::::::::::::g                                                    
                                             ggg::::::ggg                                                      
                                                gggggg                                                         
" -ForegroundColor Cyan
Write-Host "Running " -NoNewline
Write-Host "Logz.io " -ForegroundColor Cyan -NoNewline
Write-Host "Agent:`n`n" -NoNewline

# Run prerequisite installations
Write-Host "prerequisite installations:"
Invoke-Task "Install-JQ" "installing jq"                                                                # Install jq

# Run last preparations
Write-Host "`nlast preparations:"
Invoke-Task "Get-AppJSON" "getting application JSON"                                                    # Get app JSON
Invoke-Task "Build-RepoPath" "building path to logzio-agent-manifest repo"                              # Build repo path to logzio-agent-manifest rep
Invoke-Task "Get-PrerequisitesScripts" "getting prerequisites scripts"                                  # Get prerequisites scripts
Invoke-Task "Get-InstallerScripts" "getting installer scripts"                                          # Get installer scripts

# Run prerequisites script
Write-Log "INFO" "Running prerequisites script ..."
Write-Host "`nprerequisites:"
. $logzioTempDir\prerequisites.ps1
if ($LASTEXITCODE -gt 0) {
    Exit $LASTEXITCODE
}

# Run installer script
Write-Log "INFO" "Running installer script ..."
Write-Host "`ninstaller:"
. $logzioTempDir\installer.ps1
if ($LASTEXITCODE -gt 0) {
    Exit $LASTEXITCODE
}

# Delete temp directory
Remove-TempDir
