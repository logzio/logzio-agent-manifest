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
    
    Write-Output "[$LogLevel] [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" >> $AgentLogFile
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
        [string]$Level,
        [string]$Message,
        [string]$Step,
        [string]$ScriptName,
        [string]$FuncName,
        [string]$AgentId = '',
        [string]$Platform = '',
        [string]$SubType = '',
        [string]$DataSource = ''
    )

    $Message = $Message.Replace('\', '\\')
    $Message = $Message.Replace('"', '\"')

    $local:Log = "{`"@timestamp`":`"$(Get-Date -Format 'o')`",`"level`":`"$Level`",`"message`":`"$Message`",`"step`":`"$Step`",`"script`":`"$ScriptName`",`"func`":`"$FuncName`",`"os`":`"Windows`",`"windows_name`":`"$WindowsName`",`"windows_version`":`"$WindowsVersion`""

    if ($Level.Equals($LogLevelError)) {
        $local:ErrorIdPartMatch = $Message | Select-String -Pattern '\([0-9]+\)'
        $local:ErrorIdMatch = $ErrorIdPartMatch.Matches.Value | Select-String -Pattern '[0-9]+'
        $local:ErrorId = $ErrorIdMatch.Matches.Value
        
        $Log += ",`"error_id`":`"$ErrorId`""
    }
    if (-Not [string]::IsNullOrEmpty($AgentId)) {
        $Log += ",`"agent_id`":`"$AgentId`""
    }
    if (-Not [string]::IsNullOrEmpty($Platform)) {
        $Log += ",`"platform`":`"$Platform`""
    }
    if (-Not [string]::IsNullOrEmpty($SubType)) {
        $Log += ",`"subtype`":`"$SubType`""
    }
    if (-Not [string]::IsNullOrEmpty($DataSource)) {
        $Log += ",`"datasource`":`"$DataSource`""
    }

    $Log += '}'

    $local:Parameters = @{
        Action = 'SendMessage'
        MessageBody = $Log
    }

    try {
        Invoke-WebRequest -Uri 'https://sqs.us-east-1.amazonaws.com/486140753397/LogzioAgentQueue' -Body $Parameters -Method Get -UseBasicParsing | Out-Null
    }
    catch {
        Write-TaskPostRun "Write-Warning `"failed to send a request with log message to Logz.io agent SQS: $_`""
    }
}

# Writes command into task post run script file
# Input:
#   Command - The command to write into the file
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
        Write-TaskPostRun "Write-Warning `"failed to delete Logz.io temp directory: $_`""
    }
}

# Gets json string field value
# input:
#   JsonStr - Json string
#   JsonPath - Json path
# Output:
#   JsonValue - The value of the field. Only if got no error.
#   If got error will output message with exit code.
function Get-JsonStrFieldValue {
    param (
        [string]$JsonStr,
        [string]$JsonPath
    )

    $local:Result = $JsonStr | &$JqExe -r $JsonPath 2>$TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        $JsonStr = $JsonStr.Replace('"', '`"')
        Write-Output "error getting '$JsonPath' from '$JsonStr': $(Get-Content -Path $TaskErrorFile)"
        return 1
    }
    if ([string]::IsNullOrEmpty($Result)) {
        Write-Output "'$JsonPath' is empty in '$JsonStr'"
        return 2
    }
    if ($Result.Equals('null')) {
        Write-Output "'$JsonPath' does not exist in '$JsonStr'"
        return 3
    }

    $script:JsonValue = $Result
}

# Gets json string field value list
# input:
#   JsonStr - Json string
#   JsonPath - Json path
# Output:
#   JsonValue - The value (list) of the field. Only if got no error.
#   If got error will output message with exit code.
function Get-JsonStrFieldValueList {
    param (
        [string]$JsonStr,
        [string]$JsonPath
    )

    $local:Result = $JsonStr | &$JqExe -c $JsonPath 2>$TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        $JsonStr = $JsonStr.Replace('"', '`"')
        Write-Output "error getting '$JsonPath' from '$JsonStr': $(Get-Content -Path $TaskErrorFile)"
        return 1
    }
    if ($Result.Count -eq 0) {
        Write-Output "'$JsonPath' is empty in '$JsonStr'"
        return 2
    }

    $script:JsonValue = $Result
}

