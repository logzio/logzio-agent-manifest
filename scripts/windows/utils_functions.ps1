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
    Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] $message" >> logzio_agent.log
    Write-Host "$message" -ForegroundColor Red
}

# Prints warning message in yellow
# Input:
#   message - Message text
# Output:
#   The message
function Write-Warning ([string]$message) {
    Write-Output "[WARN] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] $message" >> logzio_agent.log
    Write-Host "$message" -ForegroundColor Yellow
}

# Deletes the temp directory
function Remove-TempDir {
    Remove-Item -Path logzio-temp -Recurse
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
            Write-Output "Write-Error `"timeout error - the task was not completed in time`"" >> logzio-temp/run
            break
        }
    }

    Wait-Job -Job $job | Out-Null
    $local:exitCode = Receive-Job -Job $job

    if (-Not $jobState.Equals("Completed") -Or $exitCode -ne 0) {
        Write-Host "`r[ " -NoNewline
        Write-Host "X" -ForegroundColor red -NoNewline
        Write-Host " ]" -NoNewline
        Write-Host " $desc ...`n" -ForegroundColor red -NoNewline

        [Console]::CursorVisible = $true
        
        . ./logzio-temp/run.ps1
        #Remove-TempDir
        Exit $exitCode
    }

    Write-Host "`r[ " -NoNewline
    Write-Host "$([char]8730)" -ForegroundColor green -NoNewline
    Write-Host " ]" -NoNewline
    Write-Host " $desc ...`n" -ForegroundColor green -NoNewline

    [Console]::CursorVisible = $true

    . ./logzio-temp/run.ps1
    Clear-Content logzio-temp/run.ps1
}
 
