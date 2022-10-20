#################################################################################################################################
##################################################### WINDOWS Agent Functions ###################################################
#################################################################################################################################

# Sets Windows info consts
# Input:
#   ---
# Output:
#   WindowsName - Windows name
#   WindowsVersion - Windows version
function Set-WindowsInfoConsts {
    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Setting Windows consts ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
    Write-Log $LogLevelDebug $Message

    $local:WindowsName = ''
    $local:WindowsVersion = ''

    try {
        $local:WindowsInfo = Get-ComputerInfo -Property WindowsProductName,OsVersion
        $WindowsName = $WindowsInfo.WindowsProductName
        $WindowsVersion = $WindowsInfo.OsVersion
    }
    catch {
        $Message = "agent.ps1 ($ExitCode): error getting computer info: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-Log $LogLevelError $Message

        return $ExitCode
    }

    $Message = "Windows name is $WindowsName"
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
    Write-Log $LogLevelDebug $Message

    Write-TaskPostRun "`$script:WindowsName = '$WindowsName'"
    "`$script:WindowsName = '$WindowsName'" | Out-File -FilePath $LogzioTempDir\consts.ps1 -Append -Encoding utf8

    $Message = "Windows version is $WindowsVersion"
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
    Write-Log $LogLevelDebug $Message

    Write-TaskPostRun "`$script:WindowsVersion = '$WindowsVersion'"
    "`$script:WindowsVersion = '$WindowsVersion'" | Out-File -FilePath $LogzioTempDir\consts.ps1 -Append -Encoding utf8
}

