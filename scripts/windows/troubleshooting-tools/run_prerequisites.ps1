#################################################################################################################################
################################### Run Prerequisites Windows Script (Troubleshooting Tool) #####################################
#################################################################################################################################

# Gets utils functions script from logzio-agent-manifest repo to logzio-temp directory
# Error:
#   Exit Code 1
function Get-UtilsFunctionsScript {
    Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Getting utils functions script file from logzio-agent-manifest repo ..." >> $logFile
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $repoURL/scripts/windows/utils_functions.ps1 -OutFile $logzioTempDir\utils_functions.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        $_ >> $logFile
        Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (1): failed to get utils functions script file from logzio-agent-manifest repo.`n  $_" >> $logFile

        Write-Host "agent.ps1 (1): failed to get utils functions script file from logzio-agent-manifest repo.`n  $_" -ForegroundColor Red
        Remove-Item -Path $logzioTempDir -Recurse
        Exit 1
    }
}

# Prints usage
# Output:
#   Help usage
function Show-Help {
    Write-Host "Usage: .\run_prerequisites.ps1 --path=<logzio_repo_datasource_path>"
    Write-Host " --path=<logzio_repo_datasource_path>       logzio-agent-manifest repo datasource path (dir1/dir2/dir3)"
    Write-Host " --help                                     Show usage"
}

# Gets arguments
# Input:
#   Run prerequisites script arguments ($args)
# Output:
#   repoDatasourcePath - logzio-agent-manifest datasource path (dir1/dir2/dir3)
# Error:
#   Exit Code 2
function Get-Arguments ([string[]]$agentArgs) {
    Write-Log "INFO" "Getting arguments ..."

    $script:repoDatasourcePath = ""

    for ($i=0; $i -lt $agentArgs.Count; $i++) {
        switch -Regex ($agentArgs[$i]) {
            --help {
                Show-Help
                Remove-TempDir
                Exit
            }
            --path=* {
                $repoDatasourcePath = (Write-Output $agentArgs[$i]).Split("=", 2)[1]
                if ([string]::IsNullOrEmpty($repoDatasourcePath)) {
                    Write-Error "run_prerequisites.ps1 (2): no logzio-agent-manifest repo datasource path specified!"
                    Remove-TempDir
                    Exit 2
                }

                Write-Log "INFO" "path = $repoDatasourcePath"
                continue
            }
            default {
                Write-Error "agent.ps1 (2): unrecognized flag"
                Write-Error "agent.ps1 (2): try '.\run_prerequisites.ps1 --help' for more information"
                Remove-TempDir
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
    Write-Log "INFO" "Checking validation ..."

    if ([string]::IsNullOrEmpty($repoDatasourcePath)) {
        Write-Error "run_prerequisites.ps1 (2): logzio-agent-manifest repo datasource path must be specified"
        Write-Error "run_prerequisites.ps1 (2): try '.\run_prerequisites.bash --help' for more information"
        Remove-TempDir
        Exit 2
    }
    if ($repoDatasourcePath -match ".*/.*/.*") {
        return
    }

    Write-Error "run_prerequisites.ps1 (2): logzio-agent-manifest repo datasource path's format must be 'dir1/dir2/dir3'"
    Write-Error "run_prerequisites.ps1 (2): try '.\run_prerequisites.ps1 --help' for more information"
    Remove-TempDir
    Exit 2
}

# Builds path to logzio-agent-manifest repo according the app JSON
# Output:
#   repoPath - Path to logzio-agent-manifest repo using repoDatasourcePath
function Build-RepoPath {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building repo path ..."
    
    $local:dir1 = $repoDatasourcePath.Split("/")[0]
    $local:dir2 = $repoDatasourcePath.Split("/")[1]
    $local:dir3 = $repoDatasourcePath.Split("/")[2]
    $local:repoPath = "$repoURL/$dir1/$dir2/$dir3"

    Write-Log "INFO" "repoPath = $repoPath"
    Write-Run "repoPath = `"$repoPath`""
}

# Gets prerequisites scripts from logzio-agent-manifest repo to logzio-temp directory
# Error:
#   Exit Code 3
function get_prerequisites_scripts {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting prerequisites script file from logzio-agent-manifest repo ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/prerequisites/windows/prerequisites.ps1 -OutFile $using:logzioTempDir\prerequisites.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"run_prerequisites.ps1 (3): failed to get prerequisites script file from logzio-agent-manifest repo.`n  $_`""
        return 3
    }

    Write-Log "INFO" "Getting prerequisites functions script file from logzio-agent-manifest repo ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/prerequisites/windows/functions.ps1 -OutFile $using:logzioTempDir\prerequisites_functions.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"run_prerequisites.ps1 (3): failed to get prerequisites functions script file from logzio-agent-manifest repo.`n  $_`""
        return 3
    }
}

# Consts
$script:repoURL = "https://raw.githubusercontent.com/logzio/logzio-agent-manifest/master"   # logzio-agent-manifest repo URL
$script:logzioTempDir = ".\logzio-temp"                                                     # Logz.io temp directory
$script:logFile = ".\logzio_agent_troubleshooting.log"                                      # Log file path
$script:runFile = "$logzioTempDir\run.ps1"                                                  # Run file path
$script:taskErrorFile = "$logzioTempDir\task_error.txt"                                     # Task error file path

# Move to Documents directory
Set-Location -Path $env:UserProfile\Documents

# Create temp directory with files
if (-Not (Test-Path $logzioTempDir)) {
    New-Item -Path $logzioTempDir -ItemType Directory | Out-Null    
}

$null > $runFile
$null > $taskErrorFile

# Get utils functions script
Get-UtilsFunctionsScript

# Load utils functions
Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Loading utils functions ..." >> $log_file
. $logzioTempDir\utils_functions.ps1

# Get arguments and check validation
Get-Arguments $args

# Print title
Write-Host "Running " -NoNewline
Write-Host "Logz.io " -ForegroundColor Cyan -NoNewline
Write-Host "Troubleshooting Tool:`n`n" -NoNewline

# Run last preparations
Write-Host "last preparations:"
Invoke-Task "Build-RepoPath" "building path to logzio-agent-manifest repo"                  # Build repo path to logzio-agent-manifest repo
Invoke-Task "Get-PrerequisitesScripts" "getting prerequisites scripts"                      # Get prerequisites scripts

# Run prerequisites script
Write-Log "INFO" "Running prerequisites script ..."
Write-Host "`nprerequisites:"
. $logzioTempDir\prerequisites.ps1

# Delete temp directory
Remove-TempDir

# Print success message
Write-Host
Write-Info "##### Logz.io agent troubleshooting tool was finished successfully #####"

# Finished successfully
Exit 0
