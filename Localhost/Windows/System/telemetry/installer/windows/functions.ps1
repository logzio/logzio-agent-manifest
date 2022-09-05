#################################################################################################################################
################################################# Installer Windows Functions ###################################################
#################################################################################################################################

# Checks if Logz.io OTEL collector service exist
# Output:
#   isServiceExist - Tells if Logz.io OTEL collector service exist
function Get-IsLogzioOTELCollectorServiceExist {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Checking if Logz.io OTEL collector service exist ..."
    $local:service = Get-Service -Name LogzioOTELCollector 2>$null
    if ([string]::IsNullOrEmpty($service)) {
        Write-Log "isServiceExist = false"
        Write-Run "`$script:isServiceExist = `$false"
        return
    }

    Write-Log "isServiceExist = true"
    Write-Run "`$script:isServiceExist = `$true"
}

# Gets the selected products (logs/metrics)
# Output:
#   isLogsOptionSelected - Tells if logs option was selected (true/false)
#   logsParams - The logs params if logs option was selected
#   isMetricsOptionSelected - Tells if metrics option was selected (true/false)
#   metricsParams - The metrics params if metrics option was selected
# Error:
#   Exit Code 1
function Get-SelectedProducts {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting the selected products ..."

    $local:telemetries = jq -c '.configuration.subtypes[0].datasources[0].telemetries[]' $using:appJSON
    if ([string]::IsNullOrEmpty($telemetries)) {
        Write-Run "Write-Error `"installer.ps1 (1): .configuration.subtypes[0].datasources[0].telemetries[] is empty in application JSON`""
        return 1
    }
    if ($telemetries.Equals("null")) {
        Write-Run "Write-Error `"installer.ps1 (1): .configuration.subtypes[0].datasources[0].telemetries[] was not found in application JSON`""
        return 1
    }

    $local:isLogsOptionSelected = $false
    $local:isMetricsOptionSelected = $false
    $local:index = 0

    foreach ($telemetry in $telemetries) {
        $local:type = Write-Output "$telemetry" | jq -r '.type'
        if ([string]::IsNullOrEmpty($type)) {
            Write-Run "Write-Error `"installer.ps1 (1): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' is empty in application JSON`""
            return 1
        }
        if ($type.Equals("null")) {
            Write-Run "Write-Error `"installer.ps1 (1): '.configuration.subtypes[0].datasources[0].telemetries[$index].type' was not found in application JSON`""
            return 1
        }

        $local:params = Write-Output "$telemetry" | jq -r '.params[]'
        if ([string]::IsNullOrEmpty($params)) {
            $params = ""
        }
        if ($params.Equals("null")) {
            Write-Run "Write-Error `"installer.ps1 (1): '.configuration.subtypes[0].datasources[0].telemetries[$index].params[]' was not found in application JSON`""
            return 1
        }

        if ($type.Equals("LOG_ANALYTICS")) {
            Write-Log "INFO" "isLogsOptionSelected = true"
            Write-Log "INFO" "logsParams = $params"

            $isLogsOptionSelected = $true
            Write-Run "`$script:logsParams = '$params'"
        } elseif ($type.Equals("METRICS")) {
            Write-Log "INFO" "isMetricsOptionSelected = true"
            Write-Log "INFO" "metricsParams = $params"

            $isMetricsOptionSelected = $true
            Write-Run "`$script:metricsParams = '$params'"
        }

        $index++
    }

    Write-Run "`$script:isLogsOptionSelected = `$$isLogsOptionSelected"
    Write-Run "`$script:isMetricsOptionSelected = `$$isMetricsOptionSelected"
}

# Creates Logz.io AppData directory
# Output:
#   logzioAppDataDir - The Logz.io AppData directory path
function New-LogzioAppDataDir {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Creating Logz.io AppData directory ..."

    $local:logzioAppDataDir = "$env:APPDATA\LogzioOTELCollector"
    if (-Not (Test-Path $logzioAppDataDir)) {
        New-Item -Path $logzioAppDataDir -ItemType Directory | Out-Null    
    }

    Write-Run "`$script:logzioAppDataDir = '$logzioAppDataDir'"
}

# Gets OTEL collector binary
# Output:
#   otelBin - The OTEL collector binary file path
# Error:
#   Exit Code 2
function Get-OTELCollectorBinary {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting OTEL collector binary ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri https://github.com/logzio/otel-collector-distro/releases/download/v0.56.1/otelcol-logzio-windows_amd64.tar.gz -OutFile $using:logzioTempDir\otelcol-logzio.tar.gz | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"installer.ps1 (2): failed to get OTEL collector binary file from open-telemetry repo.`n  $_`""
        return 2
    }

    $local:otelBin = "$using:logzioAppDataDir\otelcol-logzio-windows_amd64.exe"

    if (Test-Path -Path $otelBin -PathType Leaf) {
        Remove-Item -Path $otelBin
    }

    tar -zxf $using:logzioTempDir\otelcol-logzio.tar.gz --directory $using:logzioAppDataDir
    Write-Run "`$script:otelBin = '$otelBin'"
}

# Gets OTEL config from logzio-agent-manifest repo
# Output:
#   otelConfig - The OTEL config file path
# Error:
#   Exit Code 3
function Get-OTELConfig {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting OTEL config file from logzio-agent-manifest repo ..."

    $local:otelConfig = "$using:logzioAppDataDir\otel_config.yaml"
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/installer/otel_config.yaml -OutFile $otelConfig | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"installer.ps1 (3): failed to get OTEL config file from logzio-agent-manifest repo.`n  $_`""
        return 3
    }

    Write-Run "`$script:otelConfig = '$otelConfig'"
}

# Gets logs scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 4
function Get-LogsScripts {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting logs script file from logzio-agent-manifest repo ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/logs/windows/logs.ps1 -OutFile $using:logzioTempDir\logs.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"installer.ps1 (4): failed to get logs script file from logzio-agent-manifest repo.`n  $_`""
        return 4
    }

    Write-Log "INFO" "Getting logs functions script file from logzio-agent-manifest repo ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/logs/windows/functions.ps1 -OutFile $using:logzioTempDir\logs_functions.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"installer.ps1 (4): failed to get logs functions script file from logzio-agent-manifest repo.`n  $_`""
        return 4
    }
}

# Gets metrics scripts from logzio-agent-manifest repo
# Error:
#   Exit Code 5
function Get-MetricsScripts {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting metrics script file from logzio-agent-manifest repo ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/metrics/windows/metrics.ps1 -OutFile $using:logzioTempDir\metrics.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"installer.ps1 (5): failed to get metrics script file from logzio-agent-manifest repo.`n  $_`""
        return 5
    }

    Write-Log "INFO" "Getting metrics functions script file from logzio-agent-manifest repo ..."
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/metrics/windows/functions.ps1 -OutFile $using:logzioTempDir\metrics_functions.ps1 | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"installer.ps1 (5): failed to get metrics functions script file from logzio-agent-manifest repo.`n  $_`""
        return 5
    }
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