# Creates Logz.io AppData directory
# Input:
#   ---
# Output:
#   ---
function New-LogzioAppDataDir {
    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name

    if (Test-Path -Path $LogzioAppDataDir) {
        $local:Message = 'Logz.io AppData directory is already exists'
        Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-Log $LogLevelDebug $Message

        return
    }

    try {
        New-Item -Path $LogzioAppDataDir -ItemType Directory -ErrorAction Stop | Out-Null
    }
    catch {
        $local:Message = "agent.ps1 ($ExitCode): error creating Logz.io AppData directory: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:Message = 'Logz.io AppData directory was created'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
    Write-Log $LogLevelDebug $Message
}

# Checks if PowerShell was run as Administrator
# Input:
#   ---
# Output:
#   ---
function Test-IsElevated {
    $local:ExitCode = 4
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if PowerShell was run as Administrator ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
    Write-Log $LogLevelDebug $Message

    $local:Id = [System.Security.Principal.WindowsIdentity]::GetCurrent()

    try {
        $local:Principal = New-Object System.Security.Principal.WindowsPrincipal($Id) -ErrorAction Stop
        if ($Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
            return
        }
    }
    catch {
        $Message = "agent.ps1 ($ExitCode): error checking if PowerShell was run as Administrator"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $Message = "agent.ps1 ($ExitCode): PowerShell was not run as Administrator. please run Powershell as Administrator and rerun the agent script"
    Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
    Write-TaskPostRun "Write-Error '$Message'"

    return $ExitCode
}

# Prints usage
# Input:
#   ---
# Output:
#   Help usage
function Show-Help {
    Write-TaskPostRun "Write-Host `"Usage: .\agent.ps1 --url=<logzio_app_url> --id=<agent_id> [--debug=<agent_json>] [--release<repo_release>]`""
    Write-TaskPostRun "Write-Host ' --url=<logzio_app_url>       Logz.io app URL (https://app.logz.io)'"
    Write-TaskPostRun "Write-Host ' --id=<agent_id>              Logz.io agent ID'"
    Write-TaskPostRun "Write-Host ' --debug=<agent_json>         Debug run using a local agent json file'"
    Write-TaskPostRun "Write-Host ' --release=<repo_release>     The release of Logz.io repo. Default is latest release'"
    Write-TaskPostRun "Write-Host ' --help                       Show usage'"
}

# Gets arguments
# Input:
#   FuncArgs - Hashtable {AgentArgs = $args}
# Output:
#   AppUrl - Logz.io app url
#   AgentId - Logz.io agent id
#   AgentJsonFile - Agent json file path (for debug)
#   RepoRelease - Repo release (for debug)
function Get-Arguments {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 5
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting arguments ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
    Write-Log $LogLevelDebug $Message

    if ($FuncArgs.Count -eq 0) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('AgentArgs')) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument does not have 'AgentArgs' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:AgentArgs = $FuncArgs.AgentArgs

    foreach ($Arg in $AgentArgs) {
        switch -Regex ($Arg) {
            --help {
                Show-Help
                Write-TaskPostRun "`$IsShowHelp = `$true"

                return
            }
            --url=* {
                $local:AppUrl = $Arg.Split('=', 2)[1]
                if ([string]::IsNullOrEmpty($AppUrl)) {
                    $Message = "agent.ps1 ($ExitCode): no Logz.io app URL specified!"
                    Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
                    Write-TaskPostRun "Write-Error '$Message'"

                    return $ExitCode
                }
                
                $Message = "Agent argument 'url' is $AppUrl"
                Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
                Write-Log $LogLevelDebug $Message

                Write-TaskPostRun "`$script:AppUrl = '$AppUrl'"
                continue
            }
            --id=* {
                $local:AgentId = $Arg.Split('=', 2)[1]
                if ([string]::IsNullOrEmpty($AgentId)) {
                    $Message = "agent.ps1 ($ExitCode): no agent ID specified!"
                    Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
                    Write-TaskPostRun "Write-Error '$Message'"

                    return $ExitCode
                }
                
                $Message = "Agent argument 'id' is $AgentId"
                Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
                Write-Log $LogLevelDebug $Message

                Write-TaskPostRun "`$script:AgentId = '$AgentId'"
                continue
            }
            --debug=* {
                $local:AgentJsonFile = $Arg.Split('=', 2)[1]
                if ([string]::IsNullOrEmpty($AgentJsonFile)) {
                    $Message = "agent.ps1 ($ExitCode): no json file specified!"
                    Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
                    Write-TaskPostRun "Write-Error '$Message'"

                    return $ExitCode
                }

                $Message = "Agent argument 'debug' is $AgentJsonFile"
                Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
                Write-Log $LogLevelDebug $Message

                Write-TaskPostRun "`$script:AgentJsonFile = '$AgentJsonFile'"
                continue
            }
            --release=* {
                $local:RepoRelease = $Arg.Split('=', 2)[1]

                $Message = "Agent argument 'release' is $RepoRelease"
                Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
                Write-Log $LogLevelDebug $Message

                Write-TaskPostRun "`$script:RepoRelease = '$RepoRelease'"
                continue
            }
            default {
                $Message = "agent.ps1 ($ExitCode): unrecognized flag"
                Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
                Write-TaskPostRun "Write-Error '$Message'"
                $Message = "agent.ps1 ($ExitCode): try '.\agent.ps1 --help' for more information"
                Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
                Write-TaskPostRun "Write-Error '$Message'"

                return $ExitCode
            }
        }
    }
}

# Checks validation of the arguments
# Input:
#   FuncArgs - Hashtable {AppUrl = $AppUrl; AgentId = $AgentId; AgentJsonFile = $AgentJsonFile}
# Output:
#   ---
function Test-ArgumentsValidation {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 6
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking validation ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
    Write-Log $LogLevelDebug $Message

    if ($FuncArgs.Count -eq 0) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('AppUrl')) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument does not contain 'AppUrl' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('AgentId')) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument does not contain 'AgentId' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('AgentJsonFile')) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument does not contain 'AgentJsonFile' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:AppUrl = $FuncArgs.AppUrl
    $local:AgentId = $FuncArgs.AgentId
    $local:AgentJsonFile = $FuncArgs.AgentJsonFile

    if (-Not [string]::IsNullOrEmpty($AgentJsonFile)) {
        if (Test-Path -Path $AgentJsonFile -PathType Leaf) {
            return
        }

        $Message = "agent.ps1 ($ExitCode): the json file '$AgentJsonFile' does not exist"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:IsError = $false

    if ([string]::IsNullOrEmpty($AppUrl)) {
        $IsError = $true
        $Message = "agent.ps1 ($ExitCode): Logz.io app url must be specified"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-TaskPostRun "Write-Error '$Message'"
    }
    if ([string]::IsNullOrEmpty($AgentId)) {
        $IsError = $true
        $Message = "agent.ps1 ($ExitCode): agent id must be specified"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-TaskPostRun "Write-Error '$Message'"
    }

    if (-Not $IsError) {
        return
    }

    $Message = "agent.ps1 ($ExitCode): try '.\agent.ps1 --help' for more information"
    Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
    Write-TaskPostRun "Write-Error '$Message'"

    return $ExitCode
}

