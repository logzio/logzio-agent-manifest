#!/bin/bash
# filepath: tests/upload-test-release.sh

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
    
    # Check if test release exists, create it if it doesn't
    if ! gh release view test --repo logzio/logzio-agent-manifest &>/dev/null; then
      echo "Test release does not exist. Creating..."
      gh release create test --repo logzio/logzio-agent-manifest --title "Test Release" --notes "Automated test release for CI purposes." --prerelease
      
      if [ $? -ne 0 ]; then
        echo "Failed to create test release. Check GitHub permissions."
        exit 1
      fi
    fi
    
    echo "Attempting to delete existing assets from test release..."
    for artifact in "${LOCALHOST_ARTIFACTS[@]}"; do
      gh release delete-asset test "$artifact" --repo logzio/logzio-agent-manifest --yes 2>/dev/null || true
    done
    
    echo "Uploading new assets to test release..."
    for artifact in "${LOCALHOST_ARTIFACTS[@]}"; do
      echo "Uploading $artifact..."
      gh release upload test "assets/$artifact" --repo logzio/logzio-agent-manifest
      
      if [ $? -ne 0 ]; then
        echo "Failed to upload $artifact. Check GitHub permissions."
        exit 1
      fi
    done
    
    echo "All uploads completed successfully."
else
    echo "GitHub CLI not found. Please install it or modify this script to use your preferred upload method."
    echo "You can install GitHub CLI with: brew install gh"
    exit 1
fi

