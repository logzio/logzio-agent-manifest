#!/bin/bash

#################################################################################################################################
#################################################### MAC Agent Info Script ######################################################
#################################################################################################################################

echo
echo -e '###################'
echo -e "###$PURPLE_COLOR Information $WHITE_COLOR###"
echo -e '###################'
echo -e "${PURPLE_COLOR}Logz.io Helm$WHITE_COLOR: $LOGZIO_HELM_FILE"
echo -e "${PURPLE_COLOR}Logz.io Agent Logs$WHITE_COLOR: $AGENT_LOG_FILE"
echo -e "${PURPLE_COLOR}Install Logz.io Helm$WHITE_COLOR: . $LOGZIO_HELM_FILE"
echo -e "${PURPLE_COLOR}Uninstall Logz.io Helm$WHITE_COLOR: helm uninstall -n monitoring logzio-monitoring"
echo -e "${PURPLE_COLOR}Show Helm Status$WHITE_COLOR: helm status -n monitoring logzio-monitoring"
echo -e "${PURPLE_COLOR}Get Pods$WHITE_COLOR: kubectl get pods -n monitoring"
echo -e "${PURPLE_COLOR}Show Pod's Logs$WHITE_COLOR: kubectl logs <<POD_NAME>> -n monitoring"
echo -e "${PURPLE_COLOR}Show Pod's Info$WHITE_COLOR: kubectl describe pod <<POD_NAME>> -n monitoring"