# Sets agent id const
# Input:
#   FuncArgs - Hashtable {AgentId = $AgentId}
# Output:
#   AgentId - Agent id
function Set-AgentIdConst {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 7
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Setting agent id const ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
    Write-Log $LogLevelDebug $Message

    if ($FuncArgs.Count -eq 0) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('AgentId')) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument does not contain 'AgentId' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:AgentId = $FuncArgs.AgentId

    if ([string]::IsNullOrEmpty($AgentId)) {
        $AgentId = 'Debug'
    }

    $local:Message = "Agent id is $AgentId"
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
    Write-Log $LogLevelDebug $Message

    Write-TaskPostRun "`$script:AgentId = '$AgentId'"
    "`$script:AgentId = '$AgentId'" | Out-File -FilePath $LogzioTempDir\consts.ps1 -Append -Encoding utf8
}

# Downloads jq
# Input:
#   ---
# Output:
#   Jq exe file in Logz.io temp directory
function Get-JQ {
    $local:ExitCode = 8
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Downloading jq ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepDownloads $LogScriptAgent $FuncName $AgentId
    Write-Log $LogLevelDebug $Message

    try {
        Invoke-WebRequest -Uri 'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe' -OutFile $JqExe | Out-Null
    }
    catch {
        $Message = "error downloading jq exe: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepDownloads $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
}

# Downloads yq
# Input:
#   ---
# Output:
#   Yq exe file in Logz.io temp directory
function Get-Yq {
    $local:ExitCode = 9
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Downloading yq ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepDownloads $LogScriptAgent $FuncName $AgentId
    Write-Log $LogLevelDebug $Message

    try {
        Invoke-WebRequest -Uri 'https://github.com/mikefarah/yq/releases/download/v4.27.5/yq_windows_amd64.exe' -OutFile $YqExe | Out-Null
    }
    catch {
        $Message = "error downloading yq exe: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepDownloads $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
}

# Gets the agent json from the agent or local file
# Input:
#   FuncArgs - Hashtable {AppUrl = $AppUrl; AgentJsonFile = $AgentJsonFile}
# Output:
#   Agent json file in Logz.io temp directory
function Get-AgentJson {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 10
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting agent json ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
    Write-Log $LogLevelDebug $Message

    if ($FuncArgs.Count -eq 0) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('AppUrl')) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument does not contain 'AppUrl' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('AgentJsonFile')) {
        $Message = "Get-AppJson FuncArgs does not contain 'AgentJsonFile' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:AppUrl = $FuncArgs.AppUrl
    $local:AgentJsonFile = $FuncArgs.AgentJsonFile

    if (-Not [string]::IsNullOrEmpty($AgentJsonFile)) {
        # Using local app json file
        $local:Message = 'Using local agent json file ...'
        Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-Log $LogLevelDebug $Message

        try {
            Copy-Item -Path $AgentJsonFile -Destination $AgentJson -ErrorAction Stop
        }
        catch {
            $Message = "agent.ps1 ($ExitCode): error copying '$AgentJsonFile' to '$AgentJson': $_"
            Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
            Write-TaskPostRun "Write-Error '$Message'"

            return $ExitCode
        }

        return
    }

    # Getting agent json from agent
    $Message = 'Getting agent json from agent ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
    Write-Log $LogLevelDebug $Message

    try {
        Invoke-WebRequest -Uri $AppUrl/telemetry-agent/public/agents/configuration/$AgentID -OutFile $AgentJson | Out-Null
    }
    catch {
        $Message = "agent.ps1 ($ExitCode): error getting Logz.io agent json from agent. make sure your url is valid: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:Err = Get-JsonFileFieldValue $AgentJson '.statusCode'
    if ($Err.Count -ne 0 -and $Err[1] -eq 1) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if ($Err.Count -ne 0 -and $Err[1] -eq 3) {
        return
    }

    $local:StatusCode = $JsonValue

    $Message = "agent.ps1 ($ExitCode): error getting Logz.io agent json from agent (statusCode '$StatusCode'). make sure your id is valid."
    Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
    Write-TaskPostRun "Write-Error '$Message'"

    return $ExitCode
}

# Sets agent json consts
# input:
#   ---
# Output:
#   Platform - Platfrom name
#   SubType - Subtype name
#   DataSourceNames - List of datasource names
function Set-AgentJsonConsts {
    $local:ExitCode = 11
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Setting agent json consts ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
    Write-Log $LogLevelDebug $Message
    
    $local:Err = Get-JsonFileFieldValue $AgentJson '.configuration.name'
    if ($Err.Count -ne 0) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:Platform = $JsonValue.ToLower()

    $Message = "Platform is '$Platform'"
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
    Write-Log $LogLevelDebug $Message

    Write-TaskPostRun "`$script:Platform = '$Platform'"
    "`$script:Platform = '$Platform'" | Out-File -FilePath $LogzioTempDir\consts.ps1 -Append -Encoding utf8

    $Err = Get-JsonFileFieldValue $AgentJson '.configuration.subtypes[0].name'
    if ($Err.Count -ne 0) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    
    $local:SubType = $JsonValue.ToLower()

    $Message = "Subtype is '$SubType'"
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
    Write-Log $LogLevelDebug $Message

    Write-TaskPostRun "`$script:SubType = '$SubType'"
    "`$script:SubType = '$SubType'" | Out-File -FilePath $LogzioTempDir\consts.ps1 -Append -Encoding utf8
    
    $local:Err = Get-JsonFileFieldValueList $AgentJson '.configuration.subtypes[0].datasources[]'
    if ($Err.Count -ne 0) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:DataSources = $JsonValue

    $local:Index = 0
    $local:DataSourcesList = '@('
    $local:DataSourceNames = ''
    foreach ($DataSource in $DataSources) {
        $Err = Get-JsonStrFieldValue $Datasource '.name'
        if ($Err.Count -ne 0) {
            $Message = "agent.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
            Write-TaskPostRun "Write-Error '$Message'"
    
            return $ExitCode
        }
        
        $local:DataSourceName = $JsonValue

        $Message = "DataSource #$($Index+1) is '$DataSourceName'"
        Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-Log $LogLevelDebug $Message

        $DataSourceNames += "'$($DataSourceName.ToLower())',"
        $Index++
    }

    $DataSourceNames = $DataSourceNames.Substring(0, $DataSourceNames.Length-1)
    $DataSourcesList += "$DataSourceNames)"

    Write-TaskPostRun "`$script:DataSources = $DataSourcesList"
    "`$script:DataSources = $DataSourcesList" | Out-File -FilePath $LogzioTempDir\consts.ps1 -Append -Encoding utf8
}

# Gets Logz.io listener url
# Input:
#   ---
# Ouput:
#   ListenerUrl - Logz.io listener url
function Get-LogzioListenerUrl {
    $local:ExitCode = 12
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting Logz.io listener url ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platform $SubType
    Write-Log $LogLevelDebug $Message

    $local:Err = Get-JsonFileFieldValue $AgentJson '.listenerUrl'
    if ($Err.Count -ne 0) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platform $SubType
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:ListenerUrl = $JsonValue

    $Message = "Logz.io listener url is '$ListenerUrl'"
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platform $SubType
    Write-Log $LogLevelDebug $Message

    Write-TaskPostRun "`$script:ListenerUrl = '$ListenerUrl'"
}

# Gets Logz.io region
# Input:
#   FuncArgs - Hashtable {ListenerUrl = $ListenerUrl}
# Output:
#   LogzioRegion - Logz.io region
function Get-LogzioRegion {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 13
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = "Getting Logz.io region ..."
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platfrom $Subtype
    Write-Log $LogLevelDebug $Message

    if ($FuncArgs.Count -eq 0) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platfrom $Subtype
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('ListenerUrl')) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument does not contain 'ListenerUrl' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platfrom $Subtype
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:ListenerUrl = $FuncArgs.ListenerUrl

    $local:Region = 'us'
    if ($ListenerUrl -match ".*-.*") {
        $local:ListenerPart = $ListenerUrl.Split(".", 2)[0]
        $Region = $ListenerPart.Split("-", 2)[1]
    }
    
    $Message = "logz.io region is '$Region'"
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platfrom $Subtype
    Write-Log $LogLevelDebug $Message

    Write-TaskPostRun "`$script:LogzioRegion = '$Region'"
}

# Downloads subtype files
# Input:
#   FuncArgs - Hashtable {RepoRelease = $RepoRelease}
# Output:
#   Subtype files in Logz.io temp directory
function Get-SubTypeFiles {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 14
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Donwloading subtype files ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platform $SubType
    Write-Log $LogLevelDebug $Message

    if ($FuncArgs.Count -eq 0) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platform $SubType
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if (-Not $FuncArgs.ContainsKey('RepoRelease')) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument does not contain 'RepoRelease' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platform $SubType
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:RepoRelease = $FuncArgs.RepoRelease

    try {
        if ([string]::IsNullOrEmpty($RepoRelease)) {
            Invoke-WebRequest -Uri "https://github.com/logzio/logzio-agent-manifest/releases/latest/download/windows_$Platform`_$SubType.tar.gz" -OutFile $LogzioTempDir\windows_$Platform`_$SubType.tar.gz | Out-Null
        }
        else {
            Invoke-WebRequest -Uri "https://github.com/logzio/logzio-agent-manifest/releases/download/$RepoRelease/windows_$Platform`_$SubType.tar.gz" -OutFile $LogzioTempDir\windows_$Platform`_$SubType.tar.gz | Out-Null
        }
    }
    catch {
        $Message = "agent.ps1 ($ExitCode): error downloading subtype tar.gz file from Logz.io repo: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platform $SubType
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    
    tar -zxf $LogzioTempDir\windows_$Platform`_$SubType.tar.gz --directory $LogzioTempDir 2>$TaskErrorFile | Out-Null
    if ($LASTEXITCODE -eq 0) {
        return
    }

    $Message = "agent.ps1 ($ExitCode): error extracting files from tar.gz: $(Get-Content -Path $TaskErrorFile)"
    Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platform $SubType
    Write-TaskPostRun "Write-Error '$Message'"

    return $ExitCode
}

# Runs subtype prerequisites
# Input:
#   ---
# Output:
#   ---
function Invoke-SubTypePrerequisites {
    $local:ExitCode = 15
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Running subtype prerequisites ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platform $SubType
    Write-Log $LogLevelDebug $Message

    try {
        . $LogzioTempDir\$Platform\$SubType\$PrerequisitesFile -ErrorAction Stop
        if ($LASTEXITCODE -ne 0) {
            Exit $LASTEXITCODE
        }
    }
    catch {
        $Message = "agent.ps1 ($ExitCode): error running subtype prerequisites: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-Error $Message

        $IsAgentFailed = $true
        Exit $ExitCode
    }
}

# Runs subtype installer
# Input:
#   ---
# Output:
#   ---
function Invoke-SubTypeInstaller {
    $local:ExitCode = 16
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Running subtype installer ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platform $SubType
    Write-Log $LogLevelDebug $Message

    try {
        . $LogzioTempDir\$Platform\$SubType\$InstallerFile -ErrorAction Stop
        if ($LASTEXITCODE -ne 0) {
            Exit $LASTEXITCODE
        }
    }
    catch {
        $local:Message = "agent.ps1 ($ExitCode): error running subtype installer: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-Error $Message

        $IsAgentFailed = $true
        Exit $ExitCode
    }
}
