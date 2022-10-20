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

# Flags
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
                Agent v1.0.15                g:::::gg   gg:::::g                                                   
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
        $IsLoadingAgentScriptsFailed = $true
        Write-Host "agent.ps1 ($ExitCode): error loading agent scripts: $_" -ForegroundColor Red

        Exit $ExitCode
    }

    # Print title
    Write-Host '##########################'
    Write-Host '### ' -NoNewline
    Write-Host 'Pre-Initialization' -ForegroundColor Magenta -NoNewline
    Write-Host ' ###'
    Write-Host '##########################'

    # Start running agent log
    Write-Log 'INFO' 'Start running Logz.io agent ...'
    # Set Windows info consts
    Invoke-Task 'Set-WindowsInfoConsts' @{} 'Setting Windows info consts' @($AgentFunctionsFile)
    # Create Logz.io AppData directory
    Invoke-Task 'New-LogzioAppDataDir' @{} 'Creating Logz.io AppData directory' @($AgentFunctionsFile)
    # Check if PowerShell was run as Administrator
    Invoke-Task 'Test-IsElevated' @{} 'Checking if PowerShell was run as Administrator' @($AgentFunctionsFile)
    # Get arguments
    Invoke-Task 'Get-Arguments' @{AgentArgs = $args} 'Getting arguments' @($AgentFunctionsFile)
    if ($IsShowHelp) {
        Exit 0
    }
    # Check arguments validation
    Invoke-Task 'Test-ArgumentsValidation' @{AppUrl = $AppUrl; AgentId = $AgentId; AgentJsonFile = $AgentJsonFile} 'Checking arguments validation' @($AgentFunctionsFile)
    # Set agent id const
    Invoke-Task 'Set-AgentIdConst' @{AgentId = $AgentId} 'Setting agent id const' @($AgentFunctionsFile)

    # Print title
    Write-Host
    Write-Host '#################'
    Write-Host '### ' -NoNewline
    Write-Host 'Downloads' -ForegroundColor Magenta -NoNewline
    Write-Host ' ###'
    Write-Host '#################'

    # Download jq
    Invoke-Task 'Get-Jq' @{} 'Downloading jq' @($AgentFunctionsFile)
    # Download yq
    Invoke-Task 'Get-Yq' @{} 'Downloading yq' @($AgentFunctionsFile)

    # Print title
    Write-Host
    Write-Host '######################'
    Write-Host '### ' -NoNewline
    Write-Host 'Initialization' -ForegroundColor Magenta -NoNewline
    Write-Host ' ###'
    Write-Host '######################'

    # Get agent json
    Invoke-Task 'Get-AgentJson' @{AppUrl = $AppUrl; AgentJsonFile = $AgentJsonFile} 'Getting agent json' @($AgentFunctionsFile)
    # Set agent json consts
    Invoke-Task 'Set-AgentJsonConsts' @{} 'Setting agent json consts' @($AgentFunctionsFile)
    # Get Logz.io listener url
    Invoke-Task 'Get-LogzioListenerUrl' @{} 'Getting Logz.io listener url' @($AgentFunctionsFile)
    # Get Logz.io region
    Invoke-Task 'Get-LogzioRegion' @{ListenerUrl = $ListenerUrl} 'Getting Logz.io region' @($AgentFunctionsFile)
    # Download subtype files
    Invoke-Task 'Get-SubTypeFiles' @{RepoRelease = $RepoRelease} 'Donwloading subtype files' @($AgentFunctionsFile)

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
