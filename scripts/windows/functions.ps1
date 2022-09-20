#################################################################################################################################
##################################################### Agent Windows Functions ###################################################
#################################################################################################################################

# Installs jq
# Error:
#   Exit Code 3
function Install-JQ {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile
    $local:taskErrorFile = $using:taskErrorFile

    Write-Log "INFO" "Checking if jq is installed ..."
    Get-Command jq 2>&1 | Out-Null
    if ($?) {
        return
    }

    $local:result = Install-Chocolatey
    if (-Not [string]::IsNullOrEmpty($result) -and $result -gt 0) {
        return 3
    }

    Write-Log "INFO" "Installing jq ..."
    choco install jq -y 2>$using:taskErrorFile | Out-Null
    if ($?) {
        return
    }

    $local:err = Get-TaskError
    Write-Run "Write-Error `"agent.ps1 (3): failed to install jq.`n  $err`""
    return 3
}

# Gets the application JSON from the agent/local file into logzio-temp directory
# Error:
#   Exit Code 4
function Get-AppJSON {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting application JSON ..."

    if (-Not [string]::IsNullOrEmpty($using:appJsonFile)) {
        # Using local app JSON file
        Write-Log "INFO" "Using local application JSON file ..."
        Copy-Item -Path $using:appJsonFile -Destination $using:appJSON
        return
    }

    # Getting app JSON from agent
    Write-Log "INFO" "Getting application JSON from agent ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:appURL/telemetry-agent/public/agents/configuration/$using:agentID -OutFile $using:appJSON | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"agent.ps1 (4): failed to get Logz.io application JSON from agent. make sure your URL is valid.`n  $_`""
        return 4
    }

    $local:statusCode = jq -r '.statusCode' $using:appJSON
    if ([string]::IsNullOrEmpty($statusCode)) {
        $statusCode = ""
    }
    if ($statusCode.Equals("null")) {
        return
    }

    Write-Run "Write-Error `"agent.ps1 (4): failed to get Logz.io application JSON from agent (statusCode $statusCode). make sure your ID is valid`""
    return 4
}

# Builds path to logzio-agent-manifest repo according the app JSON
# Output:
#   repoPath - Path to logzio-agent-manifest repo according the app JSON
# Error:
#   Exit Code 5
function Build-RepoPath {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Building repo path ..."

    $local:dir1 = jq -r '.configuration.name' $using:appJSON
    if ([string]::IsNullOrEmpty($dir1)) {
        Write-Run "Write-Error `"agent.ps1 (5): '.configuration.name' is empty in application JSON`""
        return 5
    }
    if ($dir1.Equals("null")) {
        Write-Run "Write-Error `"agent.ps1 (5): '.configuration.name' was not found in application JSON`""
        return 5
    }

    $local:dir2 = jq -r '.configuration.subtypes[0].name' $using:appJSON
    if ([string]::IsNullOrEmpty($dir2)) {
        Write-Run "Write-Error `"agent.ps1 (5): '.configuration.subtypes[0].name' is empty in application JSON`""
        return 5
    }
    if ($dir2.Equals("null")) {
        Write-Run "Write-Error `"agent.ps1 (5): '.configuration.subtypes[0].name' was not found in application JSON`""
        return 5
    }

    $local:dir3 = jq -r '.configuration.subtypes[0].datasources[0].name' $using:appJSON
    if ([string]::IsNullOrEmpty($dir3)) {
        Write-Run "Write-Error `"agent.ps1 (5): '.configuration.subtypes[0].datasources[0].name' is empty in application JSON`""
        return 5
    }
    if ($dir3.Equals("null")) {
        Write-Run "Write-Error `"agent.ps1 (5): '.configuration.subtypes[0].datasources[0].name' was not found in application JSON`""
        return 5
    }

    $local:repoPath = "$using:repoURL/$dir1/$dir2/$dir3"
    Write-Log "INFO" "repoPath = $repoPath"
    Write-Run "`$script:repoPath = `"$repoPath`""
}

# Gets prerequisites scripts from logzio-agent-manifest repo to logzio-temp directory
# Error:
#   Exit Code 6
function Get-PrerequisitesScripts () {
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
        Write-Run "Write-Error `"agent.ps1 (6): failed to get prerequisites script file from logzio-agent-manifest repo.`n  $_`""
        return 6
    }

    Write-Log "INFO" "Getting prerequisites functions script file from logzio-agent-manifest repo ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/prerequisites/windows/functions.ps1 -OutFile $using:logzioTempDir\prerequisites_functions.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"agent.ps1 (6): failed to get prerequisites functions script file from logzio-agent-manifest repo.`n  $_`""
        return 6
    }
}

# Gets installer scripts from logzio-agent-manifest repo to logzio-temp directory
# Error:
#   Exit Code 7
function Get-InstallerScripts {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting installer script file from logzio-agent-manifest repo ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/installer/windows/installer.ps1 -OutFile $using:logzioTempDir\installer.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"agent.ps1 (7): failed to get installer script file from logzio-agent-manifest repo.`n  $_`""
        return 7
    }

    Write-Log "INFO" "Getting installer functions script file from logzio-agent-manifest repo ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/installer/windows/functions.ps1 -OutFile $using:logzioTempDir\installer_functions.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"agent.ps1 (7): failed to get installer functions script file from logzio-agent-manifest repo.`n  $_`""
        return 7
    }
}
