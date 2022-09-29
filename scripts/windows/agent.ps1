#################################################################################################################################
###################################################### WINDOWS Agent Script #####################################################
#################################################################################################################################

# Load consts
. $env:TEMP\logzio\consts.ps1

# Load agent functions
#Write-Output "[INFO] [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Loading agent functions ..." >> $LogFile
. $env:TEMP\logzio\functions.ps1
. $env:TEMP\logzio\utils_functions.ps1

# Check if PowerShell was run as Administrator
Test-IsElevated

<#
# Get arguments and check validation
Get-Arguments $args

# Set default repo branch
if ([string]::IsNullOrEmpty($repoBranch)) {
    $repoBranch = "master"
    Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] branch = master (default)" >> $logFile
}

# Consts
$script:repoURL = "https://raw.githubusercontent.com/logzio/logzio-agent-manifest/$repoBranch"          # logzio-agent-manifest repo URL

# Create temp directory with files
if (-Not (Test-Path $logzioTempDir)) {
    New-Item -Path $logzioTempDir -ItemType Directory | Out-Null    
}

$null > $runFile
$null > $taskErrorFile

# Get agent functions scripts
Get-AgentFunctionsScripts

# Load agent functions
Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Loading agent functions ..." >> $logFile
. $logzioTempDir\agent_functions.ps1
. $logzioTempDir\utils_functions.ps1

# Append environment variable Path
if ($env:Path -notcontains "C:\ProgramData\chocolatey\bin") {
    $env:Path += ";C:\ProgramData\chocolatey\bin"
}

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
                                         g:::::gg   gg:::::g                                                   
                                          g::::::ggg:::::::g                                                   
                                           gg:::::::::::::g                                                    
                                             ggg::::::ggg                                                      
                                                gggggg                                                         
" -ForegroundColor Cyan
Write-Host "Running " -NoNewline
Write-Host "Logz.io " -ForegroundColor Cyan -NoNewline
Write-Host "Agent:`n`n" -NoNewline

# Run prerequisite installations
Write-Host "prerequisite installations:"
Invoke-Task "Install-JQ" "installing jq"                                                                # Install jq

# Run last preparations
Write-Host "`nlast preparations:"
Invoke-Task "Get-AppJSON" "getting application JSON"                                                    # Get app JSON
Invoke-Task "Build-RepoPath" "building path to logzio-agent-manifest repo"                              # Build repo path to logzio-agent-manifest rep
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