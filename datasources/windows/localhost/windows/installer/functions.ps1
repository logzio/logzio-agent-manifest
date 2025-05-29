#################################################################################################################################
############################################# WINDOWS Subtype Installer Functions ###############################################
#################################################################################################################################

# Checks if Logz.io OTEL collector service exists
# Input:
#   ---
# Output:
#   IsServiceExist - Tells if Logz.io OTEL collector service exists (true/false)
function Get-IsLogzioOtelCollectorServiceExist {
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Checking if Logz.io OTEL collector service exists ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $LogLevelDebug $Message

    $local:Service = Get-Service -Name $script:LogzioOtelCollectorServiceName -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($Service)) {
        $Message = "'$script:LogzioOtelCollectorServiceName' service does not exist"
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-Log $script:LogLevelDebug $Message

        Write-TaskPostRun "`$script:IsServiceExist = `$false"
        return
    }

    $Message = "'$script:LogzioOtelCollectorServiceName' service is already exists"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
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
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    try {
        Stop-Service -Name $script:LogzioOtelCollectorServiceName -ErrorAction Stop | Out-Null
    }
    catch {
        $Message = "installer.ps1 ($ExitCode): error stopping '$script:LogzioOtelCollectorServiceName' service: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""
    }

    sc.exe DELETE $script:LogzioOtelCollectorServiceName 2>$script:TaskErrorFile | Out-Null
    if ($LASTEXITCODE -ne 0) {
        $Message = "installer.ps1 ($ExitCode): error deleting '$script:LogzioOtelCollectorServiceName' service: $(Get-TaskErrorMessage)"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Downloads OTEL collector exe
# Input:
#   ---
# Output:
#   OTEL collector exe in Logz.io temp directory
function Get-OtelCollectorExe {
    $local:ExitCode = 2
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Downloading OTEL collector exe ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    try {
        Invoke-WebRequest -Uri $script:OtelCollectorUrlDownload -OutFile "$script:LogzioTempDir\otelcol-logzio.zip" | Out-Null
    }
    catch {
        $Message = "installer.ps1 ($ExitCode): error downloading OTEL collector zip: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }

    try {
        Expand-Archive -LiteralPath "$script:LogzioTempDir\otelcol-logzio.zip" -DestinationPath $script:LogzioTempDir -Force | Out-Null
    }
    catch {
        $Message = "installer.ps1 ($ExitCode): error extracting files from zip: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepPreInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Creates Logz.io AppData subdirectory
# Input:
#   ---
# Output:
#   ---
function New-LogzioAppDataSubDir {
    $local:ExitCode = 3
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Creating Logz.io AppData subdirectory ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message
    
    try {
        New-Item -Path $script:LogzioOtelCollectorDir -ItemType Directory -Force -ErrorAction Stop | Out-Null    
    }
    catch {
        $Message = "installer.ps1 ($ExitCode): error creating Logz.io OTEL collector directory: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Copies OTEL files to AppData subdirectory
# Input:
#   ---
# Output:
#   ---
function Copy-LogzioOtelFilesToAppDataSubDir {
    $local:ExitCode = 4
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Copying Logz.io OTEL files to AppData subdirectory ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    try {
        Copy-Item -Path "$script:LogzioTempDir\$script:OtelCollectorExeName" -Destination $script:LogzioOtelCollectorDir -Force -ErrorAction Stop
        Copy-Item -Path "$script:OtelResourcesDir\$script:OtelConfigName" -Destination $script:LogzioOtelCollectorDir -Force -ErrorAction Stop
    }
    catch {
        $Message = "installer.ps1 ($ExitCode): error copying OTEL files to AppData subdirectory: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        return $ExitCode
    }
}

# Runs Logz.io OTEL collector service
# Input:
#   ---
# Output:
#   ---
function Invoke-LogzioOtelCollectorService {
    $local:ExitCode = 5
    $local:FuncName = $MyInvocation.MyCommand.Name

    $local:Message = 'Running Logz.io OTEL collector service ...'
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message
    $Message = Get-Content -Path $script:OtelConfig
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    try {
        New-Service -Name $script:LogzioOtelCollectorServiceName -BinaryPathName "$script:OtelCollectorExe --config $script:OtelConfig" -Description "Collects localhost logs/metrics and sends them to Logz.io." -ErrorAction Stop | Out-Null
    }
    catch {
        $Message = "Failed to create service: $($_.Exception.Message)"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        $Message = "installer.ps1 ($ExitCode): error creating '$script:LogzioOtelCollectorServiceName' service: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        sc.exe DELETE LogzioOTELCollector 2>$script:TaskErrorFile | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $Message = "installer.ps1 ($ExitCode): error deleting '$script:LogzioOtelCollectorServiceName' service: $(Get-TaskErrorMessage)"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
            Write-TaskPostRun "Write-Warning `"$Message`""
        }

        return $ExitCode
    }

    try {
        Start-Service -Name $script:LogzioOtelCollectorServiceName -ErrorAction Stop | Out-Null
    }
    catch {
        $Message = "installer.ps1 ($ExitCode): error starting '$script:LogzioOtelCollectorServiceName' service: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""

        sc.exe DELETE LogzioOTELCollector 2>$script:TaskErrorFile | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $Message = "installer.ps1 ($ExitCode): error deleting '$script:LogzioOtelCollectorServiceName' service: $(Get-TaskErrorMessage)"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
            Write-TaskPostRun "Write-Warning `"$Message`""
        }

        return $ExitCode
    }
}
