#!/bin/bash

#################################################################################################################################
##################################################### Installer Mac Script ######################################################
#################################################################################################################################

# Load functions
write_log "INFO" "Loading installer functions ..."
source $logzio_temp_dir/installer_functions.bash

# Get which products were selected
execute_task "get_which_products_were_selected" "getting which products were selected"

# Get otelcol-contrib binary
execute_task "get_otelcol_contrib_binary" "getting otelcol-contrib binary"

# Get OTEL config
execute_task "get_otel_config" "getting OTEL config"

# Get logs scripts
if $is_logs_option_selected; then
    execute_task "get_logs_scripts" "getting logs scripts"
fi

# Get metrics scripts
if $is_metrics_option_selected; then
    execute_task "get_metrics_scripts" "getting metrics scripts"
fi

# Run logs script
if $is_logs_option_selected; then
    write_log "INFO" "Running logs script ..."
    echo -e "\nlogs:"
    source $logzio_temp_dir/logs.bash
fi

# Run metrics script
if $is_metrics_option_selected; then
    write_log "INFO" "Running metrics script ..."
    echo -e "\nmetrics:"
    source $logzio_temp_dir/metrics.bash
fi

# Run otelcol-contrib with OTEL config as a service
execute_task "run_otelcol_contrib_as_a_service" "running otelcol-contrib as a service"

# Print success message
echo
print_info "##### Logz.io agent was finished successfully #####"

# Print information
echo -e "\nInformation:"
echo -e "OTEL collector is running as a service."
echo -e "To \033[0;35msee\033[0;37m OTEL collector logs run \`\033[0;35mcat ./otelcol-contrib_stderr.log\033[0;37m\` or \`\033[0;35mcat ./otelcol-contrib_stdout.log\033[0;37m\`"
echo -e "To \033[0;35mstop\033[0;37m the OTEL collector run \`\033[0;35mlaunchctl stop com.logzio.OTELCollector\033[0;37m\`"
echo -e "To \033[0;35mrestart\033[0;37m the OTEL collector run \`\033[0;35mlaunchctl start com.logzio.OTELCollector\033[0;37m\`"
echo -e "To \033[0;35mremove\033[0;37m the OTEL collector service run \`\033[0;35mlaunchctl unload ./com.logzio.OTELCollector.plist\033[0;37m\`"
echo -e "To \033[0;35mload and start\033[0;37m the OTEL collector service run \`\033[0;35mlaunchctl load ./com.logzio.OTELCollector.plist\033[0;37m\`"
echo
