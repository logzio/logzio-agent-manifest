 #################################################################################################################################
##################################################### Agent Windows Functions ###################################################
#################################################################################################################################

# Prints usage
# Output:
#   Help usage
function Show-Help {
    Write-Host "Usage: ./agent.bash --url=<logzio_app_url> --id=<agent_id> [--debug=<app_json>]"
    Write-Host " --url=<logzio_app_url>       Logz.io app URL (https://app.logz.io)"
    Write-Host " --id=<agent_id>              Logz.io agent ID"
    Write-Host " --debug=<app_json>           Debug run using a local application JSON"
    Write-Host " --help                       Show usage"
}

# Gets arguments
# Input:
#   Agent script arguments ($args)
# Output:
#   app_url - Logz.io app URL
#   agent_id - Logz.io agent ID
#   app_json_file - App JSON (only in debug)
# Error:
#   Exit Code 2
function Get-Arguments ([string[]]$agentArgs) {
    Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Getting arguments ..." >> logzio_agent.log

    for ($i=0; $i -lt $agentArgs.Count; $i++) {
        switch -Regex ($agentArgs[$i]) {
            --help {
                Show-Help
                Remove-TempDir
                Exit
            }
            --url=* {
                $global:appURL = (Write-Output $agentArgs[$i]).Split("=", 2)[1]
                if ([string]::IsNullOrEmpty($appURL)) {
                    Write-Error "agent.bash (2): no Logz.io app URL specified!"
                    Remove-TempDir
                    Exit 2
                }

                Write-Output "[INFO] [$(Get-Date -Format "yyy-MM-dd HH:mm:ss")] url = $appURL" >> logzio_agent.log
                continue
            }
            --id=* {
                $global:agentID = (Write-Output $agentArgs[$i]).Split("=", 2)[1]
                if ([string]::IsNullOrEmpty($agentID)) {
                    Write-Error "agent.bash (2): no agent ID specified!"
                    Remove-TempDir
                    Exit 2
                }

                Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] id = $agentID" >> logzio_agent.log
                continue
            }
            --debug=* {
                $global:appJsonFile = (Write-Output $agentArgs[$i]).Split("=", 2)[1]
                if ([string]::IsNullOrEmpty($appJsonFile)) {
                    Write-Error "agent.bash (2): no JSON file specified!"
                    Remove-TempDir
                    Exit 2
                }

                Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] debug = $appJsonFile" >> logzio_agent.log
                break
            }
            default {
                Write-Error "agent.bash (2): unrecognized flag"
                Write-Error "agent.bash (2): try './agent.bash --help' for more information"
                Remove-TempDir
                Exit 2
            }
        }
    }

    Test-ArgumentsValidation
}

# Checks validation of the arguments
# Error:
#   Exit Code 2
function Test-ArgumentsValidation {
    Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Checking validation ..." >> logzio_agent.log

    if (-Not [string]::IsNullOrEmpty($appJsonFile)) {
        if (Test-Path -Path $appJsonFile -PathType Leaf) {
            return
        }

        Write-Error "agent.bash (2): the JSON file $app_json_file does not exist"
        Remove-TempDir
        Exit 2
    }

    $local:isError = $false

    if ([string]::IsNullOrEmpty($appURL)) {
        $isError = $true
        Write-Error "agent.bash (2): Logz.io app URL must be specified"
    }
    if ([string]::IsNullOrEmpty($agentID)) {
        $isError = $true
        Write-Error "agent.bash (2): agent ID must be specified"
    }

    if ($isError) {
        Write-Error "agent.bash (2): try './agent.bash --help' for more information"
        Remove-TempDir
        Exit 2
    }
}


# Downloads jq exe
# Error:
#   Exit Code 3
function Install-JQ () {
    Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Checking if jq is installed ..." >> logzio_agent.log
    Get-Command jq 2>&1 | Out-Null
    if ($?) {
        $global:jq = "jq"
        return 0
    }

    Write-Output "[INFO] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Downloading jq exe ..." >> $logFile
    try {
        Invoke-WebRequest -Uri https://github.com/stedolan/jq/releases/download1/jq-1.6/jq-win64.exe -OutFile logzio-temp\jq.exe | Out-Null
        $global:jq = "logzio-temp\jq.exe"
    }
    catch {
        Write-Output $_ >> test.txt
        Write-Output $_ >> $logFile
        Write-Output "[ERROR] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] agent.ps1 (3): failed to get jq exe file from github" >> $logFile

        Write-Output "Write-Host `"$_`"" > logzio-temp\run.ps1
        Write-Output "Write-Error `"agent.ps1 (3): failed to get jq exe file from github`"" >> logzio-temp\run.ps1
        return 3
    }
}

