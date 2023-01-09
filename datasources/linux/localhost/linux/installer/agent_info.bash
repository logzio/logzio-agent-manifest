#!/bin/bash

#################################################################################################################################
################################################### LINUX Agent Info Script #####################################################
#################################################################################################################################

echo
echo -e '###################'
echo -e "###$PURPLE_COLOR Information $WHITE_COLOR###"
echo -e '###################'
echo -e "${PURPLE_COLOR}Collector Binary$WHITE_COLOR: $OTEL_COLLECTOR_BIN"
echo -e "${PURPLE_COLOR}Collector Config$WHITE_COLOR: $OTEL_CONFIG"
echo -e "${PURPLE_COLOR}Logz.io Agent Logs$WHITE_COLOR: $AGENT_LOG_FILE"
echo -e "${PURPLE_COLOR}Start Service$WHITE_COLOR: sudo systemctl start $LOGZIO_OTEL_COLLECTOR_SERVICE_NAME"
echo -e "${PURPLE_COLOR}Stop Service$WHITE_COLOR: sudo systemctl stop $LOGZIO_OTEL_COLLECTOR_SERVICE_NAME" 
echo -e "${PURPLE_COLOR}Delete Service$WHITE_COLOR: sudo $OTEL_RESOURCES_LINUX_DIR/delete_service.bash"
echo -e "${PURPLE_COLOR}Show Service$WHITE_COLOR: sudo systemctl | grep $LOGZIO_OTEL_COLLECTOR_SERVICE_NAME"
echo -e "${PURPLE_COLOR}Show Service Logs$WHITE_COLOR: sudo systemctl status -l $LOGZIO_OTEL_COLLECTOR_SERVICE_NAME"
