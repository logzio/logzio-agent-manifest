# Script for automated testing of Logz.io agent manifest for Windows localhost subtypes
# This script will:
# 1. Build binary files (if requested)
# 2. Run the agent with test configuration
# 3. Validate that the agent runs successfully
# 4. Validate the collector configuration files

param(
    [Parameter(Mandatory=$false)]
    [switch]$BuildBinaries,

    [Parameter(Mandatory=$false)]
    [string]$TestConfig = "",

    [Parameter(Mandatory=$false)]
    [string]$InstallDir = "$env:ProgramFiles\Logzio\Agent-Test",

    [Parameter(Mandatory=$false)]
    [string]$TempDir = "$env:TEMP\LogzioTest"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$AssetsDir = Join-Path -Path $RootDir -ChildPath "assets"
$TestConfigsDir = Join-Path -Path $RootDir -ChildPath "testing-configs"
$LogDir = Join-Path -Path $TempDir -ChildPath "logs"
$ValidationDir = Join-Path -Path $TempDir -ChildPath "validation"
$AgentOutputFile = Join-Path -Path $LogDir -ChildPath "agent_output.log"
$AgentErrorFile = Join-Path -Path $LogDir -ChildPath "agent_error.log"

# Default URL and ID for testing - these won't be used since we're using --debug mode
$TestUrl = "https://app.logz.io"
$TestId = "test-agent-id"

# Max time to wait for agent execution (in seconds)
$MaxWaitTime = 300

# If no config specified, use the default one for Windows
if ([string]::IsNullOrEmpty($TestConfig)) {
    $TestConfig = Join-Path -Path $TestConfigsDir -ChildPath "localhost-windows-system.json"
}

# Ensure we're running from the repo root
if (-not (Test-Path -Path (Join-Path -Path $RootDir -ChildPath "Makefile"))) {
    Write-Error "Error: Must run this script from the repository root or tests directory"
    exit 1
}

# Create temp directories for testing
$null = New-Item -ItemType Directory -Path $TempDir -Force
$null = New-Item -ItemType Directory -Path $LogDir -Force
$null = New-Item -ItemType Directory -Path $ValidationDir -Force

# Create installation directory if it doesn't exist
if (-not (Test-Path -Path $InstallDir)) {
    $null = New-Item -ItemType Directory -Path $InstallDir -Force
}

Write-Host "=== Logz.io Agent Manifest - Windows Localhost Tests ==="
Write-Host "=== $(Get-Date) ==="
Write-Host "Test configuration: $TestConfig"
Write-Host "Installation directory: $InstallDir"
Write-Host ""

# Function to build the binaries using the Makefile
function Build-Binaries {
    Write-Host "Building binary files using Makefile..."
    
    Push-Location $RootDir
    try {
        # Check if we have WSL or bash
        if (Get-Command "bash.exe" -ErrorAction SilentlyContinue) {
            bash -c "make"
        } elseif (Get-Command "wsl" -ErrorAction SilentlyContinue) {
            wsl make
        } else {
            # Fallback to PowerShell's Invoke-Expression
            Invoke-Expression "make"
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Error: Failed to build binary files (exit code: $LASTEXITCODE)"
            exit 1
        }
        
        Write-Host "Binary files built successfully."
    }
    finally {
        Pop-Location
    }
    
    Write-Host ""
}

# Function to prepare the test environment
function Initialize-TestEnvironment {
    Write-Host "Preparing test environment..."
    
    # Clear previous test artifacts if they exist
    if (Test-Path -Path "$TempDir\windows") {
        Remove-Item -Path "$TempDir\windows" -Recurse -Force
    }
    
    # Clear previous installation directory contents
    Get-ChildItem -Path $InstallDir -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
    
    $WindowsDir = Join-Path -Path $TempDir -ChildPath "windows"
    $null = New-Item -ItemType Directory -Path $WindowsDir -Force
    
    # Extract Windows agent ZIP
    $AgentZip = Join-Path -Path $AssetsDir -ChildPath "agent_windows.zip"
    Write-Host "Extracting agent from $AgentZip..."
    
    if (Test-Path $AgentZip) {
        Expand-Archive -Path $AgentZip -DestinationPath $WindowsDir -Force
        Write-Host "Agent extracted successfully to $WindowsDir"
    } else {
        Write-Error "Error: Windows agent zip not found: $AgentZip"
        exit 1
    }
    
    # Verify test config exists
    if (-not (Test-Path $TestConfig)) {
        Write-Error "Error: Test configuration file not found: $TestConfig"
        exit 1
    }
    
    Write-Host "Test environment prepared successfully."
}

# Function to run the agent and capture output
function Start-AgentTest {
    Write-Host "Running Logz.io agent with test configuration..."
    
    $AgentScript = Join-Path -Path $TempDir -ChildPath "windows\agent.ps1"
    $Command = "$AgentScript --debug=$TestConfig --install-dir=$InstallDir"
    
    Write-Host "Command: $Command"
    Write-Host ""
    
    # Create a script block for the command
    $ScriptBlock = [ScriptBlock]::Create($Command)
    
    # Start the agent as a job and capture output
    $Job = Start-Job -ScriptBlock {
        param($scriptToRun, $outputFile, $errorFile)
        & $scriptToRun > $outputFile 2> $errorFile
        return $LASTEXITCODE
    } -ArgumentList $ScriptBlock, $AgentOutputFile, $AgentErrorFile
    
    # Display a dot every second while the agent is running
    Write-Host -NoNewline "Agent is running"
    $Counter = 0
    while ($Job.State -eq "Running") {
        Write-Host -NoNewline "."
        Start-Sleep -Seconds 1
        $Counter++
        
        if ($Counter -ge $MaxWaitTime) {
            Write-Host ""
            Write-Error "Error: Agent execution timed out after $MaxWaitTime seconds"
            Stop-Job -Job $Job
            Remove-Job -Job $Job -Force
            return $false
        }
    }
    
    Write-Host ""
    
    # Get the job results
    $Results = Receive-Job -Job $Job
    $ExitCode = $Results
    Remove-Job -Job $Job
    
    if ($ExitCode -ne 0) {
        Write-Host "Error: Agent execution failed with exit code $ExitCode"
        Write-Host "Agent error output:"
        if (Test-Path $AgentErrorFile) {
            Get-Content $AgentErrorFile
        } else {
            Write-Host "No error log file found."
        }
        return $false
    }
    
    Write-Host "Agent execution completed successfully in $Counter seconds."
    Write-Host ""
    
    return $true
}

# Function to validate generated OTEL configuration files
function Test-OtelConfiguration {
    Write-Host "Validating OTEL configuration..."
    
    # Define expected configuration files
    $ConfigFiles = @(
        (Join-Path -Path $InstallDir -ChildPath "otel_config.yaml")
    )
    
    # Optional files that may be generated based on configuration
    $LogsPipeline = Join-Path -Path $InstallDir -ChildPath "logs_pipeline.yaml"
    $MetricsPipeline = Join-Path -Path $InstallDir -ChildPath "metrics_pipeline.yaml"
    
    # Check if required files exist
    $MissingFiles = 0
    foreach ($File in $ConfigFiles) {
        if (-not (Test-Path $File)) {
            Write-Host "Error: Required configuration file not found: $File"
            $MissingFiles++
        } else {
            Write-Host "Found configuration file: $File"
        }
    }
    
    if ($MissingFiles -gt 0) {
        Write-Host "Error: $MissingFiles required configuration files are missing"
        return $false
    }
    
    # Extract telemetry types from the config file
    $ConfigJson = Get-Content -Raw -Path $TestConfig | ConvertFrom-Json
    $Telemetries = $ConfigJson.subtypes[0].datasources[0].telemetries
    $HasLogs = ($Telemetries | Where-Object { $_.type -eq "LOG_ANALYTICS" }).Count -gt 0
    $HasMetrics = ($Telemetries | Where-Object { $_.type -eq "METRICS" }).Count -gt 0
    
    # Check for logs pipeline if logs are enabled
    if ($HasLogs) {
        if (-not (Test-Path $LogsPipeline)) {
            Write-Host "Error: Logs pipeline configuration not found: $LogsPipeline"
            $MissingFiles++
        } else {
            Write-Host "Found logs pipeline configuration: $LogsPipeline"
            
            # Validate logs pipeline structure (basic check)
            $LogsContent = Get-Content -Raw $LogsPipeline
            if (-not ($LogsContent -match "receivers:" -and $LogsContent -match "exporters:")) {
                Write-Host "Error: Invalid logs pipeline configuration (missing receivers or exporters)"
                $MissingFiles++
            }
        }
    }
    
    # Check for metrics pipeline if metrics are enabled
    if ($HasMetrics) {
        if (-not (Test-Path $MetricsPipeline)) {
            Write-Host "Error: Metrics pipeline configuration not found: $MetricsPipeline"
            $MissingFiles++
        } else {
            Write-Host "Found metrics pipeline configuration: $MetricsPipeline"
            
            # Validate metrics pipeline structure (basic check)
            $MetricsContent = Get-Content -Raw $MetricsPipeline
            if (-not ($MetricsContent -match "receivers:" -and $MetricsContent -match "exporters:")) {
                Write-Host "Error: Invalid metrics pipeline configuration (missing receivers or exporters)"
                $MissingFiles++
            }
        }
    }
    
    # Check for Windows service registration (this is harder to validate in testing environment)
    # Could check for appropriate PowerShell code in the agent output
    
    if ($MissingFiles -gt 0) {
        Write-Host "Error: $MissingFiles configuration files or sections are invalid"
        return $false
    }
    
    Write-Host "OTEL configuration validation passed."
    return $true
}

# Function to generate a validation report
function Export-ValidationReport {
    param(
        [bool]$Success
    )
    
    $ValidationFile = Join-Path -Path $ValidationDir -ChildPath "localhost-windows-validation.txt"
    
    Write-Host "Generating validation report..."
    
    # Ensure validation directory exists
    if (-not (Test-Path $ValidationDir)) {
        $null = New-Item -ItemType Directory -Path $ValidationDir -Force
    }
    
    # Extract important parts from the test config
    $ConfigJson = Get-Content -Raw -Path $TestConfig | ConvertFrom-Json
    $Telemetries = $ConfigJson.subtypes[0].datasources[0].telemetries
    $HasLogs = ($Telemetries | Where-Object { $_.type -eq "LOG_ANALYTICS" }).Count -gt 0
    $HasMetrics = ($Telemetries | Where-Object { $_.type -eq "METRICS" }).Count -gt 0
    
    # Generate the report
    $ReportContent = @"
=== Validation Report for localhost-windows-system ===
Date: $(Get-Date)

Test Config File: $TestConfig
Installation Directory: $InstallDir
Has LOG_ANALYTICS: $HasLogs
Has METRICS: $HasMetrics

Validation Status: $($Success ? "PASSED" : "FAILED")

Generated Files:
- OTEL Configuration: $((Test-Path "$InstallDir\otel_config.yaml") ? "Found" : "Not Found (ERROR)")
"@

    # Add logs pipeline info if relevant
    if ($HasLogs) {
        $ReportContent += "`n- Logs Pipeline Configuration: $((Test-Path "$InstallDir\logs_pipeline.yaml") ? "Found" : "Not Found (ERROR)")"
    }
    
    # Add metrics pipeline info if relevant
    if ($HasMetrics) {
        $ReportContent += "`n- Metrics Pipeline Configuration: $((Test-Path "$InstallDir\metrics_pipeline.yaml") ? "Found" : "Not Found (ERROR)")"
    }
    
    # Add agent output summary
    $ReportContent += "`n`nAgent Output Summary:"
    if (Test-Path $AgentOutputFile) {
        $OutputSummary = (Get-Content $AgentOutputFile -Tail 20) -join "`n"
        $ReportContent += "`n$OutputSummary"
    } else {
        $ReportContent += "`nNo output captured"
    }
    
    # Add agent error summary
    $ReportContent += "`n`nAgent Error Summary:"
    if (Test-Path $AgentErrorFile) {
        $ErrorSummary = Get-Content $AgentErrorFile -Raw
        if ($ErrorSummary.Trim()) {
            $ReportContent += "`n$ErrorSummary"
        } else {
            $ReportContent += "`nNo errors captured"
        }
    } else {
        $ReportContent += "`nNo error log file found"
    }
    
    # Write the report to file
    Set-Content -Path $ValidationFile -Value $ReportContent
    
    Write-Host "Validation report generated: $ValidationFile"
    
    # Display report summary
    Write-Host ""
    Write-Host "=== Validation Report Summary ==="
    Write-Host "Status: $($Success ? "PASSED" : "FAILED")"
    Write-Host "Report location: $ValidationFile"
    Write-Host ""
}

# Main test execution
function Start-Tests {
    # Build binaries if explicitly requested
    if ($BuildBinaries) {
        Build-Binaries
    } else {
        Write-Host "Skipping binary build as it's not explicitly requested with -BuildBinaries"
    }
    
    # Prepare test environment
    Initialize-TestEnvironment
    
    # Run agent with test configuration
    $AgentSuccess = Start-AgentTest
    
    # Validate OTEL configuration
    $ConfigSuccess = Test-OtelConfiguration
    
    # Generate validation report
    $OverallSuccess = $AgentSuccess -and $ConfigSuccess
    Export-ValidationReport -Success $OverallSuccess
    
    Write-Host "=== Tests completed ==="
    if ($OverallSuccess) {
        Write-Host "All tests passed successfully."
        return $true
    } else {
        Write-Host "Some tests failed. Check the validation report for details."
        return $false
    }
}

# Run the main function
$TestResult = Start-Tests
if (-not $TestResult) {
    exit 1
}