<#
# Gets the application JSON from the agent/local file into logzio-temp directory
# Error:
#   Exit Code 4
function get_app_json () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting application JSON ..." >> logzio_agent.log

    if [[ ! -z "$app_json_file" ]]; then
        # Using local app JSON file
        echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Using local application JSON file ..." >> logzio_agent.log
        cp $app_json_file logzio-temp/app.json
        return
    fi

    # Getting app JSON from agent
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting application JSON from agent ..." >> logzio_agent.log
    curl -fsSL $app_url/telemetry-agent/public/agents/configuration/$agent_id > logzio-temp/app.json 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"agent.bash (4): failed to get Logz.io application JSON from agent. make sure your URL is valid\"" >> logzio-temp/run
        return 4
    fi

    local status_code=$(echo -e "$app_json" | jq -r '.statusCode')
    if [[ "$status_code" != null ]]; then
        echo -e "print_error \"agent.bash (4): failed to get Logz.io application JSON from agent (statusCode $status_code). make sure your ID is valid\"" > logzio-temp/run
        return 4
    fi

    echo -e "$app_json" > logzio-temp/app.json
}

# Builds path to logzio-agent-manifest repo according the app JSON
# Output:
#   repo_path - Path to logzio-agent-manifest repo according the app JSON
# Error:
#   Exit Code 5
function build_repo_path () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Building repo path ..." >> logzio_agent.log
    
    local dir1=$(jq -r '.configuration.name' logzio-temp/app.json)
    if [[ "$dir1" = null ]]; then
        echo -e "print_error \"agent.bash (5): '.configuration.name' was not found in application JSON\"" > logzio-temp/run
        return 5
    fi
    if [[ -z "$dir1" ]]; then
        echo -e "print_error \"agent.bash (5): '.configuration.name' is empty in application JSON\"" > logzio-temp/run
        return 5
    fi

    local dir2=$(jq -r '.configuration.subtypes[0].name' logzio-temp/app.json)
    if [[ "$dir2" = null ]]; then
        echo -e "print_error \"agent.bash (5): '.configuration.subtypes[0].name' was not found in application JSON\"" > logzio-temp/run
        return 5
    fi
    if [[ -z "$dir2" ]]; then
        echo -e "print_error \"agent.bash (5): '.configuration.subtypes[0].name' is empty in application JSON\"" > logzio-temp/run
        return 5
    fi

    local dir3=$(jq -r '.configuration.subtypes[0].datasources[0].name' logzio-temp/app.json)
    if [[ "$dir3" = null ]]; then
        echo -e "print_error \"agent.bash (5): '.configuration.subtypes[0].datasources[0].name' was not found in application JSON\"" > logzio-temp/run
        return 5
    fi
    if [[ -z "$dir3" ]]; then
        echo -e "print_error \"agent.bash (5): '.configuration.subtypes[0].datasources[0].name' is empty in application JSON\"" > logzio-temp/run
        return 5
    fi

    local repo_path="$repo_url/$dir1/$dir2/$dir3"
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] repo_path = $repo_path" >> logzio_agent.log
    echo -e "repo_path=\"$repo_path\"" > logzio-temp/run
}

# Gets prerequisites scripts from logzio-agent-manifest repo to logzio-temp directory
# Error:
#   Exit Code 6
function get_prerequisite_scripts () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting prerequisites script file from logzio-agent-manifest repo ..." >> logzio_agent.log
    curl -fsSL $repo_path/prerequisites/linux/prerequisites.bash > logzio-temp/prerequisites.bash 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"agent.bash (6): failed to get prerequisites script file from logzio-agent-manifest repo\"" >> logzio-temp/run
        return 6
    fi

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting prerequisites functions script file from logzio-agent-manifest repo ..." >> logzio_agent.log
    curl -fsSL $repo_path/prerequisites/linux/functions.bash > logzio-temp/prerequisites_functions.bash 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"agent.bash (6): failed to get prerequisites functions script file from logzio-agent-manifest repo\"" >> logzio-temp/run
        return 6
    fi
}

# Gets installer scripts from logzio-agent-manifest repo to logzio-temp directory
# Error:
#   Exit Code 7
function get_installer_scripts () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting installer script file from logzio-agent-manifest repo ..." >> logzio_agent.log
    curl -fsSL $repo_path/telemetry/installer/linux/installer.bash > logzio-temp/installer.bash 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"agent.bash (7): failed to get installer script file from logzio-agent-manifest repo\"" > logzio-temp/run
        return 7
    fi

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting installer functions script file from logzio-agent-manifest repo ..." >> logzio_agent.log
    curl -fsSL $repo_path/telemetry/installer/linux/functions.bash > logzio-temp/installer_functions.bash 2>logzio-temp/task_result
    if [[ $? -ne 0 ]]; then
        cat logzio-temp/task_result >> logzio_agent.log

        echo -e "cat logzio-temp/task_result" > logzio-temp/run
        echo -e "print_error \"agent.bash (7): failed to get installer functions script file from logzio-agent-manifest repo\"" > logzio-temp/run
        return 7
    fi
}
#> 
