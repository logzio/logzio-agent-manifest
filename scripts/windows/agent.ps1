#################################################################################################################################
###################################################### WINDOWS Agent Script #####################################################
#################################################################################################################################

function Invoke-AgentFinallizer {
    $local:FuncName = $MyInvocation.MyCommand.Name

    if ($IsShowHelp) {
        Exit 0
    }
    if ($IsLoadingAgentScriptsFailed) {
        $local:Message = 'Agent Failed'
        Write-MessageRepeater $Message 'Red'
        Exit $LASTEXITCODE
    }
    if ($IsRemoveServiceAnswerNo) {
        Exit 0
    }
    if ($IsAgentFailed) {
        $local:Message = 'Agent Failed'

        if ([string]::IsNullOrEmpty($AgentId)) {
            Send-LogToLogzio $LogLevelInfo $Message $LogStepFinal $LogScriptAgent $FuncName
        }
        else {
            Send-LogToLogzio $LogLevelInfo $Message $LogStepFinal $LogScriptAgent $FuncName $AgentId
        }

        Write-Log 'INFO' $Message
        Write-MessageRepeater $Message 'Red'
        Exit $LASTEXITCODE
    }
    if ($IsAgentCompleted) {
        $local:Message = 'Agent Completed Successfully'
        Send-LogToLogzio $LogLevelInfo $Message $LogStepFinal $LogScriptAgent $FuncName $AgentId
        Write-Log 'INFO' $Message

        Write-MessageRepeater $Message 'Green'
        Exit 0
    }

    # Agent interruption
    $local:Message = 'Agent Stopped By User'
    $local:Command = Get-Command -Name Send-LogToLogzio
    if (-Not [string]::IsNullOrEmpty($Command)) {
        if ([string]::IsNullOrEmpty($AgentId)) {
            Send-LogToLogzio $LogLevelInfo $Message 'Final' 'agent.ps1' $FuncName
        }
        else {
            Send-LogToLogzio $LogLevelInfo $Message 'Final' 'agent.ps1' $FuncName $AgentId
        }
    }

    if (-Not [string]::IsNullOrEmpty($LogFile)) {
        if (Test-Path -Path $LogFile -PathType Leaf) {
            Write-Log 'INFO' $Message
        }
    }
    
    Write-MessageRepeater $Message 'Yellow'
    Exit 0
}

function Write-MessageRepeater {
    param (
        [string]$Message,
        [string]$Color
    )

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
}


# Settings
$ProgressPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'
[Console]::CursorVisible = $false

# Agent status flags
$script:IsShowHelp = $false
$script:IsLoadingAgentScriptsFailed = $false
$script:IsRemoveServiceAnswerNo = $false
$script:IsAgentFailed = $false
$script:IsAgentCompleted = $false

# Print main title
Write-Host '
    LLLLLLLLLLL                                                                             iiii                   
    L:::::::::L                                                                            i::::i                  
    L:::::::::L                                                                             iiii                   
    LL:::::::LL                                                                                                    
      L:::::L                  ooooooooooo      ggggggggg   gggggzzzzzzzzzzzzzzzzz        iiiiiii    ooooooooooo   
      L:::::L                oo:::::::::::oo   g:::::::::ggg::::gz:::::::::::::::z        i:::::i  oo:::::::::::oo 
      L:::::L               o:::::::::::::::o g:::::::::::::::::gz::::::::::::::z          i::::i o:::::::::::::::o
      L:::::L               o:::::ooooo:::::og::::::ggggg::::::ggzzzzzzzz::::::z           i::::i o:::::ooooo:::::o
      L:::::L               o::::o     o::::og:::::g     g:::::g       z::::::z            i::::i o::::o     o::::o
      L:::::L               o::::o     o::::og:::::g     g:::::g      z::::::z             i::::i o::::o     o::::o
      L:::::L               o::::o     o::::og:::::g     g:::::g     z::::::z              i::::i o::::o     o::::o
      L:::::L         LLLLLLo::::o     o::::og::::::g    g:::::g    z::::::z               i::::i o::::o     o::::o
    LL:::::::LLLLLLLLL:::::Lo:::::ooooo:::::og:::::::ggggg:::::g   z::::::zzzzzzzz        i::::::io:::::ooooo:::::o
    L::::::::::::::::::::::Lo:::::::::::::::o g::::::::::::::::g  z::::::::::::::z ...... i::::::io:::::::::::::::o
    L::::::::::::::::::::::L oo:::::::::::oo   gg::::::::::::::g z:::::::::::::::z .::::. i::::::i oo:::::::::::oo 
    LLLLLLLLLLLLLLLLLLLLLLLL   ooooooooooo       gggggggg::::::g zzzzzzzzzzzzzzzzz ...... iiiiiiii   ooooooooooo   
                                                         g:::::g                                                   
                                             gggggg      g:::::g                                                   
                Agent v1.0.18                g:::::gg   gg:::::g                                                   
                                              g::::::ggg:::::::g                                                   
                                               gg:::::::::::::g                                                    
                                                 ggg::::::ggg                                                      
                                                    gggggg                                                          
' -ForegroundColor Cyan
Write-Host

try {
    # Load agent scripts
    try {
        # Load consts
        . $env:TEMP\logzio\consts.ps1 -ErrorAction Stop
        # Load agent functions
        . $env:TEMP\logzio\functions.ps1 -ErrorAction Stop
        # Load agent utils functions
        . $env:TEMP\logzio\utils_functions.ps1 -ErrorAction Stop
    }
    catch {
        $local:ExitCode = 1
        $script:IsLoadingAgentScriptsFailed = $true
        Write-Host "agent.ps1 ($ExitCode): error loading agent scripts: $_" -ForegroundColor Red

        Exit $ExitCode
    }

    # Write agent running log
    Write-Log $script:LogLevelInfo 'Start running Logz.io agent ...' $false

    # Print title
    Write-Host '##########################'
    Write-Host '### ' -NoNewline
    Write-Host 'Pre-Initialization' -ForegroundColor Magenta -NoNewline
    Write-Host ' ###'
    Write-Host '##########################'

    # Set Windows info consts
    Invoke-Task 'Set-WindowsInfoConsts' @{} 'Setting Windows info consts' @($script:AgentFunctionsFile)
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

    #Run subtype installer
    Invoke-SubTypeInstaller

    $IsAgentCompleted = $true
}
finally {
    #Remove-TempDir
    Invoke-AgentFinallizer

    [Console]::CursorVisible = $true
}


<#
# Append environment variable Path
if ($env:Path -notcontains "C:\ProgramData\chocolatey\bin") {
    $env:Path += ";C:\ProgramData\chocolatey\bin"
}

# Delete temp directory
Remove-TempDir
#>
