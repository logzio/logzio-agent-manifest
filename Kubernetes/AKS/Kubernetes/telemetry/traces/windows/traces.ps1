#################################################################################################################################
#################################################### Traces Windows Script ######################################################
#################################################################################################################################

# Load functions
Write-Log "INFO" "Loading traces functions ..."
. $logzioTempDir\traces_functions.ps1

# Build enable traces Helm set
Invoke-Task "Build-EnableTracesHelmSet" "building enable traces Helm set"

# Build Logz.io traces token Helm set
Invoke-Task "Build-LogzioTracesTokenHelmSet" "building Logz.io traces token Helm set"

# Build Logz.io region Helm set
Invoke-Task "Build-LogzioRegionHelmSet" "building Logz.io region Helm set"

# Finished successfully
Exit 0
