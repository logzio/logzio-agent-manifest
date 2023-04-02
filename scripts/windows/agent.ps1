#################################################################################################################################
###################################################### WINDOWS Agent Script #####################################################
#################################################################################################################################

# Gets agent id
# Input:
#   AgentArgs - Script arguments ($args)
# Output:
#   AgentId - The agent id argument
function Get-AgentId {
    $local:AgentId = 'none'

    foreach ($Arg in $script:AgentArgs) {
        switch -Regex ($Arg) {
            --id=* {
                $AgentId = $Arg.Split('=', 2)[1]
                continue
            }
            --debug=* {
                $AgentId = 'debug'
                break
            }
        }
    }

    $script:AgentId = $AgentId
}

# Writes start agent message
# Input:
#   ---
# Output:
#   The message
function Write-StartAgentMessage {
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = "Start running Logz.io agent $script:AgentVersion ..."
    Send-LogToLogzio $script:LogLevelInfo $Message $script:LogStepStartAgent $script:LogScriptAgent $FuncName
    Write-Log $script:LogLevelInfo $Message
}

# Deletes Logz.io temp directory
# Input:
#   ---
# Output:
#   ---
function Remove-TempDir {
    try {
        Remove-Item -Path $script:LogzioTempDir -Recurse -ErrorAction Stop
    } 
    catch {
        Write-Warning "failed to delete Logz.io temp directory: $_"
    }
}

# Prints agent final messages
# Input:
#   ---
# Output:
#   Agent final messages
function Write-AgentFinalMessages {
    $local:FuncName = $MyInvocation.MyCommand.Name

    if ($script:IsShowHelp) {
        return
    }
    if ($script:IsLoadingAgentScriptsFailed) {
        $local:Message = 'Agent Failed'
        Write-AgentStatus $Message 'Red'
        Write-AgentSupport
        return
    }
    if ($script:IsRemoveLastRunAnswerNo) {
        Write-AgentInfo
        Write-AgentSupport
        return
    }
    if ($script:IsAgentFailed) {
        $local:Message = 'Agent Failed'
        Send-LogToLogzio $script:LogLevelInfo $Message $script:LogStepFinal $script:LogScriptAgent $FuncName
        Write-Log $script:LogLevelInfo $Message

        Write-AgentStatus $Message 'Red'
        Write-AgentSupport
        return
    }
    if ($script:IsPostrequisiteFailed) {
        $local:Message = 'Agent Failed'
        Send-LogToLogzio $script:LogLevelInfo $Message $script:LogStepFinal $script:LogScriptAgent $FuncName
        Write-Log $script:LogLevelInfo $Message

        Write-AgentStatus $Message 'Red'
        Write-AgentInfo
        Write-AgentSupport
        return
    }
    if ($script:IsAgentCompleted) {
        $local:Message = 'Agent Completed Successfully'
        Send-LogToLogzio $script:LogLevelInfo $Message $script:LogStepFinal $script:LogScriptAgent $FuncName
        Write-Log $script:LogLevelInfo $Message

        Write-AgentStatus $Message 'Green'
        Write-AgentInfo
        Write-AgentSupport
        return
    }

    # Agent interruption
    $local:Message = 'Agent Stopped By User'
    $local:Command = Get-Command -Name Send-LogToLogzio
    if (-Not [string]::IsNullOrEmpty($Command)) {
        Send-LogToLogzio $script:LogLevelInfo $Message $script:LogStepFinal $script:LogScriptAgent $FuncName
    }
    
    $Command = Get-Command -Name Write-Log
    if (-Not [string]::IsNullOrEmpty($Command)) {
        Write-Log $script:LogLevelInfo $Message
    }
    
    Write-AgentStatus $Message 'Yellow'
}