# Gets json file field value
# input:
#   JsonStr - Json string
#   JsonPath - Json path
# Output:
#   JsonValue - The value of the field. Only if got no error.
#   If got error will output message with exit code.
function Get-JsonFileFieldValue {
    param (
        [string]$JsonFile,
        [string]$JsonPath
    )

    $local:Result = &$JqExe -r $JsonPath $JsonFile 2>$TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        Write-Output "error getting '$JsonPath' from '$JsonFile': $(Get-Content -Path $TaskErrorFile)"
        return 1
    }
    if ([string]::IsNullOrEmpty($Result)) {
        Write-Output "'$JsonPath' is empty in '$JsonFile'"
        return 2
    }
    if ($Result.Equals('null')) {
        Write-Output "'$JsonPath' does not exist in '$JsonFile'"
        return 3
    }

    $script:JsonValue = $Result
}

# Gets json file field value list
# input:
#   JsonStr - Json string
#   JsonPath - Json path
# Output:
#   JsonValue - The value (list) of the field. Only if got no error.
#   If got error will output message with exit code.
function Get-JsonFileFieldValueList {
    param (
        [string]$JsonFile,
        [string]$JsonPath
    )

    $local:Result = &$JqExe -c $JsonPath $JsonFile 2>$TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        Write-Output "error getting '$JsonPath' from '$JsonFile': $(Get-Content -Path $TaskErrorFile)"
        return 1
    }
    if ($Result.Count -eq 0) {
        Write-Output "'$JsonPath' is empty in '$JsonFile'"
        return 2
    }

    $script:JsonValue = $Result
}

# Converts list to string
# Input:
#   List - List of items
# Output:
#   StrList - List of items as string
function Convert-ListToStr {
    param (
        [string[]]$List
    )

    if ($List.Count -eq 0) {
        Write-Output '@()'
        return
    }

    $local:StrList = ''
    foreach ($Item in $List) {
        if ($Item -match "^'.*'$" -or $Item -match '^".*"$') {
            $StrList += "$Item,"
        }
        else {
            $StrList += "'$Item',"
        }
    }

    $StrList = $StrList.Substring(0, $StrList.Length-1)
    Write-Output "@($StrList)"
}

# Gets param by name
# Input:
#   Params - Parameters from the agent json
#   ParamName - Parameter name
# Output:
#   TargetParam - The param json object. Only if got no error.
#   If got error will output message with exit code.
function Get-Param {
    param (
        [string[]]$Params,
        [string]$ParamName
    )

    foreach ($Param in $Params) {
        $Err = Get-JsonStrFieldValue $Param '.name'
        if ($Err.Count -ne 0) {
            Write-Output $Err[0]
            return 1
        }
        
        $local:Name = $JsonValue
        if (-Not $Name.Equals($ParamName)) {
            continue
        }

        $script:TargetParam = $Param
        return
    }

    Write-Output "$ParamName param was not found"
    return 2
}

# Gets param value
# Inputs: 
#   Params - Parameters from the agent json
#   ParamName - Parameter name to get value of
# Output:
#   ParamValue - The value of the target param. Only if got no error.
#   If got error will output message with exit code.
function Get-ParamValue {
    param (
        [string[]]$Params,
        [string]$ParamName
    )

    $local:Err = Get-Param $Params $ParamName
    if ($Err.Count -ne 0) {
        Write-Output $Err[0]
    }

    $local:Param = $TargetParam

    $Err = Get-JsonStrFieldValue $TargetParam '.value'
    if ($Err.Count -ne 0 -and $Err[1] -ne 2) {
        Write-Output $Err[0]
        return 1
    }
    if ($Err.Count -ne 0) {
        $script:ParamValue = ''
        return
    }
    
    $script:ParamValue = $JsonValue
}

