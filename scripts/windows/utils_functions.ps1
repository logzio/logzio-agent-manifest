   #!/bin/bash

#################################################################################################################################
#################################################### Utils Windows Functions ####################################################
#################################################################################################################################

# Prints error message in red
# Input:
#   message - Message text
# Output:
#   The message
function Write-Error ([string]$message) {
    Write-Log "ERROR" "$message"
    Write-Host "$message" -ForegroundColor Red
}

# Prints warning message in yellow
# Input:
#   message - Message text
# Output:
#   The message
function Write-Warning ([string]$message) {
    Write-Log "WARN" "$message"
    Write-Host "$message" -ForegroundColor Yellow
}

# Writes log into Logz.io agent log file
# Input:
#   logLevel - The level of the log (INFO/ERROR/WARN)
#   log - Log text
function Write-Log ([string]$logLevel, [string]$log) {
    Write-Output "[$logLevel] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] $log" >> $logFile
}

# Writes command into run file in Logz.io temp directory
# Input:
#   command - The command to write into the file
function Write-Run ([string]$command) {
    Write-Output "$command" >> $runFile
}

# Deletes the temp directory
function Remove-TempDir {
    Remove-Item -Path $logzioTempDir -Recurse
}

# Gets task error file error message
# Output:
#   The task error message
function Get-TaskError {
    $local:err = Get-Content $taskErrorFile -First 1
    if ([string]::IsNullOrEmpty($err)) {
        return
    }

    $err = $err.Replace("`"", "'")
    Write-Output "$err"
}

# Finds the requested parameter in params 
# Inputs: 
#   params - The parameters in the application json
#   requestedName - The parameter name to find
# Output:
#   The requested parameter if requestedName was found, empty otherwise.
function Find-Param ([string]$params, [string]$requestedName) {
    $local:paramsList = Write-Output $params | jq -c '.'
    $local:requestedParam = ""

    foreach ($param in $paramsList) {
        $local:name = Write-Output "$param" | jq -r '.name'
        if ([string]::IsNullOrEmpty($name) -or $name.Equals("null")) {
            continue
        }
        
        if ($name.Equals($requestedName)) {
            $requestedParam = "$param"
        }
    }

    Write-Output "$requestedParam"
}

# Installs Chocolatey
# Error:
#   Exit Code 1
function Install-Chocolatey {
    Write-Log "INFO" "Checking if Chocolatey is installed ..."
    Get-Command choco 2>&1 | Out-Null
    if ($?) {
        return
    }

    Write-Log "INFO" "Installing Chocolatey ..."
    $local:job = Start-Job -ScriptBlock {Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression -Command (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')}
    Wait-Job -Job $job

    Get-Command choco 2>&1 | Out-Null
    if ($?) {
        return
    }
    
    Write-Run "Write-Error `"utils_functions.ps1 (1): failed to install Chocolatey.`n  run the following command 'Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))' and rerun Logz.io agent script`""
    return 1
}

# Executes command with progress indicator
# Input:
#   command - Command to execute
#   desc - Task description
# Error:
#   Exit Code 2 if got timeout error, otherwise Exit Code according the executed command
function Invoke-Task([string]$command, [string]$desc) {
    $local:funcCode = Get-Command $command | Select-Object -ExpandProperty ScriptBlock
    $local:scriptBlock = [ScriptBlock]::Create($funcCode)
    $local:frame = "-", "\", "|", "/"
    $local:frameInterval = 250
    $local:timeout = 30
    $local:counter = 0

    [Console]::CursorVisible = $false
    
    $local:job = Start-Job -ScriptBlock $scriptBlock
    $local:jobState = ""

    while ($true) {
        Write-Host "`r[   ] $desc ..." -NoNewline

        for ($i=0; $i -lt $frame.Count; $i++) {
            Write-Host "`r[ $($frame[$i]) ]" -NoNewline
            Start-Sleep -Milliseconds $frameInterval
        }

        $counter++

        $jobState = $job.State | Write-Output
        if ($jobState.Equals("Completed")) {
            break
        }
        if ($jobState.Equals("Failed")) {
            break
        }

        if ($counter -eq $timeout) {
            Remove-Job -Job $job -Force >$null
            $jobState = "Timeout"
            Write-Run "Write-Error `"utils_functions.ps1 (2): timeout error: the task was not completed in time`""
            break
        }
    }

    Wait-Job -Job $job | Out-Null
    $local:exitCode = 2
    
    if (-Not $jobState.Equals("Timeout")) {
        $exitCode = Receive-Job -Job $job
        if ([string]::IsNullOrEmpty($exitCode) -or $exitCode -isnot [int]) {
            $exitCode = 0
        }
    }
    
    if (-Not $jobState.Equals("Completed") -or $exitCode -gt 0) {
        Write-Host "`r[ " -NoNewline
        Write-Host "X" -ForegroundColor red -NoNewline
        Write-Host " ]" -NoNewline
        Write-Host " $desc ...`n" -ForegroundColor red -NoNewline

        [Console]::CursorVisible = $true
        
        . $runFile
        #Remove-TempDir
        Exit $exitCode
    }

    Write-Host "`r[ " -NoNewline
    Write-Host "$([char]8730)" -ForegroundColor green -NoNewline
    Write-Host " ]" -NoNewline
    Write-Host " $desc ...`n" -ForegroundColor green -NoNewline

    [Console]::CursorVisible = $true

    . $runFile
    #Clear-Content $runFile
}
