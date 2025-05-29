############################################################
# This Makefile generates binary files for testing purposes.
############################################################

# Initialize paths
CURR_PATH := $(CURDIR)
ASSETS_PATH := $(CURR_PATH)/assets
TMP_PATH := $(CURR_PATH)/tmp

# Detect OS for Windows-specific commands
ifeq ($(OS),Windows_NT)
	USE_POWERSHELL := 1
else
	USE_POWERSHELL := 0
endif

# Starting point
.PHONY: all
all: create_assets windows linux mac

# Create the assets directory
.PHONY: create_assets
create_assets:
	mkdir -p $(ASSETS_PATH)

# Build Windows binaries
.PHONY: windows
windows: create_assets
	mkdir -p $(TMP_PATH)
ifeq ($(USE_POWERSHELL),1)
	# Use PowerShell for Windows builds
	powershell -Command "Copy-Item -Path '$(CURR_PATH)/scripts/windows/*' -Destination '$(TMP_PATH)' -Recurse -Force"
	powershell -Command "Copy-Item -Path '$(CURR_PATH)/version' -Destination '$(TMP_PATH)' -Force"
	powershell -Command "Compress-Archive -Path '$(TMP_PATH)/*' -DestinationPath '$(ASSETS_PATH)/agent_windows.zip' -Force"
	powershell -Command "Remove-Item -Path '$(TMP_PATH)/*' -Recurse -Force"
	powershell -Command "Copy-Item -Path '$(CURR_PATH)/datasources/windows/*' -Destination '$(TMP_PATH)' -Recurse -Force"
	powershell -Command "Copy-Item -Path '$(CURR_PATH)/resources' -Destination '$(TMP_PATH)' -Recurse -Force"
	powershell -Command "Compress-Archive -Path '$(TMP_PATH)/kubernetes/aks', '$(TMP_PATH)/resources' -DestinationPath '$(ASSETS_PATH)/windows_kubernetes_aks.zip' -Force"
	powershell -Command "Compress-Archive -Path '$(TMP_PATH)/kubernetes/eks', '$(TMP_PATH)/resources' -DestinationPath '$(ASSETS_PATH)/windows_kubernetes_eks.zip' -Force"
	powershell -Command "Compress-Archive -Path '$(TMP_PATH)/kubernetes/gke', '$(TMP_PATH)/resources' -DestinationPath '$(ASSETS_PATH)/windows_kubernetes_gke.zip' -Force"
	powershell -Command "Compress-Archive -Path '$(TMP_PATH)/kubernetes/digitalocean', '$(TMP_PATH)/resources' -DestinationPath '$(ASSETS_PATH)/windows_kubernetes_digitalocean.zip' -Force"
	powershell -Command "Compress-Archive -Path '$(TMP_PATH)/localhost/windows', '$(TMP_PATH)/resources' -DestinationPath '$(ASSETS_PATH)/windows_localhost_windows.zip' -Force"
	powershell -Command "Remove-Item -Path '$(TMP_PATH)' -Recurse -Force"
else
	# Use zip for non-Windows builds
	cd $(TMP_PATH) && \
	cp -r $(CURR_PATH)/scripts/windows/. $(CURR_PATH)/version . && \
	zip -r $(ASSETS_PATH)/agent_windows.zip . && \
	rm -rf $(TMP_PATH)/*
	cd $(TMP_PATH) && \
	cp -r $(CURR_PATH)/datasources/windows/. $(CURR_PATH)/resources . && \
	zip -r $(ASSETS_PATH)/windows_kubernetes_aks.zip kubernetes/aks resources && \
	zip -r $(ASSETS_PATH)/windows_kubernetes_eks.zip kubernetes/eks resources && \
	zip -r $(ASSETS_PATH)/windows_kubernetes_gke.zip kubernetes/gke resources && \
	zip -r $(ASSETS_PATH)/windows_kubernetes_digitalocean.zip kubernetes/digitalocean resources && \
	zip -r $(ASSETS_PATH)/windows_localhost_windows.zip localhost/windows resources
	rm -rf $(TMP_PATH)
endif

# Build Linux binaries
.PHONY: linux
linux: create_assets
	tar -czvf $(ASSETS_PATH)/agent_linux.tar.gz -C scripts/linux . -C $(CURR_PATH) version
	tar -czvf $(ASSETS_PATH)/linux_kubernetes_aks.tar.gz -C datasources/linux kubernetes/aks -C $(CURR_PATH) resources -C $(CURR_PATH) resources-linux
	tar -czvf $(ASSETS_PATH)/linux_kubernetes_eks.tar.gz -C datasources/linux kubernetes/eks -C $(CURR_PATH) resources -C $(CURR_PATH) resources-linux
	tar -czvf $(ASSETS_PATH)/linux_kubernetes_gke.tar.gz -C datasources/linux kubernetes/gke -C $(CURR_PATH) resources -C $(CURR_PATH) resources-linux
	tar -czvf $(ASSETS_PATH)/linux_kubernetes_digitalocean.tar.gz -C datasources/linux kubernetes/digitalocean -C $(CURR_PATH) resources -C $(CURR_PATH) resources-linux
	tar -czvf $(ASSETS_PATH)/linux_aws_ec2.tar.gz -C datasources/linux aws/ec2 -C $(CURR_PATH) resources -C $(CURR_PATH) resources-linux
	tar -czvf $(ASSETS_PATH)/linux_localhost_linux.tar.gz -C datasources/linux localhost/linux -C $(CURR_PATH) resources -C $(CURR_PATH) resources-linux

# Build Mac binaries
.PHONY: mac
mac: create_assets
	tar -czvf $(ASSETS_PATH)/agent_mac.tar.gz -C scripts/mac . -C $(CURR_PATH) version
	tar -czvf $(ASSETS_PATH)/mac_kubernetes_aks.tar.gz -C datasources/mac kubernetes/aks -C $(CURR_PATH) resources -C $(CURR_PATH) resources-mac
	tar -czvf $(ASSETS_PATH)/mac_kubernetes_eks.tar.gz -C datasources/mac kubernetes/eks -C $(CURR_PATH) resources -C $(CURR_PATH) resources-mac
	tar -czvf $(ASSETS_PATH)/mac_kubernetes_gke.tar.gz -C datasources/mac kubernetes/gke -C $(CURR_PATH) resources -C $(CURR_PATH) resources-mac
	tar -czvf $(ASSETS_PATH)/mac_kubernetes_digitalocean.tar.gz -C datasources/mac kubernetes/digitalocean -C $(CURR_PATH) resources -C $(CURR_PATH) resources-mac
	tar -czvf $(ASSETS_PATH)/mac_localhost_mac.tar.gz -C datasources/mac localhost/mac -C $(CURR_PATH) resources -C $(CURR_PATH) resources-mac
