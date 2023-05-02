#################################################################################################################################
###################################################### WINDOWS Agent Script #####################################################
#################################################################################################################################

# Gets agent id
# Input:
#   FuncArgs - Hashtable {AgentArgs = $args}
# Output:
#   AgentId - Logz.io agent id
function Get-AgentId {
    param (
        [hashtable]$FuncArgs
    )

    $local:Err = Test-AreFuncArgsExist $FuncArgs @('AgentArgs')
    if ($Err.Count -ne 0) {
        return
    }

    $local:AgentArgs = $FuncArgs.AgentArgs

    foreach ($Arg in $AgentArgs) {
        switch -Regex ($Arg) {
            --id=* {
                $script:AgentId = $Arg.Split('=', 2)[1]
                "`$script:AgentId = '$script:AgentId'" | Out-File -FilePath $script:ConstsFile -Append -Encoding utf8
                return
            }
        }
    }
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

    if ($IsShowHelp) {
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
        Send-LogToLogzio $script:LogLevelInfo $Message $script:LogStepFinal $script:LogScriptAgent $FuncName $script:AgentId
        Write-Log $script:LogLevelInfo $Message

        Write-AgentStatus $Message 'Red'
        Write-AgentSupport
        return
    }
    if ($script:IsPostrequisiteFailed) {
        $local:Message = 'Agent Failed'
        Send-LogToLogzio $script:LogLevelInfo $Message $script:LogStepFinal $script:LogScriptAgent $FuncName $script:AgentId
        Write-Log $script:LogLevelInfo $Message

        Write-AgentStatus $Message 'Red'
        Write-AgentInfo
        Write-AgentSupport
        return
    }
    if ($script:IsAgentCompleted) {
        $local:Message = 'Agent Completed Successfully'
        Send-LogToLogzio $script:LogLevelInfo $Message $script:LogStepFinal $script:LogScriptAgent $FuncName $script:AgentId
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
        Send-LogToLogzio $script:LogLevelInfo $Message $script:LogStepFinal $script:LogScriptAgent $FuncName $script:AgentId
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

function Write-AgentInfo {
    try {
        . "$script:LogzioTempDir\$script:Platform\$script:SubType\$script:AgentInfoFile" -ErrorAction Stop
    }
    catch {
        $local:Message = "failed to print agent info: $_"
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
$script:AgentVersion = Get-Content "$env:TEMP\Logzio\version"

# Agent id
$script:AgentId = ''

# Settings
$ProgressPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'
[Console]::CursorVisible = $false

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
    . $env:TEMP\Logzio\logo-themes\default.ps1 -ErrorAction Stop
}
catch {
    Write-Host
    Write-Host "Logz.io Agent $AgentVersion" -ForegroundColor Cyan
    Write-Host
}

try {
    # Load agent scripts
    try {
        # Load consts
        . $env:TEMP\Logzio\consts.ps1 -ErrorAction Stop
        # Load agent functions
        . $env:TEMP\Logzio\functions.ps1 -ErrorAction Stop
        # Load agent utils functions
        . $env:TEMP\Logzio\utils_functions.ps1 -ErrorAction Stop
    }
    catch {
        $local:ExitCode = 1
        $script:IsLoadingAgentScriptsFailed = $true
        Write-Host "agent.ps1 ($ExitCode): error loading agent scripts: $_" -ForegroundColor Red

        Exit $ExitCode
    }

    # Clears content of task post run script file if exists (happens if Logz.io temp directory was not deleted)
    if (Test-Path -Path $script:TaskPostRunFile -PathType Leaf) {
        Clear-Content $script:TaskPostRunFile -Force
    }

    # Get agent id
    Get-AgentId @{AgentArgs = $args}

    # Install ThreadJob module
    Install-ThreadJobModule

    # Write agent running log
    Send-LogToLogzio $script:LogLevelInfo 'Start running Logz.io agent ...' $script:LogStepPreInit $script:LogScriptAgent '' $script:AgentId
    Write-Log $script:LogLevelInfo 'Start running Logz.io agent ...'

    # Print title
    Write-Host '##########################'
    Write-Host '### ' -NoNewline
    Write-Host 'Pre-Initialization' -ForegroundColor Magenta -NoNewline
    Write-Host ' ###'
    Write-Host '##########################'

    # Set Windows and PowerShell info consts
    Invoke-Task 'Set-WindowsAndPowerShellInfoConsts' @{} 'Setting Windows and PowerShell info consts' @($script:AgentFunctionsFile)
    # Check if PowerShell was run as Administrator
    Invoke-Task 'Test-IsElevated' @{} 'Checking if PowerShell was run as Administrator' @($script:AgentFunctionsFile)
    # Get arguments
    Invoke-Task 'Get-Arguments' @{AgentArgs = $args} 'Getting arguments' @($script:AgentFunctionsFile)
    if ($script:IsShowHelp) {
        Exit 0
    }
    # Check arguments validation
    Invoke-Task 'Test-ArgumentsValidation' @{AppUrl = $script:AppUrl; AgentId = $script:AgentId; AgentJsonFile = $script:AgentJsonFile} 'Checking arguments validation' @($script:AgentFunctionsFile)
    # Set agent id const
    Invoke-Task 'Set-AgentIdConst' @{AgentId = $script:AgentId} 'Setting agent id const' @($script:AgentFunctionsFile)

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
    # Get Logz.io region
    Invoke-Task 'Get-LogzioRegion' @{ListenerUrl = $script:ListenerUrl} 'Getting Logz.io region' @($script:AgentFunctionsFile)
    # Download subtype files
    Invoke-Task 'Get-SubTypeFiles' @{RepoRelease = $script:RepoRelease} 'Donwloading subtype files' @($script:AgentFunctionsFile)

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
