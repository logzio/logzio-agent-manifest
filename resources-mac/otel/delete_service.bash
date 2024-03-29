#!/bin/bash

#################################################################################################################################
##################################################### MAC Delete Service ########################################################
#################################################################################################################################

launchctl remove "LOGZIO_OTEL_COLLECTOR_SERVICE_NAME"
if [[ $? -ne 0 ]]; then
    exit 1
fi

rm "LOGZIO_OTEL_COLLECTOR_SERVICE_PLIST_FILE"
if [[ $? -ne 0 ]]; then
    exit 2
fi

echo -e "service was deleted successfully"