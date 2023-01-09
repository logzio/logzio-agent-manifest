#!/bin/bash

#################################################################################################################################
#################################################### LINUX DELETE SERVICE #######################################################
#################################################################################################################################

systemctl stop "LOGZIO_OTEL_COLLECTOR_SERVICE_NAME"
if [[ $? -ne 0 ]]; then
    exit 1
fi

systemctl disable "LOGZIO_OTEL_COLLECTOR_SERVICE_NAME"
if [[ $? -ne 0 ]]; then
    exit 2
fi

systemctl reset-failed "LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 2>/dev/null

rm "/etc/systemd/system/LOGZIO_OTEL_COLLECTOR_SERVICE_NAME.service" 2>/dev/null
rm "/usr/lib/systemd/system/LOGZIO_OTEL_COLLECTOR_SERVICE_NAME.service" 2>/dev/null
rm "/etc/init.d/LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 2>/dev/null
