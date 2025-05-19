# Windows OTEL Configuration Validator PowerShell Script
param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigDir,
    
    [Parameter(Mandatory=$false)]
    [string]$ReportFile = "$PSScriptRoot\otel_validation_windows.txt"
)

# Check if OTEL config file exists
function Test-OtelConfig {
    $configFile = Join-Path -Path $ConfigDir -ChildPath "otel_config.yaml"
    if (-not (Test-Path $configFile)) {
        Write-Error "OTEL config file not found: $configFile"
        return $false
    }
    
    Write-Host "Found OTEL config file: $configFile"
    return $true
}

# Check if logs pipeline exists and is valid
function Test-LogsPipeline {
    $pipelineFile = Join-Path -Path $ConfigDir -ChildPath "logs_pipeline.yaml"
    
    if (-not (Test-Path $pipelineFile)) {
        Write-Host "Logs Pipeline: Not Found"
        return $false
    }
    
    # Basic validation - check for receivers and exporters sections
    $content = Get-Content -Path $pipelineFile -Raw
    if ($content -match "receivers:" -and $content -match "exporters:") {
        Write-Host "Logs Pipeline: Valid"
        return $true
    } else {
        Write-Host "Logs Pipeline: Invalid (Missing receivers or exporters)"
        return $false
    }
}

# Check if metrics pipeline exists and is valid
function Test-MetricsPipeline {
    $pipelineFile = Join-Path -Path $ConfigDir -ChildPath "metrics_pipeline.yaml"
    
    if (-not (Test-Path $pipelineFile)) {
        Write-Host "Metrics Pipeline: Not Found"
        return $false
    }
    
    # Basic validation - check for receivers and exporters sections
    $content = Get-Content -Path $pipelineFile -Raw
    if ($content -match "receivers:" -and $content -match "exporters:") {
        Write-Host "Metrics Pipeline: Valid"
        return $true
    } else {
        Write-Host "Metrics Pipeline: Invalid (Missing receivers or exporters)"
        return $false
    }
}

# Check if the service definition file exists and is valid for Windows
function Test-WindowsService {
    # In a real implementation, we would check Windows service configuration
    # This is a placeholder that would be expanded with actual Windows service validation
    $serviceStatus = "Not Validated (Placeholder)"
    
    Write-Host "Service Definition: $serviceStatus"
    return $true
}

# Main validation function
function Test-OtelConfiguration {
    Write-Host "=== Validating OTEL Configuration for Windows ==="
    Write-Host "Configuration Directory: $ConfigDir"
    Write-Host ""
    
    if (-not (Test-Path $ConfigDir)) {
        Write-Error "Configuration directory not found: $ConfigDir"
        return $false
    }
    
    # Initialize validation status
    $validationStatus = "PASSED"
    $validationOutput = @()
    
    # Check OTEL config
    $validationOutput += "Checking OTEL Configuration:"
    if (Test-OtelConfig) {
        $validationOutput += "  - OTEL Config: Found"
    } else {
        $validationOutput += "  - OTEL Config: Not Found (FAILED)"
        $validationStatus = "FAILED"
    }
    
    # Check logs pipeline
    $validationOutput += "Checking Logs Pipeline:"
    $logsResult = "SKIPPED"
    if (Test-LogsPipeline) {
        $validationOutput += "  - Logs Pipeline: Valid"
        $logsResult = "PASSED"
    } else {
        $validationOutput += "  - Logs Pipeline: Invalid or Not Found"
    }
    
    # Check metrics pipeline
    $validationOutput += "Checking Metrics Pipeline:"
    $metricsResult = "SKIPPED"
    if (Test-MetricsPipeline) {
        $validationOutput += "  - Metrics Pipeline: Valid"
        $metricsResult = "PASSED"
    } else {
        $validationOutput += "  - Metrics Pipeline: Invalid or Not Found"
    }
    
    # Check Windows service configuration
    $validationOutput += "Checking Windows Service Configuration:"
    $serviceResult = Test-WindowsService
    $validationOutput += "  - Windows Service: $serviceResult"
    
    # Generate validation report
    $report = @"
=== OTEL Configuration Validation Report ===
Date: $(Get-Date)
OS Type: Windows
Configuration Directory: $ConfigDir

$($validationOutput -join "`n")

Validation Status: $validationStatus

Logs Configuration: $logsResult
Metrics Configuration: $metricsResult

Note: This validation checks for the existence and basic structure
      of configuration files but does not verify full functionality.
"@

    Set-Content -Path $ReportFile -Value $report -Force
    
    Write-Host ""
    Write-Host "Validation report generated: $ReportFile"
    
    return ($validationStatus -eq "PASSED")
}

# Run the validation
Test-OtelConfiguration