# Prints agent status
# Input:
#   ---
# Ouput:
#   Agent status
function Write-AgentStatus {
    param (
        [string]$Message,
        [string]$Color
    )

    Write-Host
    Write-Host

    $local:Repeat = 5
    while ($Repeat -ne 0) {
        if ($Repeat % 2 -eq 0) {
            Write-Host "`r##### $Message #####" -ForegroundColor White -NoNewline
        } 
        else {
            Write-Host "`r##### $Message #####" -ForegroundColor $Color -NoNewline
        }

        Start-Sleep -Milliseconds 250
        $Repeat--
    }

    Write-Host
    Write-Host
}

# Prints agent info
# Input:
#   ---
# Ouput:
#   Agent info
function Write-AgentInfo {
    try {
        . "$script:LogzioTempDir\$($script:Platform.ToLower())\$($script:SubType.ToLower())\$script:AgentInfoFile" -ErrorAction Stop
    }
    catch {
        $local:Message = "failed to print agent info: $_"
        Send-LogToLogzio $script:LogLevelWarn $Message $script:LogStepStartAgent $script:LogScriptAgent $FuncName
        Write-Warning $Message
    }
}

# Prints agent support message
# Input:
#   ---
# Output:
#   Support message 
function Write-AgentSupport {
    Write-Host
    Write-Host '###############'
    Write-Host '### ' -NoNewline
    Write-Host 'Support' -ForegroundColor Magenta -NoNewline
    Write-Host ' ###'
    Write-Host '###############'
    Write-Host 'If you have any issue, request or additional questions, our Amazing Support Team will be more than happy to assist.'
    Write-Host "You can contact us via 'help@logz.io' email or chat in Logz.io application under 'Need help?'."
    Write-Host
}


# Agent version
$script:AgentVersion = 'v1.0.44'

# Settings
$ProgressPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'
[Console]::CursorVisible = $false

# Agent args
$script:AgentArgs = $args

# Exit code
$script:ExitCode = 1

# Agent status flags
$script:IsShowHelp = $false
$script:IsLoadingAgentScriptsFailed = $false
$script:IsRemoveLastRunAnswerNo = $false
$script:IsAgentFailed = $false
$script:IsPostrequisiteFailed = $false
$script:IsAgentCompleted = $false

# Print main title
try {
    # Christmas theme
    . "$env:TEMP\Logzio\logo-themes\default.ps1" -ErrorAction Stop
}
catch {
    Write-Host
    Write-Host "Logz.io Agent $script:AgentVersion" -ForegroundColor Cyan
    Write-Host
}

