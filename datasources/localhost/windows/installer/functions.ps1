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
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
    Write-Log $LogLevelDebug $Message

    $local:Service = Get-Service -Name $LogzioOtelCollectorServiceName -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($Service)) {
        $Message = "$LogzioOtelCollectorServiceName service does not exist"
        Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
        Write-Log $LogLevelDebug $Message

        Write-TaskPostRun "`$script:IsServiceExist = `$false"
        return
    }

    $Message = "$LogzioOtelCollectorServiceName service is already exists"
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
    Write-Log $LogLevelDebug $Message

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
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
    Write-Log $LogLevelDebug $Message

    try {
        Stop-Service -Name $LogzioOtelCollectorServiceName -ErrorAction Stop | Out-Null
    }
    catch {
        $Message = "installer.ps1 ($ExitCode): error stopping '$LogzioOtelCollectorServiceName' service: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
        Write-TaskPostRun "Write-Error `"$Message`""
    }

    sc.exe DELETE $LogzioOtelCollectorServiceName 2>$TaskErrorFile | Out-Null
    if ($LASTEXITCODE -eq 0) {
        return
    }

    $Message = "installer.ps1 ($ExitCode): error deleting '$LogzioOtelCollectorServiceName' service: $(Get-Content -Path $TaskErrorFile)"
    Send-LogToLogzio $LogLevelError $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
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
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
    Write-Log $LogLevelDebug $Message
    
    try {
        New-Item -Path $LogzioOtelCollectorDir -ItemType Directory -Force -ErrorAction Stop | Out-Null    
    }
    catch {
        $Message = "installer.ps1 ($ExitCode): error creating Logz.io OTEL collector directory: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
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
    Send-LogToLogzio $LogLevelDebug $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
    Write-Log $LogLevelDebug $Message

    try {
        Invoke-WebRequest -Uri 'https://github.com/logzio/otel-collector-distro/releases/download/v0.56.1/otelcol-logzio-windows_amd64.tar.gz' -OutFile $LogzioTempDir\otelcol-logzio.tar.gz | Out-Null
    }
    catch {
        $Message = "installer.ps1 ($ExitCode): error downloading OTEL collector tar.gz: $_"
        Send-LogToLogzio $LogLevelError $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    tar -zxf $LogzioTempDir\otelcol-logzio.tar.gz --directory $LogzioOtelCollectorDir 2>$TaskErrorFile | Out-Null
    if ($LASTEXITCODE -eq 0) {
        return
    }

    $Message = "installer.ps1 ($ExitCode): error extracting files from tar.gz: $(Get-Content -Path $TaskErrorFile)"
    Send-LogToLogzio $LogLevelError $Message $LogStepPreInstallation $LogScriptInstaller $FuncName $AgentId $Platfrom $Subtype
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
