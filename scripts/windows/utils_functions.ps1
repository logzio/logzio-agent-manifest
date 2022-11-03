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
    
    "[$LogLevel] [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" | Out-File -FilePath $script:AgentLogFile -Append -Encoding utf8
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

    $Command | Out-File -FilePath $script:TaskPostRunFile -Append -Encoding utf8
}

# Gets task error file content
# Input:
#   ---
# Output:
#   Task error file content
function Get-TaskErrorMessage {
    $local:Err = Get-Content -Path $script:TaskErrorFile
    $Err = $Err.Replace('"', '')

    Write-Output $Err
}

# Sends log to Logz.io
# Input:
#   Level - Log level
#   Message - Log message
#   Step - Log step
#   ScriptName - Log script name
#   FuncName - Log function name
#   AgentId - Agent id
#   Platform - Platform name
#   SubType - Subtype name
#   DataSource - Datasource name
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

    $Message = $Message.Replace('\', '\\').Replace('"', '\"')

    $local:Log = "{`"@timestamp`":`"$(Get-Date -Format 'o')`",`"level`":`"$Level`",`"message`":`"$Message`",`"step`":`"$Step`",`"script`":`"$ScriptName`",`"func`":`"$FuncName`",`"os`":`"Windows`",`"os_name`":`"$script:WindowsName`",`"os_version`":`"$script:WindowsVersion`",`"shell_version`":`"$script:PowerShellVersion`""

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
        Invoke-WebRequest -Uri $script:SqsUrl -Body $Parameters -Method Get -UseBasicParsing | Out-Null
    }
    catch {
        Write-TaskPostRun "Write-Warning `"failed to send a request with log message to Logz.io agent SQS: $_`""
    }
}

# Checks if function arguments exist
# Input:
#   FuncArgs - Hashtable of function arguments
#   ArgName - Argument names
# Output:
#   Retunrs nothing if everything ok.
#   If got error will output message with exit code.
function Test-AreFuncArgsExist {
    param (
        [hashtable]$FuncArgs,
        [string[]]$ArgNames
    )

    if ($FuncArgs.Count -eq 0) {
        Write-Output "function hashtable argument is empty"
        return 1
    }

    foreach ($ArgName in $ArgNames) {
        if (-Not $FuncArgs.ContainsKey($ArgName)) {
            Write-Output "function hashtable argument does not have '$ArgName' key"
            return 2
        }
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

    $local:Result = $JsonStr | &$script:JqExe -r $JsonPath 2>$script:TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        $JsonStr = $JsonStr.Replace('"', '`"')
        Write-Output "error getting '$JsonPath' from '$JsonStr': $(Get-TaskErrorMessage)"
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

    $local:Result = $JsonStr | &$script:JqExe -c $JsonPath 2>$script:TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        $JsonStr = $JsonStr.Replace('"', '`"')
        Write-Output "error getting '$JsonPath' from '$JsonStr': $(Get-TaskErrorMessage)"
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
#   JsonFile - Json file path
#   JsonPath - Json path
# Output:
#   JsonValue - The value of the field. Only if got no error.
#   If got error will output message with exit code.
function Get-JsonFileFieldValue {
    param (
        [string]$JsonFile,
        [string]$JsonPath
    )

    $local:Result = &$script:JqExe -r $JsonPath $JsonFile 2>$script:TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        Write-Output "error getting '$JsonPath' from '$JsonFile': $(Get-TaskErrorMessage)"
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
#   JsonFile - Json file path
#   JsonPath - Json path
# Output:
#   JsonValue - The value (list) of the field. Only if got no error.
#   If got error will output message with exit code.
function Get-JsonFileFieldValueList {
    param (
        [string]$JsonFile,
        [string]$JsonPath
    )

    $local:Result = &$script:JqExe -c $JsonPath $JsonFile 2>$script:TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        Write-Output "error getting '$JsonPath' from '$JsonFile': $(Get-TaskErrorMessage)"
        return 1
    }
    if ($Result.Count -eq 0) {
        Write-Output "'$JsonPath' is empty in '$JsonFile'"
        return 2
    }

    $script:JsonValue = $Result
}

# Adds yaml file field value
# input:
#   YamlFile - Yaml file path
#   YamlPath - Yaml path
#   Value - Value to add
# Output:
#   Returns nothing if everything ok.
#   If got error will output message with exit code.
function Add-YamlFileFieldValue {
    param (
        [string]$YamlFile,
        [string]$YamlPath,
        [string]$Value
    )

    &$script:YqExe -i "$YamlPath += ""`"$Value`"""" $YamlFile 2>$script:TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        Write-Output "error adding '$Value' to '$YamlPath in '$YamlPath': $(Get-TaskErrorMessage)"
        return 1
    }
}

# Sets yaml file field value
# input:
#   YamlFile - Yaml file path
#   YamlPath - Yaml path
#   Value - Value to set
# Output:
#   Returns nothing if everything ok.
#   If got error will output message with exit code.
function Set-YamlFileFieldValue {
    param (
        [string]$YamlFile,
        [string]$YamlPath,
        [string]$Value
    )

    &$script:YqExe -i "$YamlPath = ""`"$Value`"""" $YamlFile 2>$script:TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        Write-Output "error setting '$Value' to '$YamlPath in '$YamlFile': $(Get-TaskErrorMessage)"
        return 1
    }
}

# Gets yaml file field value
# input:
#   YamlFile - Yaml file path
#   YamlPath - Yaml path
# Output:
#   YamlValue - The value of the field. Only if got no error.
#   If got error will output message with exit code.
function Get-YamlFileFieldValue {
    param (
        [string]$YamlFile,
        [string]$YamlPath
    )

    $local:Result = &$script:YqExe $YamlPath $YamlFile 2>$script:TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        Write-Output "error getting '$YamlPath' from '$YamlFile': $(Get-TaskErrorMessage)"
        return 1
    }
    if ([string]::IsNullOrEmpty($Result)) {
        Write-Output "'$YamlPath' is empty in '$YamlFile'"
        return 2
    }
    if ($Result.Equals('null')) {
        Write-Output "'$YamlPath' does not exist in '$YamlFile'"
        return 3
    }

    $script:YamlValue = $Result
}

# Adds yaml file field value to another yaml file field
# input:
#   YamlFileSource - Source yaml file path
#   YamlFileDest - Destination yaml file path
#   YamlPathSource - Yaml path of the source yaml
#   YamlPathDest - Yaml path of the destination yaml
# Output:
#   Retunrs nothing if everything is ok.
#   If got error will output message with exit code.
function Add-YamlFileFieldValueToAnotherYamlFileField {
    param (
        [string]$YamlFileSource,
        [string]$YamlFileDest,
        [string]$YamlPathSource,
        [string]$YamlPathDest
    )

    &$script:YqExe eval-all -i "select(fileIndex==0)$YamlPathDest += select(fileIndex==1)$YamlPathSource | select(fileIndex==0)" $YamlFileDest $YamlFileSource 2>$script:TaskErrorFile
    if ($LASTEXITCODE -ne 0) {
        if ([string]::IsNullOrEmpty($YamlPathSource)) {
            $YamlPathSource = '.'
        }

        Write-Output "error adding '$YamlPathSource' in '$YamlFileSource' to '$YamlPathDest' in '$YamlFileDest': $(Get-TaskErrorMessage)"
        return 1
    }
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

# Gets Logz.io region
# Input:
#   ListenerUrl - Logz.io listener url
# Output:
#   LogzioRegion - Logz.io region
function Get-LogzioRegion {
    param (
        [string]$ListenerUrl
    )

    $local:Region = 'us'
    if ($ListenerUrl -match ".*-.*") {
        $local:ListenerPart = $ListenerUrl.Split(".", 2)[0]
        $Region = $ListenerPart.Split("-", 2)[1]
    }

    Write-Output $Region
}

# Invokes task
# Input:
#   FuncName - Function name to invoke
#   FuncArgs - Hashtable of the function arguments
#   Description - Task description that is going to be displayed
#   ScriptsToLoad - List of script names that need to be loaded before invoking the function
# Output:
#   ---
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
    
    $local:Job = Start-Job -ScriptBlock {
        $ProgressPreference = 'SilentlyContinue'
        $WarningPreference = 'SilentlyContinue'

        try {
            . $using:ConstsFile -ErrorAction Stop
            . $using:LogzioTempDir\utils_functions.ps1 --ErrorAction Stop
        }
        catch {
            $local:Message = "utils.ps1 (1): error loading agent scripts: $_"
            Send-LogToLogzio $script:LogLevelError $Message '' $script:LogScriptUtilsFunctions $FuncName $script:AgentId
            Write-TaskPostRun "Write-Error `"$Message`""

            return 1
        }

        foreach ($ScriptToLoad in $using:ScriptsToLoad) {
            try {
                . $ScriptToLoad -ErrorAction Stop
            }
            catch {
                $local:Message = "utils.ps1 (2): error loading '$ScriptToLoad' script: $_"
                Send-LogToLogzio $script:LogLevelError $Message '' $script:LogScriptUtilsFunctions $FuncName $script:AgentId
                Write-TaskPostRun "Write-Error `"$Message`""

                return 2
            }
        }

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
            Start-Sleep -Milliseconds $FrameInterval
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
            Remove-Job -Job $Job -Force | Out-Null
            $JobState = "Timeout"

            $local:Message = "timeout error: the task was not completed in time"
            Send-LogToLogzio $script:LogLevelError $Message '' $script:LogScriptAgent $FuncName $script:AgentId
            Write-TaskPostRun "Write-Error `"$Message`""
            break
        }
    }

    Wait-Job -Job $Job | Out-Null
    $local:ExitCode = 3
    
    if (-Not $JobState.Equals("Timeout")) {
        $ExitCode = Receive-Job -Job $Job
        if ([string]::IsNullOrEmpty($ExitCode) -or $ExitCode -isnot [int]) {
            $ExitCode = 0
        }
    }

    if (-Not $JobState.Equals("Completed") -or $ExitCode -ne 0) {
        Write-Host "`r  [ " -NoNewline
        Write-Host "X" -ForegroundColor Red -NoNewline
        Write-Host " ]" -NoNewline
        Write-Host " $Description ...`n" -ForegroundColor Red -NoNewline
        
        $script:IsAgentFailed = $true

        if (Test-Path -Path $script:TaskPostRunFile) {
            try {
                . $script:TaskPostRunFile -ErrorAction Stop
            }
            catch {
                $local:Message = "utils.ps1 (4): error running task post run script: $_"
                Send-LogToLogzio $script:LogLevelError $Message '' $script:LogScriptUtilsFunctions $FuncName $script:AgentId
                Write-Error $Message

                Exit 4
            }
        }

        Clear-Content $script:TaskPostRunFile
        Exit $ExitCode
    }

    Write-Host "`r  [ " -NoNewline
    Write-Host "$([char]8730)" -ForegroundColor Green -NoNewline
    Write-Host " ]" -NoNewline
    Write-Host " $Description ...`n" -ForegroundColor Green -NoNewline

    if (Test-Path -Path $script:TaskPostRunFile) {
        try {
            . $script:TaskPostRunFile -ErrorAction Stop
        }
        catch {
            $local:Message = "utils.ps1 (4): error running task post run script: $_"
            Send-LogToLogzio $script:LogLevelError $Message '' $script:LogScriptUtilsFunctions $FuncName $script:AgentId
            Write-Error $Message

            Exit 4
        }

        Clear-Content $script:TaskPostRunFile
    }
}