try {
    # Get agent id
    Get-AgentId

    # Load agent scripts
    try {
        # Load consts
        . "$env:TEMP\Logzio\consts.ps1" -ErrorAction Stop
        # Load agent functions
        . "$env:TEMP\Logzio\functions.ps1" -ErrorAction Stop
        # Load agent utils functions
        . "$env:TEMP\Logzio\utils_functions.ps1" -ErrorAction Stop
    }
    catch {
        $script:IsLoadingAgentScriptsFailed = $true

        $local:Message = "agent.ps1 ($script:ExitCode): error loading agent scripts: $_"
        $Message = $Message.Replace('\', '\\').Replace('"', '\"')
        $local:Log = "{`"datetime`":`"$(Get-Date -Format 'o')`",`"level`":`"ERROR`",`"message`":`"$Message`",`"step`":`"Start Agent`",`"script`":`"agent.ps1`",`"func`":`"main`",`"os`":`"Windows`",`"cpu_arch`":`"$env:PROCESSOR_ARCHITECTURE`",`"agent_id`":`"$script:AgentId`"}"
        $local:Parameters = @{
            Action = 'SendMessage'
            MessageBody = $Log
        }
    
        try {
            Invoke-WebRequest -Uri 'https://sqs.us-east-1.amazonaws.com/486140753397/LogzioAgentQueue' -Body $Parameters -Method Get -UseBasicParsing | Out-Null
        }
        catch {
            Write-Host "failed to send a request with log message to Logz.io agent SQS: $_" -ForegroundColor Yellow
        }

        "[ERROR] [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" | Out-File -FilePath "$env:APPDATA\LogzioAgent\logzio_agent.log" -Append -Encoding utf8
        Write-Host "agent.ps1 ($script:ExitCode): error loading agent scripts: $_" -ForegroundColor Red
        Exit $script:ExitCode
    }

    $script:ExitCode++

    # Clears content of task post run script file if exists (happens if Logz.io temp directory was not deleted)
    if (Test-Path -Path $script:TaskPostRunFile -PathType Leaf) {
        Clear-Content -Path $script:TaskPostRunFile -Force
    }

    # Write start agent message
    Write-StartAgentMessage

    # Print title
    Write-Host '##########################'
    Write-Host '### ' -NoNewline
    Write-Host 'Pre-Initialization' -ForegroundColor Magenta -NoNewline
    Write-Host ' ###'
    Write-Host '##########################'

    # Set agent id const
    Invoke-Task 'Set-AgentIdConst' @{AgentId = $script:AgentId} 'Setting agent id const' @($script:AgentFunctionsFile)
    # Set Windows and PowerShell info consts
    Invoke-Task 'Set-WindowsAndPowerShellInfoConsts' @{} 'Setting Windows and PowerShell info consts' @($script:AgentFunctionsFile)
    # Check if PowerShell was run as Administrator
    Invoke-Task 'Test-IsElevated' @{} 'Checking if PowerShell was run as Administrator' @($script:AgentFunctionsFile)
    # Get arguments
    Invoke-Task 'Get-Arguments' @{} 'Getting arguments' @($script:AgentFunctionsFile)
    if ($script:IsShowHelp) {
        Exit 0
    }
    # Check arguments validation
    Invoke-Task 'Test-ArgumentsValidation' @{AppUrl = $script:AppUrl; AgentId = $script:AgentId; AgentJsonFile = $script:AgentJsonFile} 'Checking arguments validation' @($script:AgentFunctionsFile)

    # Print title
    Write-Host
    Write-Host '#################'
    Write-Host '### ' -NoNewline
    Write-Host 'Downloads' -ForegroundColor Magenta -NoNewline
    Write-Host ' ###'
    Write-Host '#################'

    # Download jq
    Invoke-Task 'Get-Jq' @{} 'Downloading jq' @($script:AgentFunctionsFile)
    # Download yq
    Invoke-Task 'Get-Yq' @{} 'Downloading yq' @($script:AgentFunctionsFile)

    # Print title
    Write-Host
    Write-Host '######################'
    Write-Host '### ' -NoNewline
    Write-Host 'Initialization' -ForegroundColor Magenta -NoNewline
    Write-Host ' ###'
    Write-Host '######################'

    # Get agent json
    Invoke-Task 'Get-AgentJson' @{AppUrl = $script:AppUrl; AgentJsonFile = $script:AgentJsonFile} 'Getting agent json' @($script:AgentFunctionsFile)
    # Set agent json consts
    Invoke-Task 'Set-AgentJsonConsts' @{} 'Setting agent json consts' @($script:AgentFunctionsFile)
    # Get Logz.io listener url
    Invoke-Task 'Get-LogzioListenerUrl' @{} 'Getting Logz.io listener url' @($script:AgentFunctionsFile)
    # Download subtype files
    Invoke-Task 'Get-SubTypeFiles' @{RepoRelease = $script:RepoRelease} 'Donwloading subtype files' @($script:AgentFunctionsFile)
    Exit

    # Run subtype prerequisites
    Invoke-SubTypePrerequisites

    # Run subtype installer
    Invoke-SubTypeInstaller

    if (-Not $script:IsRemoveLastRunAnswerNo) {
        # Run subtype post-requisites
        Invoke-SubTypePostrequisites
    }
    
    $script:IsAgentCompleted = $true
}
finally {
    Write-AgentFinalMessages
    Remove-TempDir
    
    [Console]::CursorVisible = $true
}
