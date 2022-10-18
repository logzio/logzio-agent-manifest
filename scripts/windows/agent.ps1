#################################################################################################################################
###################################################### WINDOWS Agent Script #####################################################
#################################################################################################################################

# Flags
$script:IsAgentCompleted = $false
$script:IsAgentFailed = $false
$script:IsShowHelp = $false

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
        Write-Host "agent.ps1 ($ExitCode): error loading agent scripts: $_" -ForegroundColor Red
        Exit $ExitCode
    }

    # Print title
    Write-Host '##########################'
    Write-Host '### ' -NoNewline
    Write-Host 'Pre-Initialization' -ForegroundColor Magenta -NoNewline
    Write-Host ' ###'
    Write-Host '##########################'

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
    # Download subtype files
    Invoke-Task 'Get-SubTypeFiles' @{RepoRelease = $RepoRelease} 'Donwloading subtype files' @($AgentFunctionsFile)

    # Run subtype prerequisites
    Invoke-SubTypePrerequisites
    if ($LASTEXITCODE -ne 0) {
        Exit $LASTEXITCODE
    }

    #Run subtype installer
    Invoke-SubTypeInstaller
    if ($LASTEXITCODE -ne 0) {
        Exit $LASTEXITCODE
    }

    $IsAgentCompleted = $true
}
finally {
    #Remove-TempDir

    if ($IsShowHelp) {
        Exit
    }
    elseif ($IsAgentFailed) {
        $local:Message = 'Agent failed'
        Send-LogToLogzio @{level = 'DEBUG'; message = $Message; step = 'Final'}
        Write-Log 'DEBUG' $Message
        Write-Host `n
        Exit
    }
    elseif (-Not $IsAgentCompleted) {
        $local:Message = 'Agent was stopped by the user'
        Send-LogToLogzio @{level = 'DEBUG'; message = $Message; step = 'Final'}
        Write-Log 'DEBUG' $Message
        Write-Host `n

        $local:Repeat = 5
        while ($Repeat -ne 0) {
            if ($Repeat % 2 -eq 0) {
                Write-Host "`r##### $Message #####" -ForegroundColor White -NoNewline
            } else {
                Write-Host "`r##### $Message #####" -ForegroundColor Yellow -NoNewline
            }

            Start-Sleep -Milliseconds 250
            $Repeat--
        }

        Write-Host `n
    }
}


<#
# Append environment variable Path
if ($env:Path -notcontains "C:\ProgramData\chocolatey\bin") {
    $env:Path += ";C:\ProgramData\chocolatey\bin"
}


# Run last preparations
Write-Host "`nlast preparations:"
Invoke-Task "Get-PrerequisitesScripts" "getting prerequisites scripts"                                  # Get prerequisites scripts
Invoke-Task "Get-InstallerScripts" "getting installer scripts"                                          # Get installer scripts

# Run prerequisites script
Write-Log "INFO" "Running prerequisites script ..."
Write-Host "`nprerequisites:"
. $logzioTempDir\prerequisites.ps1
if ($LASTEXITCODE -gt 0) {
    Exit $LASTEXITCODE
}

# Run installer script
Write-Log "INFO" "Running installer script ..."
Write-Host "`ninstaller:"
. $logzioTempDir\installer.ps1
if ($LASTEXITCODE -gt 0) {
    Exit $LASTEXITCODE
}

# Delete temp directory
Remove-TempDir
#>
