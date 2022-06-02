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

# Writes log into logzio_agent.log file
# Input:
#   logLevel - The level of the log (INFO/ERROR/WARN)
#   log - Log text
function Write-Log ([string]$logLevel, [string]$log) {
    Write-Output "[$logLevel] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] $log" >> $logFile
}

# Writes command into logzio-temp\run.ps1 file
# Input:
#   command - The command towrite into the file
function Write-Run ([string]$command) {
    Write-Output "$command" >> $runFile
}

# Deletes the temp directory
function Remove-TempDir {
    Remove-Item -Path $logzioTempDir -Recurse
}

# Finds the requested parameter in params 
# Inputs: 
#   params - The parameters in the application json
#   requested_name - The parameter name to find
# Output:
#   The requested parameter if requested_name was found, empty otherwise.
function Find-Params ([string]$params, [string]$requestedName) {
    $local:paramsList = Write-Output $params | jq -c '.'
    $local:requestedParam = ""

    foreach ($param in $paramsList) {
        $local:name = Write-Output "$param" | jq -r '.name'
        if ($name.Equals($requestedName)) {
            $requestedParam = "$param"
        }
    }

    Write-Output "$requestedParam"
}

# Executes command with progress indicator
# Input:
#   command - Command to execute
#   desc - Task description
# Error:
#   Exit Code according the executed command
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
        $counter++
        Write-Host "`r[   ] $desc ..." -NoNewline

        for ($i=0; $i -lt $frame.Count; $i++) {
            Write-Host "`r[ $($frame[$i]) ]" -NoNewline
            Start-Sleep -Milliseconds $frameInterval
        }

        $jobState = $job.State | Write-Output
        if ($jobState.Equals("Completed")) {
            break
        }
        if ($jobState.Equals("Failed")) {
            break
        }

        if ($counter -eq $timeout) {
            Remove-Job -Job $job -Force >$null
            Write-Run "Write-Error `"timeout error: the task was not completed in time`""
            break
        }
    }

    Wait-Job -Job $job | Out-Null
    $local:exitCode = Receive-Job -Job $job
    if ([string]::IsNullOrEmpty($exitCode) -or $exitCode -isnot [int]) {
        $exitCode = 0
    }
    Write-Output $exitCode >> test.txt

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
    Clear-Content $runFile
}
