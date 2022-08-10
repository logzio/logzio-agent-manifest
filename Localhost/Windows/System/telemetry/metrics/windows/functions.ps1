#################################################################################################################################
################################################## Metrics Windows Functions ####################################################
#################################################################################################################################

# Gets Logz.io metrics listener URL
# Output:
#   metricsListenerURL - Logz.io metrics listener URL
# Error:
#   Exit Code 1
function Get-LogzioMetricsListenerUrl {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting Logz.io metrics listener URL ..."

    $local:listenerURL = jq -r '.listenerUrl' $using:appJSON
    if ([string]::IsNullOrEmpty($listenerURL)) {
        Write-Run "Write-Error `"metrics.ps1 (1): '.listenerUrl' is empty in application JSON`""
        return 1
    }
    if ($listenerURL.Equals("null")) {
        Write-Run "Write-Error `"metrics.ps1 (1): '.listenerUrl' was not found in application JSON`""
        return 1
    }

    $listenerURL = "https://$listenerURL`:8053"
    Write-Log "INFO" "metricsListenerURL = $listenerURL"
    Write-Run "`$script:metricsListenerURL = '$listenerURL'"
}

# Gets Logz.io metrics token
# Output:
#   metricsToken - Logz.io metrics token
# Error:
#   Exit Code 2
function Get-LogzioMetricsToken {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile

    Write-Log "INFO" "Getting Logz.io metrics token ..."

    $local:shippingToken = jq -r '.shippingTokens.METRICS' $using:appJSON
    if ([string]::IsNullOrEmpty($shippingToken)) {
        Write-Run "Write-Error `"metrics.ps1 (2): '.shippingTokens.METRICS' is empty in application JSON`""
        return 2
    }
    if ($shippingToken.Equals("null")) {
        Write-Run "Write-Error `"metrics.ps1 (2): '.shippingTokens.METRICS' was not found in application JSON`""
        return 2
    }
    
    Write-Log "INFO" "metricsToken = $shippingToken"
    Write-Run "`$script:metricsToken += '$shippingToken'"
}

# Adds metrics receivers to OTEL config
# Error:
#   Exit Code 3
function Add-MetricsReceiversToOTELConfig {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile
    $local:taskErrorFile = $using:taskErrorFile

    Write-Log "INFO" "Adding metrics receivers to OTEL config ..."

    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/metrics/metrics_otel_receivers.yaml -OutFile $using:logzioTempDir\metrics_otel_receivers.yaml | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"metrics.ps1 (3): failed to get metrics_otel_receivers yaml file from logzio-agent-manifest repo.`n  $_`""
        return 3
    }

    yq eval-all -i 'select(fileIndex==0).receivers += select(fileIndex==1) | select(fileIndex==0)' $using:otelConfig $using:logzioTempDir\metrics_otel_receivers.yaml 2>$using:taskErrorFile
    if (-Not $?) {
        $local:err = Get-TaskError
        Write-Run "Write-Error `"metrics.ps1 (3): failed to add metrics receivers to OTEL config file.`n  $err`""
        return 3
    }

    yq e -i '.service.pipelines.metrics.receivers += ""hostmetrics""' $using:otelConfig 2>$using:taskErrorFile
    if (-Not $?) {
        $local:err = Get-TaskError
        Write-Run "Write-Error `"metrics.ps1 (3): failed to add service pipeline metrics receiver to OTEL config file.`n  $err`""
        return 3
    }
}

# Adds metrics exporter to OTEL config
# Error:
#   Exit Code 4
function Add-MetricsExporterToOTELConfig {
    . $using:logzioTempDir\utils_functions.ps1
    $local:logFile = $using:logFile
    $local:runFile = $using:runFile
    $local:taskErrorFile = $using:taskErrorFile

    Write-Log "INFO" "Adding metrics exporter to OTEL config ..."

    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $using:repoPath/telemetry/metrics/metrics_otel_exporter.yaml -OutFile $using:logzioTempDir\metrics_otel_exporter.yaml | Out-Null
        $ProgressPreference = "Continue"
    }
    catch {
        Write-Run "Write-Error `"metrics.ps1 (4): failed to get metrics_otel_exporter yaml file from logzio-agent-manifest repo.`n  $_`""
        return 4
    }

    yq e -i ".prometheusremotewrite.endpoint = ""`"$using:metricsListenerURL`"""" $using:logzioTempDir\metrics_otel_exporter.yaml 2>$using:taskErrorFile
    if (-Not $?) {
        $local:err = Get-TaskError
        Write-Run "Write-Error `"metrics.ps1 (4): failed to insert Logz.io metrics listener URL into metrics_otel_exporter yaml file.`n  $err`""
        return 4
    }

    $local:auth = "`"Bearer $using:metricsToken`""
    yq e -i ".prometheusremotewrite.headers.Authorization = ""`"$auth`"""" $using:logzioTempDir\metrics_otel_exporter.yaml 2>$using:taskErrorFile
    if (-Not $?) {
        $local:err = Get-TaskError
        Write-Run "Write-Error `"metrics.ps1 (4): failed to insert Logz.io metrics token into metrics_otel_exporter yaml file.`n  $err`""
        return 4
    }

    yq eval-all -i 'select(fileIndex==0).exporters += select(fileIndex==1) | select(fileIndex==0)' $using:otelConfig $using:logzioTempDir\metrics_otel_exporter.yaml 2>$using:taskErrorFile
    if (-Not $?) {
        $local:err = Get-TaskError
        Write-Run "Write-Error `"metrics.ps1 (4): failed to add metrics exporter to OTEL config file.`n  $err`""
        return 4
    }

    yq e -i '.service.pipelines.metrics.exporters += """prometheusremotewrite"""' $using:otelConfig 2>$using:taskErrorFile
    if (-Not $?) {
        $local:err = Get-TaskError
        Write-Run "Write-Error `"metrics.ps1 (4): failed to add service pipeline metrics exporter to OTEL config file.`n  $err`""
        return 4
    }
}