# Gets param value list
# Inputs: 
#   Params - Parameters from the agent json
#   ParamName - Parameter name to get value of
# Output:
#   ParamValue - The value (list) of the target param. Only if got no error.
#   If got error will output message with exit code.
function Get-ParamValueList {
    param (
        [string[]]$Params,
        [string]$ParamName
    )

    $local:Err = Get-Param $Params $ParamName
    if ($Err.Count -ne 0) {
        Write-Output $Err[0]
    }

    $local:Param = $TargetParam

    $Err = Get-JsonStrFieldValueList $TargetParam '.value[]'
    if ($Err.Count -ne 0 -and $Err[1] -eq 1) {
        Write-Output $Err[0]
        return 1
    }
    if ($Err.Count -ne 0) {
        $script:ParamValue = @()
        return
    }
    
    $script:ParamValue = $JsonValue
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
function Invoke-Task {
    param (
        [string]$FuncName,
        [hashtable]$FuncArgs,
        [string]$Description,
        [string[]]$ScriptsToLoad
    )

    $local:Frame = '-', '\', '|', '/'
    $local:FrameInterval = 250
    $local:Timeout = 300
    $local:Counter = 0

    #[Console]::CursorVisible = $false
    
    $local:Job = Start-Job -ScriptBlock { 
        $ProgressPreference = 'SilentlyContinue'
        $WarningPreference = 'SilentlyContinue'
        . $using:LogzioTempDir\consts.ps1;
        . $using:LogzioTempDir\utils_functions.ps1;
        foreach ($ScriptToLoad in $using:ScriptsToLoad) {
            . $ScriptToLoad 
        };
        if ($using:FuncArgs.Count -eq 0) {
            &$using:FuncName
        } 
        else {
            &$using:FuncName $using:FuncArgs
        }
    }
    $local:JobState = ''

    while ($true) {
        Write-Host "`r  [   ] $Description ..." -NoNewline

        for ($i=0; $i -lt $Frame.Count; $i++) {
            Write-Host "`r  [ $($Frame[$i]) ]" -NoNewline
            Start-Sleep -Milliseconds $frameInterval
        }

        $Counter++

        $JobState = $Job.State | Write-Output
        if ($JobState.Equals("Completed")) {
            break
        }
        if ($JobState.Equals("Failed")) {
            break
        }

        if ($Counter -eq $Timeout) {
            Remove-Job -Job $Job -Force >$null
            $JobState = "Timeout"
            Write-TaskPostRun "Write-Error `"utils_functions.ps1 (2): timeout error: the task was not completed in time`""
            break
        }
    }

    Wait-Job -Job $Job | Out-Null
    $local:ExitCode = 2
    
    if (-Not $JobState.Equals("Timeout")) {
        $ExitCode = Receive-Job -Job $Job
        if ([string]::IsNullOrEmpty($ExitCode) -or $ExitCode -isnot [int]) {
            $exitCode = 0
        }
    }
    
    if (-Not $JobState.Equals("Completed") -or $ExitCode -gt 0) {
        Write-Host "`r  [ " -NoNewline
        Write-Host "X" -ForegroundColor Red -NoNewline
        Write-Host " ]" -NoNewline
        Write-Host " $Description ...`n" -ForegroundColor Red -NoNewline
        
        if (Test-Path -Path $TaskPostRunFile) {
            . $TaskPostRunFile
        }
        #Remove-TempDir
        $script:IsAgentFailed = $true
        Exit $ExitCode
    }

    Write-Host "`r  [ " -NoNewline
    Write-Host "$([char]8730)" -ForegroundColor Green -NoNewline
    Write-Host " ]" -NoNewline
    Write-Host " $Description ...`n" -ForegroundColor Green -NoNewline

    if (Test-Path -Path $TaskPostRunFile) {
        . $TaskPostRunFile
        Clear-Content $TaskPostRunFile
    }
}
