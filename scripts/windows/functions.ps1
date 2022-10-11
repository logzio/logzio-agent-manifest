#################################################################################################################################
##################################################### WINDOWS Agent Functions ###################################################
#################################################################################################################################

# Creates Logz.io AppData directory
# Input:
#   ---
# Output:
#   ---
function New-LogzioAppDataDir {
    $local:ExitCode = 2
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
    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if PowerShell was run as Administrator ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
    Write-Log $LogLevelDebug $Message

    $local:Id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $local:Principal = New-Object System.Security.Principal.WindowsPrincipal($Id)
    if ($Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        return
    }

    $Message = "agent.ps1 ($ExitCode): PowerShell was not run as Administrator. Please run Powershell as Administrator and rerun the agent script."
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
    Write-TaskPostRun "Write-Host `"Usage: .\agent.ps1 --url=<logzio_app_url> --id=<agent_id> [--debug=<app_json>] [--branch<repo_release>]`""
    Write-TaskPostRun "Write-Host ' --url=<logzio_app_url>       Logz.io app URL (https://app.logz.io)'"
    Write-TaskPostRun "Write-Host ' --id=<agent_id>              Logz.io agent ID'"
    Write-TaskPostRun "Write-Host ' --debug=<app_json>           Debug run using a local application JSON'"
    Write-TaskPostRun "Write-Host ' --release=<repo_release>     The branch of Logz.io repo. Default is master'"
    Write-TaskPostRun "Write-Host ' --help                       Show usage'"
}

# Gets arguments
# Input:
#   FuncArgs - Hashtable {AgentArgs = $args}
# Output:
#   AppUrl - Logz.io app url
#   AgentId - Logz.io agent id
#   AppJsonFile - App json (for debug)
#   RepoRelease - Repo release (for debug)
function Get-Arguments {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 4
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
                $local:AppJsonFile = $Arg.Split('=', 2)[1]
                if ([string]::IsNullOrEmpty($AppJsonFile)) {
                    $Message = "agent.ps1 ($ExitCode): no json file specified!"
                    Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
                    Write-TaskPostRun "Write-Error '$Message'"

                    return $ExitCode
                }

                $Message = "Agent argument 'debug' is $AppJsonFile"
                Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInit $LogScriptAgent $FuncName
                Write-Log $LogLevelDebug $Message
                Write-TaskPostRun "`$script:AppJsonFile = '$AppJsonFile'"

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
#   FuncArgs - Hashtable {AppUrl = $AppUrl; AgentId = $AgentId; AppJsonFile = $AppJsonFile}
# Output:
#   ---
function Test-ArgumentsValidation {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 5
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
    if (-Not $FuncArgs.ContainsKey('AppJsonFile')) {
        $Message = "agent.ps1 ($ExitCode): function hashtable argument does not contain 'AppJsonFile' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInit $LogScriptAgent $FuncName
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:AppUrl = $FuncArgs.AppUrl
    $local:AgentId = $FuncArgs.AgentId
    $local:AppJsonFile = $FuncArgs.AppJsonFile

    if (-Not [string]::IsNullOrEmpty($AppJsonFile)) {
        if (Test-Path -Path $AppJsonFile -PathType Leaf) {
            return
        }

        $Message = "agent.ps1 ($ExitCode): the json file '$AppJsonFile' does not exist"
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

# Sets log agent id const
# Input:
#   FuncArgs - Hashtable {AgentId = $AgentId}
# Output:
#   AgentId const - Agent id
function Set-LogAgentIdConst {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 6
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Setting log agent id const ...'
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

    "`$script:AgentId = '$AgentId'" | Out-File -FilePath $LogzioTempDir\consts.ps1 -Append -Encoding utf8
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
    $local:ExitCode = 8
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

# Gets the app json from the agent or local file
# Input:
#   FuncArgs - Hashtable {AppUrl = $AppUrl; AppJsonFile = $AppJsonFile}
# Output:
#   App json file in Logz.io temp directory
function Get-AppJson {
    param (
        [hashtable]$FuncArgs
    )

    $local:ExitCode = 9
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Getting application json ...'
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
    if (-Not $FuncArgs.ContainsKey('AppJsonFile')) {
        $Message = "Get-AppJson FuncArgs does not contain 'AppJsonFile' key"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:AppUrl = $FuncArgs.AppUrl
    $local:AppJsonFile = $FuncArgs.AppJsonFile

    if (-Not [string]::IsNullOrEmpty($AppJsonFile)) {
        # Using local app json file
        $local:Message = 'Using local application json file ...'
        Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-Log $LogLevelDebug $Message

        try {
            Copy-Item -Path $AppJsonFile -Destination $AppJson -ErrorAction Stop
        }
        catch {
            $Message = "agent.ps1 ($ExitCode): error copying '$AppJsonFile' to '$AppJson': $_"
            Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
            Write-TaskPostRun "Write-Error '$Message'"

            return $ExitCode
        }

        return
    }

    # Getting app json from agent
    $Message = 'Getting application json from agent ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
    Write-Log $LogLevelDebug $Message

    try {
        Invoke-WebRequest -Uri $AppUrl/telemetry-agent/public/agents/configuration/$AgentID -OutFile $AppJson | Out-Null
    }
    catch {
        $Message = "agent.ps1 ($ExitCode): error getting Logz.io application json from agent. make sure your url is valid: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:StatusCode = &$JqExe -r '.statusCode' $AppJson
    if ($LASTEXITCODE -ne 0) {
        $Message = "agent.ps1 ($ExitCode): error getting status code from application json: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if ([string]::IsNullOrEmpty($StatusCode)) {
        $StatusCode = ''
    }
    if ($StatusCode.Equals('null')) {
        return
    }

    $Message = "agent.ps1 ($ExitCode): error getting Logz.io application json from agent (statusCode $statusCode). make sure your id is valid."
    Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
    Write-TaskPostRun "Write-Error '$Message'"

    return $ExitCode
}

# Sets log data consts
# input:
#   ---
# Output:
#   Platform const - Platfrom name
#   Subtype const - Subtype name
#   DatasourcesNum const - Number of datasources
#   Datasource{#num} const - Each datasource name
function Set-LogDataConsts {
    $local:ExitCode = 8
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Setting log data consts ...'
    Send-LogToLogzio $LogLevelDebug $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
    Write-Log $LogLevelDebug $Message
    
    $local:Platform = &$JqExe -r '.configuration.name' $AppJson
    if ($LASTEXITCODE -ne 0) {
        $Message = "agent.ps1 ($ExitCode): error getting platform from application json: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if ([string]::IsNullOrEmpty($Platform) -or $Platform.Equals('null')) {
        $Message = "agent.ps1 ($ExitCode): '.configuration.name' in application json does not exist or is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $Platform = $Platform.ToLower()
    "`$script:Platform = '$Platform'" | Out-File -FilePath $LogzioTempDir\consts.ps1 -Append -Encoding utf8

    $local:SubType = &$JqExe -r '.configuration.subtypes[0].name' $AppJson
    if ($LASTEXITCODE -ne 0) {
        $Message = "agent.ps1 ($ExitCode): error getting subtype from application json: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    if ([string]::IsNullOrEmpty($SubType) -or $SubType.Equals('null')) {
        $Message = "agent.ps1 ($ExitCode): '.configuration.subtypes[0].name' in application json does not exist or is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }
    
    $SubType = $SubType.ToLower()
    "`$script:SubType = '$SubType'" | Out-File -FilePath $LogzioTempDir\consts.ps1 -Append -Encoding utf8
    
    $local:DataSources = &$JqExe -c '.configuration.subtypes[0].datasources[]' $AppJson
    if ($LASTEXITCODE -ne 0) {
        $Message = "agent.ps1 ($ExitCode): error getting datasources from application json: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    $local:DataSourcesNum = $DataSources.Count
    if ($DataSourcesNum -eq 0) {
        $Message = "agent.ps1 ($ExitCode): '.configuration.subtypes[0].datasources[]' in application json is empty"
        Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
        Write-TaskPostRun "Write-Error '$Message'"

        return $ExitCode
    }

    "`$script:DataSourcesNum = '$DataSourcesNum'" | Out-File -FilePath $LogzioTempDir\consts.ps1 -Append -Encoding utf8

    $local:Index = 0
    foreach ($DataSource in $DataSources) {
        $local:DataSourceName = $Datasource | &$JqExe -r '.name'
        if ($LASTEXITCODE -ne 0) {
            $Message = "agent.ps1 ($ExitCode): error getting datasources[$Index] from application json: $_"
            Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
            Write-TaskPostRun "Write-Error '$Message'"

            return $ExitCode
        }
        if ([string]::IsNullOrEmpty($DataSourceName) -or $DataSourceName.Equals('null')) {
            $Message = "agent.ps1 ($ExitCode): '.configuration.subtypes[0].datasources[$Index].name' in application json does not exist or is empty"
            Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId
            Write-TaskPostRun "Write-Error '$Message'"
    
            return $ExitCode
        }

        $DataSourceName = $DataSourceName.ToLower()
        "`$script:DataSource$Index = '$DataSourceName'" | Out-File -FilePath $LogzioTempDir\consts.ps1 -Append -Encoding utf8
        $Index++
    }
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

    $local:ExitCode = 9
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
    
    tar -zxf $LogzioTempDir\windows_$Platform`_$SubType.tar.gz --directory $LogzioTempDir
    if ($LASTEXITCODE -eq 0) {
        return
    }

    $Message = "agent.ps1 ($ExitCode): error extracting files from tar.gz: $_"
    Send-LogToLogzio $LogLevelError $Message $LogStepInit $LogScriptAgent $FuncName $AgentId $Platform $SubType
    Write-TaskPostRun "Write-Error '$Message'"

    return $ExitCode
}
