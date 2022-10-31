#################################################################################################################################
############################################# WINDOWS Subtype Installer Functions ###############################################
#################################################################################################################################

# Checks if Logz.io OTEL collector service exists
# Input:
#   ---
# Output:
#   IsServiceExist - Tells if Logz.io OTEL collector service exist (true/false)
function Get-IsLogzioOtelCollectorServiceExist {
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if Logz.io OTEL collector service exist ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $LogLevelDebug $Message

    $local:Service = Get-Service -Name $script:LogzioOtelCollectorServiceName -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($Service)) {
        $Message = "$script:LogzioOtelCollectorServiceName service does not exist"
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-Log $script:LogLevelDebug $Message

        Write-TaskPostRun "`$script:IsServiceExist = `$false"
        return
    }

    $Message = "$script:LogzioOtelCollectorServiceName service is already exists"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    Write-TaskPostRun "`$script:IsServiceExist = `$true"
}

# Deletes Logz.io OTEL collector service
# Input:
#   ---
# Output:
#   ---
function Remove-LogzioOtelCollectorService {
    $local:ExitCode = 1
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Removing Logz.io OTEL collector service ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    try {
        Stop-Service -Name $script:LogzioOtelCollectorServiceName -ErrorAction Stop | Out-Null
    }
    catch {
        $Message = "installer.ps1 ($ExitCode): error stopping '$script:LogzioOtelCollectorServiceName' service: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""
    }

    sc.exe DELETE $script:LogzioOtelCollectorServiceName 2>$script:TaskErrorFile | Out-Null
    if ($LASTEXITCODE -eq 0) {
        return
    }

    $Message = "installer.ps1 ($ExitCode): error deleting '$script:LogzioOtelCollectorServiceName' service: $(Get-TaskErrorMessage)"
    Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-TaskPostRun "Write-Error `"$Message`""

    return $ExitCode
}

# Creates Logz.io AppData subdirectory
# Input:
#   ---
# Output:
#   ---
function New-LogzioAppDataSubDir {
    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Creating Logz.io AppData subdirectory ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message
    
    try {
        New-Item -Path $script:LogzioOtelCollectorDir -ItemType Directory -Force -ErrorAction Stop | Out-Null    
    }
    catch {
        $Message = "installer.ps1 ($ExitCode): error creating Logz.io OTEL collector directory: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Downloads OTEL collector exe
# Input:
#   ---
# Output:
#   OTEL collector exe in Logz.io AppData subdirectory
function Get-OtelCollectorExe {
    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Downloading OTEL collector exe ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    try {
        Invoke-WebRequest -Uri $script:OtelCollectorUrlDownload -OutFile $script:LogzioTempDir\otelcol-logzio.tar.gz | Out-Null
    }
    catch {
        $Message = "installer.ps1 ($ExitCode): error downloading OTEL collector tar.gz: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    tar -zxf $script:LogzioTempDir\otelcol-logzio.tar.gz --directory $script:LogzioOtelCollectorDir 2>$script:TaskErrorFile | Out-Null
    if ($LASTEXITCODE -eq 0) {
        return
    }

    $Message = "installer.ps1 ($ExitCode): error extracting files from tar.gz: $(Get-TaskErrorMessage)"
    Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platfrom $script:Subtype
    Write-TaskPostRun "Write-Error `"$Message`""

    return $ExitCode
}





# Runs Logz.io OTEL collector service
# Error:
#   Exit Code 6
function Invoke-LogzioOTELCollectorService {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile
    $local:taskErrorFile = $using:taskErrorFile

    Write-Log "INFO" "Running Logz.io OTEL collector service ..."
    Write-Log "INFO" "OTEL config =`n$(Get-Content $using:otelConfig)"

    New-Service -Name LogzioOTELCollector -BinaryPathName "$using:otelBin --config $using:otelConfig" -Description "Collects localhost logs/metrics and sends them to Logz.io." 2>$using:taskErrorFile | Out-Null
    if (-Not $?) {
        $local:err = Get-TaskError
        Write-Run "Write-Error `"installer.ps1 (6): failed to run Logzio OTEL collector service.`n  $err`""
        return 6
    }

    Start-Service -Name LogzioOTELCollector 2>$using:taskErrorFile | Out-Null
    if ($?) {
        return
    }

    sc.exe DELETE LogzioOTELCollector 2>&1 | Out-Null
    $local:err = Get-TaskError
    Write-Run "Write-Error `"installer.ps1 (6): failed to start Logzio OTEL collector service.`n  $err`""
    return 6
}
