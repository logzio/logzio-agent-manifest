#################################################################################################################################
###################################################### WINDOWS Agent Script #####################################################
#################################################################################################################################

# Flags
$script:IsAgentCompleted = $false
$script:IsAgentFailed = $false
$script:IsShowHelp = $false

try {
    # Print title
    Write-Host "
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
    `n" -ForegroundColor Cyan

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

    Write-Host '##########################'
    Write-Host '### Pre-Initialization ###'
    Write-Host '##########################'
    # Create Logz.io AppData directory
    Invoke-Task 'New-LogzioAppDataDir' @{} 'Creating Logz.io AppData directory' @("$LogzioTempDir\functions.ps1")
    # Check if PowerShell was run as Administrator
    Invoke-Task 'Test-IsElevated' @{} 'Checking if PowerShell was run as Administrator' @("$LogzioTempDir\functions.ps1")
    # Get arguments
    Invoke-Task 'Get-Arguments' @{AgentArgs = $args} 'Getting arguments' @("$LogzioTempDir\functions.ps1")
    if ($IsShowHelp) {
        Exit
    }
    # Check arguments validation
    Invoke-Task 'Test-ArgumentsValidation' @{AppUrl = $AppUrl; AgentId = $AgentId; AppJsonFile = $AppJsonFile} 'Checking arguments validation' @("$LogzioTempDir\functions.ps1")
    # Set agent id const
    Invoke-Task 'Set-LogAgentIdConst' @{AgentId = $AgentId} 'Setting log agent id const' @("$LogzioTempDir\functions.ps1")

    Write-Host "`n#################"
    Write-Host '### Downloads ###'
    Write-Host '#################'
    # Download jq
    Invoke-Task 'Get-Jq' @{} 'Downloading jq' @("$LogzioTempDir\functions.ps1")
    # Download yq
    Invoke-Task 'Get-Yq' @{} 'Downloading yq' @("$LogzioTempDir\functions.ps1")

    Write-Host "`n######################"
    Write-Host '### Initialization ###'
    Write-Host '######################'
    # Get app json
    Invoke-Task 'Get-AppJson' @{AppUrl = $AppUrl; AppJsonFile = $AppJsonFile} 'Getting application json' @("$LogzioTempDir\functions.ps1")
    # Set consts
    Invoke-Task 'Set-LogDataConsts' @{} 'Setting log data consts' @("$LogzioTempDir\functions.ps1")
    # Download subtype files
    Invoke-Task 'Get-SubTypeFiles' @{RepoRelease = $RepoRelease} 'Donwloading subtype files' @("$LogzioTempDir\functions.ps1")

    # Load consts script with new consts
    try {
        . $LogzioTempDir\consts.ps1 -ErrorAction Stop
    }
    catch {
        $local:ExitCode = 10
        Write-Host "agent.ps1 ($ExitCode): error loading consts script: $_" -ForegroundColor Red
        Exit $ExitCode
    }

    Write-Host "`n#####################"
    Write-Host '### Prerequisites ###'
    Write-Host '#####################'
    # Run prerequisites script
    . $LogzioTempDir\$Platform\$SubType\prerequisites\prerequisites.ps1

    $IsAgentCompleted = $true
}
finally {
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

    #Remove-TempDir
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