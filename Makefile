############################################################
# This Makefile generates binary files for testing purposes.
############################################################

# Initialize paths
CURR_PATH := $(CURDIR)
ASSETS_PATH := $(CURR_PATH)/assets
TMP_PATH := $(CURR_PATH)/tmp

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
