#################################################################################################################################
##################################################### WINDOWS Agent Functions ###################################################
#################################################################################################################################

# Installs ThreadJob module
# Input:
#   ---
# Output:
#   ---
function Install-ThreadJobModule {
    $local:ExitCode = 1
    $local:FuncName = $MyInvocation.MyCommand.Name

    try {
        Get-Command Start-ThreadJob -ErrorAction Stop | Out-Null
        $local:Message = "'ThreadJob' module was already installed"
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-Log $script:LogLevelDebug $Message
    }
    catch {
        try {
            Install-Module -Name 'ThreadJob' -AllowClobber -Force -ErrorAction Stop | Out-Null
            $local:Message = "'ThreadJob' module is installed successfully"
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
            Write-Log $script:LogLevelDebug $Message
        }
        catch {
            $script:IsLoadingAgentScriptsFailed = $true
            Write-Error "agent.ps1 ($ExitCode): error installing 'ThreadJob' module: $_"
            Exit $ExitCode
        }
    }
}

# Sets Windows and PowerShell info consts
# Input:
#   ---
# Output:
#   WindowsName - Windows name
#   WindowsVersion - Windows version
#   PowerShellVersion - PowerShell version
function Set-WindowsAndPowerShellInfoConsts {
    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Setting Windows consts ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $script:LogLevelDebug $Message

    $local:WindowsName = ''
    $local:WindowsVersion = ''

    try {
        $local:WindowsInfo = Get-ComputerInfo -Property WindowsProductName,OsVersion
        $WindowsName = $WindowsInfo.WindowsProductName
        $WindowsVersion = $WindowsInfo.OsVersion
    }
    catch {
        $Message = "agent.ps1 ($ExitCode): error getting computer info: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:PowerShellVersion = [string]$PSVersionTable.PSVersion
    $local:PowerShellEdition = $PSVersionTable.PSEdition

    $Message = "Windows name is '$WindowsName'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $script:LogLevelDebug $Message

    $local:WindowsNameCommand = "`$script:WindowsName = '$WindowsName'"
    Write-TaskPostRun $WindowsNameCommand

    $Message = "Windows version is '$WindowsVersion'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $LogLevelDebug $Message

    $local:WindowsVersionCommand = "`$script:WindowsVersion = '$WindowsVersion'"
    Write-TaskPostRun $WindowsVersionCommand

    $Message = "PowerShell version is '$PowerShellVersion $PowerShellEdition'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $LogLevelDebug $Message

    $local:PowerShellVersionCommand = "`$script:PowerShellVersion = '$PowerShellVersion $PowerShellEdition'"
    Write-TaskPostRun $PowerShellVersionCommand

    try {
        $WindowsNameCommand | Out-File -FilePath $script:ConstsFile -Append -Encoding utf8 -ErrorAction Stop
        $WindowsVersionCommand | Out-File -FilePath $script:ConstsFile -Append -Encoding utf8 -ErrorAction Stop
        $PowerShellVersionCommand | Out-File -FilePath $script:ConstsFile -Append -Encoding utf8 -ErrorAction Stop
    }
    catch {
        $Message = "agent.ps1 ($ExitCode): error writing to '$script:ConstsFile': $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Checks if PowerShell was run as Administrator
# Input:
#   ---
# Output:
#   ---
function Test-IsElevated {
    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if PowerShell was run as Administrator ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $script:LogLevelDebug $Message

    $local:Id = [System.Security.Principal.WindowsIdentity]::GetCurrent()

    try {
        $local:Principal = New-Object System.Security.Principal.WindowsPrincipal($Id) -ErrorAction Stop
        if ($Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
            return
        }
    }
    catch {
        $Message = "agent.ps1 ($ExitCode): error checking if PowerShell was run as Administrator"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $Message = "agent.ps1 ($ExitCode): PowerShell was not run as Administrator. please run Powershell as Administrator and rerun the agent script"
    Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-TaskPostRun "Write-Error `"$Message`""

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

    $local:ExitCode = 4
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting arguments ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('AgentArgs')
    if ($Err.Count -ne 0) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:AgentArgs = $FuncArgs.AgentArgs

    foreach ($Arg in $AgentArgs) {
        switch -Regex ($Arg) {
            --help {
                Show-Help
                Write-TaskPostRun "`$script:IsShowHelp = `$true"

                return
            }
            --url=* {
                $local:AppUrl = $Arg.Split('=', 2)[1]
                if ([string]::IsNullOrEmpty($AppUrl)) {
                    $Message = "agent.ps1 ($ExitCode): no Logz.io app URL specified!"
                    Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
                    Write-TaskPostRun "Write-Error `"$Message`""

                    return $ExitCode
                }
                
                $Message = "Agent argument 'url' is '$AppUrl'"
                Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
                Write-Log $script:LogLevelDebug $Message

                Write-TaskPostRun "`$script:AppUrl = '$AppUrl'"
                continue
            }
            --id=* {
                $local:AgentId = $Arg.Split('=', 2)[1]
                if ([string]::IsNullOrEmpty($AgentId)) {
                    $Message = "agent.ps1 ($ExitCode): no agent ID specified!"
                    Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
                    Write-TaskPostRun "Write-Error `"$Message`""

                    return $ExitCode
                }
                
                $Message = "Agent argument 'id' is '$AgentId'"
                Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
                Write-Log $script:LogLevelDebug $Message

                Write-TaskPostRun "`$script:AgentId = '$AgentId'"
                continue
            }
            --debug=* {
                $local:AgentJsonFile = $Arg.Split('=', 2)[1]
                if ([string]::IsNullOrEmpty($AgentJsonFile)) {
                    $Message = "agent.ps1 ($ExitCode): no json file specified!"
                    Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
                    Write-TaskPostRun "Write-Error `"$Message`""

                    return $ExitCode
                }

                $Message = "Agent argument 'debug' is '$AgentJsonFile'"
                Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
                Write-Log $script:LogLevelDebug $Message

                Write-TaskPostRun "`$script:AgentJsonFile = '$AgentJsonFile'"
                continue
            }
            --release=* {
                $local:RepoRelease = $Arg.Split('=', 2)[1]

                $Message = "Agent argument 'release' is '$RepoRelease'"
                Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
                Write-Log $script:LogLevelDebug $Message

                Write-TaskPostRun "`$script:RepoRelease = '$RepoRelease'"
                continue
            }
            default {
                $Message = "agent.ps1 ($ExitCode): unrecognized flag"
                Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
                Write-TaskPostRun "Write-Error `"$Message`""
                $Message = "agent.ps1 ($ExitCode): try running the agent with '--help' flag for more information"
                Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
                Write-TaskPostRun "Write-Error `"$Message`""

                return $ExitCode
            }
        }
    }
}

# Checks validation of the arguments
# Input:
#   FuncArgs - Hashtable {AppUrl = $script:AppUrl; AgentId = $script:AgentId; AgentJsonFile = $script:AgentJsonFile}
# Output:
#   ---
function Test-ArgumentsValidation {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 5
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking validation ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('AppUrl', 'AgentId', 'AgentJsonFile')
    if ($Err.Count -ne 0) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""

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
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:IsError = $false

    if ([string]::IsNullOrEmpty($AppUrl)) {
        $IsError = $true
        $Message = "agent.ps1 ($ExitCode): Logz.io app url must be specified"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""
    }
    if ([string]::IsNullOrEmpty($AgentId)) {
        $IsError = $true
        $Message = "agent.ps1 ($ExitCode): agent id must be specified"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""
    }

    if (-Not $IsError) {
        return
    }

    $Message = "agent.ps1 ($ExitCode): try running the agent with '--help' flag for more information"
    Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-TaskPostRun "Write-Error `"$Message`""

    return $ExitCode
}

# Sets agent id const
# Input:
#   FuncArgs - Hashtable {AgentId = $script:AgentId}
# Output:
#   AgentId - Agent id
function Set-AgentIdConst {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 6
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Setting agent id const ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('AgentId')
    if ($Err.Count -ne 0) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:AgentId = $FuncArgs.AgentId

    if ([string]::IsNullOrEmpty($AgentId)) {
        $AgentId = 'Debug'
    }

    $local:Message = "Agent id is '$AgentId'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $LogLevelDebug $Message

    $local:Command = "`$script:AgentId = '$AgentId'"
    Write-TaskPostRun $Command
    $Command | Out-File -FilePath $script:ConstsFile -Append -Encoding utf8
}

# Downloads jq
# Input:
#   ---
# Output:
#   Jq exe file in Logz.io temp directory
function Get-JQ {
    $local:ExitCode = 7
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Downloading jq ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepDownloads $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $script:LogLevelDebug $Message

    try {
        Invoke-WebRequest -Uri $script:JqUrlDownload -OutFile $script:JqExe | Out-Null
    }
    catch {
        $Message = "error downloading jq exe: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepDownloads $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Downloads yq
# Input:
#   ---
# Output:
#   Yq exe file in Logz.io temp directory
function Get-Yq {
    $local:ExitCode = 8
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Downloading yq ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepDownloads $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $script:LogLevelDebug $Message

    try {
        Invoke-WebRequest -Uri $script:YqUrlDownload -OutFile $script:YqExe | Out-Null
    }
    catch {
        $Message = "error downloading yq exe: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepDownloads $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Gets the agent json from the agent or local file
# Input:
#   FuncArgs - Hashtable {AppUrl = $script:AppUrl; AgentJsonFile = $script:AgentJsonFile}
# Output:
#   Agent json file in Logz.io temp directory
function Get-AgentJson {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 9
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting agent json ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('AppUrl', 'AgentJsonFile')
    if ($Err.Count -ne 0) {
        $Message = "agent.ps1 ($ExitCode): $(Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""
    }

    $local:AppUrl = $FuncArgs.AppUrl
    $local:AgentJsonFile = $FuncArgs.AgentJsonFile

    if (-Not [string]::IsNullOrEmpty($AgentJsonFile)) {
        # Using local app json file
        $Message = 'Using local agent json file ...'
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-Log $script:LogLevelDebug $Message

        try {
            Copy-Item -Path $AgentJsonFile -Destination $script:AgentJson -ErrorAction Stop
        }
        catch {
            $Message = "agent.ps1 ($ExitCode): error copying '$AgentJsonFile' to '$script:AgentJson': $_"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
            Write-TaskPostRun "Write-Error `"$Message`""

            return $ExitCode
        }

        return
    }

    # Getting agent json from agent
    $Message = 'Getting agent json from agent ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $LogLevelDebug $Message

    try {
        Invoke-WebRequest -Uri "$AppUrl/telemetry-agent/public/agents/configuration/$script:AgentID" -OutFile $script:AgentJson | Out-Null
    }
    catch {
        $Message = "agent.ps1 ($ExitCode): error getting Logz.io agent json from agent. make sure your url is valid: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:Err = Get-JsonFileFieldValue $script:AgentJson '.statusCode'
    if ($Err.Count -ne 0 -and $Err[1] -eq 1) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    if ($Err.Count -eq 0) {
        $local:StatusCode = $script:JsonValue

        $Message = "agent.ps1 ($ExitCode): error getting Logz.io agent json from agent (statusCode '$StatusCode'). make sure your id is valid."
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""
    
        return $ExitCode
    }
}

# Sets agent json consts
# input:
#   ---
# Output:
#   Platform - Platfrom name
#   SubType - Subtype name
#   DataSourceNames - List of datasource names
function Set-AgentJsonConsts {
    $local:ExitCode = 10
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Setting agent json consts ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $script:LogLevelDebug $Message
    
    $local:Err = Get-JsonFileFieldValue $script:AgentJson '.configuration.name'
    if ($Err.Count -ne 0) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:Platform = $script:JsonValue

    $Message = "Platform is '$Platform'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $script:LogLevelDebug $Message

    $local:Command = "`$script:Platform = '$Platform'"
    Write-TaskPostRun $Command
    $Command | Out-File -FilePath $script:ConstsFile -Append -Encoding utf8

    $Err = Get-JsonFileFieldValue $script:AgentJson '.configuration.subtypes[0].name'
    if ($Err.Count -ne 0) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    
    $local:SubType = $script:JsonValue

    $Message = "Subtype is '$SubType'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
    Write-Log $script:LogLevelDebug $Message

    $Command = "`$script:SubType = '$SubType'"
    Write-TaskPostRun $Command
    $Command | Out-File -FilePath $script:ConstsFile -Append -Encoding utf8
    
    $local:Err = Get-JsonFileFieldValueList $script:AgentJson '.configuration.subtypes[0].datasources[]'
    if ($Err.Count -ne 0) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:DataSources = $script:JsonValue

    $local:Index = 0
    $local:DataSourceNames = @()
    foreach ($DataSource in $DataSources) {
        $Err = Get-JsonStrFieldValue $Datasource '.name'
        if ($Err.Count -ne 0) {
            $Message = "agent.ps1 ($ExitCode): $($Err[0])"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
            Write-TaskPostRun "Write-Error `"$Message`""
    
            return $ExitCode
        }
        
        $local:DataSourceName = $script:JsonValue

        $Message = "DataSource #$($Index+1) is '$DataSourceName'"
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId
        Write-Log $script:LogLevelDebug $Message

        $DataSourceNames += $DataSourceName
        $Index++
    }

    $local:DataSourcesStr = Convert-ListToStr $DataSourceNames

    $Command = "`$script:DataSources = $DataSourcesStr"
    Write-TaskPostRun $Command
    $Command | Out-File -FilePath $script:ConstsFile -Append -Encoding utf8
}

# Gets Logz.io listener url
# Input:
#   ---
# Ouput:
#   ListenerUrl - Logz.io listener url
function Get-LogzioListenerUrl {
    $local:ExitCode = 11
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting Logz.io listener url ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Get-JsonFileFieldValue $script:AgentJson '.listenerUrl'
    if ($Err.Count -ne 0) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:ListenerUrl = $script:JsonValue

    $Message = "Logz.io listener url is '$ListenerUrl'"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:ListenerUrl = '$ListenerUrl'"
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

    $local:ExitCode = 12
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Donwloading subtype files ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
    Write-Log $script:LogLevelDebug $Message

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('RepoRelease')
    if ($Err.Count -ne 0) {
        $Message = "agent.ps1 ($ExitCode): $($Err[0])"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    $local:RepoRelease = $FuncArgs.RepoRelease

    try {
        if ([string]::IsNullOrEmpty($RepoRelease)) {
            Invoke-WebRequest -Uri "https://github.com/logzio/logzio-agent-manifest/releases/latest/download/windows_$($script:Platform.ToLower())_$($script:SubType.ToLower()).tar.gz" -OutFile $script:LogzioTempDir\windows_$($script:Platform.ToLower())_$($script:SubType.ToLower()).tar.gz | Out-Null
        }
        else {
            Invoke-WebRequest -Uri "https://github.com/logzio/logzio-agent-manifest/releases/download/$RepoRelease/windows_$($script:Platform.ToLower())_$($script:SubType.ToLower()).tar.gz" -OutFile $script:LogzioTempDir\windows_$($script:Platform.ToLower())_$($script:SubType.ToLower()).tar.gz | Out-Null
        }
    }
    catch {
        $Message = "agent.ps1 ($ExitCode): error downloading subtype tar.gz file from Logz.io repo: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
    
    tar -zxf $script:LogzioTempDir\windows_$script:Platform`_$script:SubType.tar.gz --directory $script:LogzioTempDir 2>$script:TaskErrorFile | Out-Null
    if ($LASTEXITCODE -eq 0) {
        return
    }

    $Message = "agent.ps1 ($ExitCode): error extracting files from tar.gz: $(Get-TaskErrorMessage)"
    Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
    Write-TaskPostRun "Write-Error `"$Message`""

    return $ExitCode
}

# Runs subtype prerequisites
# Input:
#   ---
# Output:
#   ---
function Invoke-SubTypePrerequisites {
    $local:ExitCode = 13
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Running subtype prerequisites ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
    Write-Log $LogLevelDebug $Message

    try {
        . "$script:LogzioTempDir\$script:Platform\$script:SubType\$script:PrerequisitesFile" -ErrorAction Stop
        if ($LASTEXITCODE -ne 0) {
            Exit $LASTEXITCODE
        }
    }
    catch {
        $Message = "agent.ps1 ($ExitCode): error running subtype prerequisites: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
        Write-Error $Message

        $script:IsAgentFailed = $true
        Exit $ExitCode
    }
}

# Runs subtype installer
# Input:
#   ---
# Output:
#   ---
function Invoke-SubTypeInstaller {
    $local:ExitCode = 14
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Running subtype installer ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
    Write-Log $script:LogLevelDebug $Message

    try {
        . "$script:LogzioTempDir\$script:Platform\$script:SubType\$script:InstallerFile" -ErrorAction Stop
        if ($LASTEXITCODE -ne 0) {
            Exit $LASTEXITCODE
        }
    }
    catch {
        $Message = "agent.ps1 ($ExitCode): error running subtype installer: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
        Write-Error $Message

        $script:IsAgentFailed = $true
        Exit $ExitCode
    }
}

# Runs subtype post-requisites
# Input:
#   ---
# Output:
#   ---
function Invoke-SubTypePostrequisites {
    $local:ExitCode = 15
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Running subtype post-requisites ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
    Write-Log $script:LogLevelDebug $Message

    try {
        . "$script:LogzioTempDir\$script:Platform\$script:SubType\$script:PostrequisitesFile" -ErrorAction Stop
        if ($LASTEXITCODE -ne 0) {
            Exit $LASTEXITCODE
        }
    }
    catch {
        $Message = "agent.ps1 ($ExitCode): error running subtype post-requisites: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInit $script:LogScriptAgent $FuncName $script:AgentId $script:Platform $script:SubType
        Write-Error $Message

        $script:IsAgentFailed = $true
        Exit $ExitCode
    }
}
