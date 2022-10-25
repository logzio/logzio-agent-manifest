#################################################################################################################################
############################################### Prerequisites Windows Functions #################################################
#################################################################################################################################

# Installs yq
# Error:
#   Exit Code 1
function Install-YQ {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile
    $local:taskErrorFile = $using:taskErrorFile

    Write-Log "INFO" "Checking if yq is installed ..."

    Get-Command yq 2>&1 | Out-Null
    if ($?) {
        return
    }

    $local:result = Install-Chocolatey
    if (-Not [string]::IsNullOrEmpty($result) -and $result -gt 0) {
        return 1
    }

    Write-Log "INFO" "Installing yq ..."
    choco install yq -y 2>$using:taskErrorFile | Out-Null
    if ($?) {
        return
    }

    $local:err = Get-TaskError
    Write-Run "Write-Error `"prerequisites.ps1 (1): failed to install yq.`n  $err`""
    return 1
}

# Checks if localhost can connect to Logz.io logs (port 8071)
# Error:
#   Exit Code 2
function Test-CanLocalhostConnectToLogzioLogs {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Checking if localhost can connect to Logz.io logs (port 8071) ..."

    $ProgressPreference = "SilentlyContinue"
    $WarningPreference = "SilentlyContinue"
    $local:result = Test-NetConnection -ComputerName listener.logz.io -Port 8071 -InformationLevel Quiet
    $ProgressPreference = "Continue"
    $WarningPreference = "Continue"
    if ($result) {
        return
    }

    Write-Run "Write-Error `"prerequisites.ps1 (2): localhost cannot connect to Logz.io logs. please check your network for port 8071`""
    return 2
}

# Checks if localhost can connect to Logz.io metrics (port 8053)
# Error:
#   Exit Code 2
function Test-CanLocalhostConnectToLogzioMetrics {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Checking if localhost can connect to Logz.io metrics (port 8053) ..."

    $ProgressPreference = "SilentlyContinue"
    $WarningPreference = "SilentlyContinue"
    $local:result = Test-NetConnection -ComputerName listener.logz.io -Port 8053 -InformationLevel Quiet
    $ProgressPreference = "Continue"
    $WarningPreference = "Continue"
    if ($result) {
        return
    }

    Write-Run "Write-Error `"prerequisites.ps1 (2): localhost cannot connect to Logz.io logs. please check your network for port 8053`""
    return 2
}

# Checks if tar is installed
# Error:
#   Exit Code 3
function Test-IsTarInstalled {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Checking if tar is installed ..."

    Get-Command tar 2>&1 | Out-Null
    if ($?) {
        return
    }

    Write-Run "Write-Error `"prerequisites.ps1 (3): tar is not installed. please install it and rerun the agent script`""
    return 3
}
