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
    
    # Verify the collector exe exists
    if (-not (Test-Path -Path $script:OtelCollectorExe)) {
        $Message = "installer.ps1 ($ExitCode): error starting service - OTEL collector executable not found at path: $script:OtelCollectorExe"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""
        return $ExitCode
    }
    
    # Verify the config file exists
    if (-not (Test-Path -Path $script:OtelConfig)) {
        $Message = "installer.ps1 ($ExitCode): error starting service - OTEL config file not found at path: $script:OtelConfig"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""
        return $ExitCode
    }
    
    # Log the config content for debugging
    $ConfigContent = Get-Content -Path $script:OtelConfig
    $Message = "OTEL Collector config content:`n$ConfigContent"
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message

    # First test if the collector runs successfully directly
    $Message = "Testing OTEL collector executable before service creation..."
    Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
    Write-Log $script:LogLevelDebug $Message
    
    try {
        # Run with --version to test if executable works
        $testOutput = & "$script:OtelCollectorExe" --version 2>&1
        $Message = "OTEL collector test output: $testOutput"
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-Log $script:LogLevelDebug $Message
    }
    catch {
        $Message = "installer.ps1 ($ExitCode): error testing OTEL collector executable: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""
        # Continue anyway, as the service might still work
    }

    try {
        # Create the service with LocalSystem account to ensure proper permissions
        New-Service -Name $script:LogzioOtelCollectorServiceName `
                    -BinaryPathName "$script:OtelCollectorExe --config $script:OtelConfig" `
                    -DisplayName "Logz.io OTEL Collector" `
                    -Description "Collects localhost logs/metrics and sends them to Logz.io." `
                    -StartupType Automatic `
                    -ErrorAction Stop | Out-Null
                    
        $Message = "Service created successfully"
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-Log $script:LogLevelDebug $Message
    }
    catch {
        $Message = "installer.ps1 ($ExitCode): error creating '$script:LogzioOtelCollectorServiceName' service: $_ error: $_.Exception.Message"
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

    # Set service to use LocalSystem account to ensure proper permissions
    try {
        $service = Get-WmiObject -Class Win32_Service -Filter "Name='$script:LogzioOtelCollectorServiceName'"
        $result = $service.Change($null, $null, $null, $null, $null, $null, "LocalSystem", $null, $null, $null, $null)
        if ($result.ReturnValue -ne 0) {
            $Message = "Warning: Failed to set service account to LocalSystem. Return code: $($result.ReturnValue)"
            Send-LogToLogzio $script:LogLevelWarning $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
            Write-Log $script:LogLevelWarning $Message
        }
    }
    catch {
        $Message = "Warning: Error setting service account: $_"
        Send-LogToLogzio $script:LogLevelWarning $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-Log $script:LogLevelWarning $Message
    }

    try {
        # Start the service with more detailed error handling
        $Message = "Starting service '$script:LogzioOtelCollectorServiceName'..."
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-Log $script:LogLevelDebug $Message
        
        Start-Service -Name $script:LogzioOtelCollectorServiceName -ErrorAction Stop | Out-Null
        
        # Verify service started successfully
        $serviceStatus = (Get-Service -Name $script:LogzioOtelCollectorServiceName).Status
        $Message = "Service status after starting: $serviceStatus"
        Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-Log $script:LogLevelDebug $Message
        
        if ($serviceStatus -ne 'Running') {
            throw "Service is in $serviceStatus state, not Running as expected"
        }
    }
    catch {
        # Get Windows event log information for better diagnosis
        $Message = "installer.ps1 ($ExitCode): error starting '$script:LogzioOtelCollectorServiceName' service: $_"
        Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
        Write-TaskPostRun "Write-Error `"$Message`""
        
        # Try to get event log entries to diagnose the issue
        try {
            $events = Get-EventLog -LogName System -EntryType Error -Newest 5 -Source "Service Control Manager" -ErrorAction SilentlyContinue | 
                      Where-Object { $_.Message -like "*$script:LogzioOtelCollectorServiceName*" }
            
            if ($events -and $events.Count -gt 0) {
                foreach ($event in $events) {
                    $Message = "Service error event: $($event.Message)"
                    Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
                    Write-TaskPostRun "Write-Warning `"$Message`""
                }
            }
        }
        catch {
            $Message = "Warning: Could not retrieve event log entries: $_"
            Send-LogToLogzio $script:LogLevelWarning $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
            Write-TaskPostRun "Write-Warning `"$Message`""
        }

        # Attempt to run the collector directly to see error output
        try {
            $Message = "Attempting to run collector directly to see error output"
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
            Write-Log $script:LogLevelDebug $Message
            
            $testOutput = & "$script:OtelCollectorExe" --config "$script:OtelConfig" --set=service.telemetry.logs.level=debug 2>&1
            $Message = "Direct execution output: $testOutput"
            Send-LogToLogzio $script:LogLevelDebug $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
            Write-TaskPostRun "Write-Warning `"$Message`""
        }
        catch {
            $Message = "Error running collector directly: $_"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
            Write-TaskPostRun "Write-Warning `"$Message`""
        }

        # Cleanup
        sc.exe DELETE $script:LogzioOtelCollectorServiceName 2>$script:TaskErrorFile | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $Message = "installer.ps1 ($ExitCode): error deleting '$script:LogzioOtelCollectorServiceName' service: $(Get-TaskErrorMessage)"
            Send-LogToLogzio $script:LogLevelError $Message $script:LogStepInstallation $script:LogScriptInstaller $FuncName $script:AgentId $script:Platform $script:Subtype
            Write-TaskPostRun "Write-Warning `"$Message`""
        }

        return $ExitCode
    }
}
