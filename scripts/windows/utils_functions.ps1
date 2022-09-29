#################################################################################################################################
#################################################### WINDOWS Utils Functions ####################################################
#################################################################################################################################


# Prints info message in green
# Input:
#   Message - Message text
# Output:
#   The message
function Write-Info {
    param (
        [string]$Message
    )

    Write-Log 'INFO' $Message
    Write-Host $Message -ForegroundColor Green
}

# Prints error message in red
# Input:
#   Message - Message text
# Output:
#   The message
function Write-Error {
    param (
        [string]$Message
    )

    Write-Log 'ERROR' $Message
    Write-Host $Message -ForegroundColor Red
}

# Prints warning message in yellow
# Input:
#   Message - Message text
# Output:
#   The message
function Write-Warning {
    param (
        [string]$Message
    )

    Write-Log 'WARN' $Message
    Write-Host $Message -ForegroundColor Yellow
}

# Writes log into log file
# Input:
#   LogLevel - Level of the log (INFO/ERROR/WARN)
#   Message - Message text
# Output:
#   ---
function Write-Log {
    param (
        [string]$LogLevel,
        [string]$Message
    )
    
    Write-Output "[$LogLevel] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] $Message" >> $LogFile
}

function Get-LogMetadata {
    
}

# Sends log to Logz.io
# Input:
#   LogFields - Log fields to send as one log to Logz.io
# Output:
#   ---
function Send-LogToLogzio {
    param (
        [hashtable]$LogFields
    )

    $local:Log = '{'

    foreach ($LogField in $LogFields.GetEnumerator()) {
        $local:FieldKey = $LogField.Key
        $local:FieldValue = $LogField.Value
        $Log += "`"$FieldKey`":`"$FieldValue`","
    }

    $Log = $Log.Substring(1)
    $Log += '}'

    $local:Parameters = @{
        Action = 'SendMessage'
        MessageBody = $Log
    }

    try {
        Invoke-WebRequest -Uri 'https://sqs.us-east-1.amazonaws.com/486140753397/LogzioAgentQueue' -Body $Parameters -Method Get -UseBasicParsing | Out-Null
    }
    catch {
        #Write-TaskPostRun "Write-Host `"failed to send a request with log message to Logz.io agent SQS.`n`t$_`" -ForegroundColor Yellow"
        Write-TaskPostRun "Write-Warning `"failed to send a request with log message to Logz.io agent SQS.`n`t$_`""
    }
}

# Writes command into task post run script file
# Input:
#   command - The command to write into the file
# Output:
#   ---
function Write-TaskPostRun {
        param (
            [string]$Command
        )

    Write-Output $Command >> $TaskPostRunFile
}

# Deletes Logz.io temp directory
# Input:
#   ---
# Output:
#   ---
function Remove-TempDir {
    try {
        Remove-Item -Path $LogzioTempDir -Recurse -ErrorAction Stop
    } 
    catch {
        Write-TaskPostRun "Write-Warning `"failed to delete Logz.io temp directory.`n`t$_`""
    }
}

# Gets task error file's content
# Intput:
#   ---
# Output:
#   The task error file's content
#function Get-TaskErrorContent {
#    $local:Err = Get-Content -Path $taskErrorFile -First 1
#    if ([string]::IsNullOrEmpty($err)) {
#        return
#    }

#    $err = $err.Replace("`"", "'")
#    Write-Output "$err"
#}

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
    Write-Log 'INFO' 'Checking if Chocolatey is installed ...'
    Get-Command -Name choco 2>&1 | Out-Null
    if ($?) {
        return
    }

    Write-Log 'INFO' 'Installing Chocolatey ...'
    $local:job = Start-Job -ScriptBlock {Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression -Command (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')}
    Wait-Job -Job $job | Out-Null

    Get-Command choco 2>&1 | Out-Null
    if ($?) {
        return
    }
    
    Write-Run "Write-Error `"utils_functions.ps1 (1): failed to install Chocolatey.`n  run the following command 'Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))', open a new PowerShell and rerun Logz.io agent script`""
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
    $local:timeout = 300
    $local:counter = 0

    [Console]::CursorVisible = $false
    
    $local:job = Start-Job -InitializationScript {} -ScriptBlock $scriptBlock
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
        Remove-TempDir
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
