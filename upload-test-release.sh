#!/bin/bash
# filepath: automation_script.sh

# Exit on error
set -e

echo "Starting automation script..."

echo "Building artifacts with make..."
make

echo "Uploading all localhost artifacts to test release..."

LOCALHOST_ARTIFACTS=(
  "linux_localhost_linux.tar.gz"
  "mac_localhost_mac.tar.gz"
  "windows_localhost_windows.zip"
)

# Check if all files exist
for artifact in "${LOCALHOST_ARTIFACTS[@]}"; do
  if [ ! -f "assets/$artifact" ]; then
    echo "Error: $artifact not found in assets directory"
    exit 1
  fi
done

if command -v gh &> /dev/null; then
    echo "GitHub CLI found. Proceeding with upload..."
    
    echo "Attempting to delete existing assets from test release..."
    for artifact in "${LOCALHOST_ARTIFACTS[@]}"; do
      gh release delete-asset test "$artifact" --repo logzio/logzio-agent-manifest --yes 2>/dev/null || true
    done
    
    echo "Uploading new assets to test release..."
    for artifact in "${LOCALHOST_ARTIFACTS[@]}"; do
      echo "Uploading $artifact..."
      gh release upload test "assets/$artifact" --repo logzio/logzio-agent-manifest
    done
    
    echo "All uploads completed successfully."
else
    echo "GitHub CLI not found. Please install it or modify this script to use your preferred upload method."
    echo "You can install GitHub CLI with: brew install gh"
    exit 1
fi

