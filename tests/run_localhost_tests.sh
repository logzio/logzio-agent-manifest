#!/bin/bash

# Script for automated testing of Logz.io agent manifest for localhost subtypes
# This script will:
# 1. Build binary files (if not skipped)
# 2. Run the agent with test configuration
# 3. Validate that the agent runs successfully
# 4. Validate the collector configuration files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TEMP_DIR="$ROOT_DIR/tmp/test"
ASSETS_DIR="$ROOT_DIR/assets"
TEST_CONFIGS_DIR="$ROOT_DIR/testing-configs"
LOG_DIR="$TEMP_DIR/logs"
VALIDATION_DIR="$TEMP_DIR/validation"
AGENT_OUTPUT_FILE="$LOG_DIR/agent_output.log"
AGENT_ERROR_FILE="$LOG_DIR/agent_error.log"

# Default test parameters
INSTALL_DIR="/opt/logzio-agent-test"
TEST_CONFIG=""

# Default URL and ID for testing - these won't be used since we're using --debug mode
TEST_URL="https://app.logz.io"
TEST_ID="test-agent-id"

# Add a flag to control debug output
DEBUG_MODE=false

# Max time to wait for agent execution (in seconds)
MAX_WAIT_TIME=300

# Detect current OS
CURRENT_OS=""
if [[ "$(uname)" == "Linux" ]]; then
    CURRENT_OS="linux"
elif [[ "$(uname)" == "Darwin" ]]; then
    CURRENT_OS="mac"
else
    echo "Error: Unsupported OS: $(uname). This script only works on Linux or macOS."
    exit 1
fi

echo "Detected OS: $CURRENT_OS"

# Parse command-line arguments
SKIP_BUILD=false
for arg in "$@"; do
    case "$arg" in
        --skip-build)
            SKIP_BUILD=true
            ;;
        --config=*)
            TEST_CONFIG="${arg#*=}"
            ;;
        --install-dir=*)
            INSTALL_DIR="${arg#*=}"
            ;;
        --debug)
            DEBUG_MODE=true
            ;;
        *)
            # Unknown option
            ;;
    esac
done

# If no config specified, use the default one for current OS
if [[ -z "$TEST_CONFIG" ]]; then
    TEST_CONFIG="$TEST_CONFIGS_DIR/localhost-${CURRENT_OS}-system.json"
fi

# Ensure we're running from the repo root
if [[ ! -f "$ROOT_DIR/Makefile" ]]; then
    echo "Error: Must run this script from the repository root or tests directory"
    exit 1
fi

# Create temp directories for testing
mkdir -p "$TEMP_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$VALIDATION_DIR"
mkdir -p "$INSTALL_DIR"

echo "=== Logz.io Agent Manifest - Localhost Tests ==="
echo "=== $(date) ==="
echo "Test configuration: $TEST_CONFIG"
echo "Installation directory: $INSTALL_DIR"
if [[ "$DEBUG_MODE" == "true" ]]; then
    echo "Debug mode: Enabled (verbose output)"
fi
echo ""

# Function to build the binaries using the Makefile
build_binaries() {
    echo "Building binary files using Makefile..."
    cd "$ROOT_DIR"
    make
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to build binary files"
        exit 1
    fi
    echo "Binary files built successfully."
    echo ""
}

# Function to prepare the test environment
prepare_test_env() {
    echo "Preparing test environment..."
    
    # Clear previous test artifacts if they exist
    rm -rf "$TEMP_DIR/$CURRENT_OS" "$INSTALL_DIR"/*
    mkdir -p "$TEMP_DIR/$CURRENT_OS"
    
    # Extract the agent for current OS
    echo "Extracting agent for $CURRENT_OS..."
    tar -xzf "$ASSETS_DIR/agent_${CURRENT_OS}.tar.gz" -C "$TEMP_DIR/$CURRENT_OS"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to extract agent for $CURRENT_OS"
        exit 1
    fi
    
    echo "Agent extracted successfully to $TEMP_DIR/$CURRENT_OS"
    
    # Make agent script executable
    local agent_script="$TEMP_DIR/$CURRENT_OS/agent.bash"
    chmod +x "$agent_script"
    
    # Check the contents of the agent directory
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo "Agent directory contents:"
        ls -la "$TEMP_DIR/$CURRENT_OS"
    fi
    
    # Verify test config exists
    if [[ ! -f "$TEST_CONFIG" ]]; then
        echo "Error: Test configuration file not found: $TEST_CONFIG"
        exit 1
    fi
    
    # Check the test config is valid JSON
    if ! jq empty "$TEST_CONFIG" 2>/dev/null; then
        echo "Error: Invalid JSON in test configuration file: $TEST_CONFIG"
        exit 1
    fi
    
    # Verify install directory is writable
    if [[ ! -w "$INSTALL_DIR" ]]; then
        echo "Error: Installation directory is not writable: $INSTALL_DIR"
        echo "Try running the script with sudo or choose a different installation directory"
        exit 1
    fi
    
    echo "Test environment prepared successfully."
}

# Function to run the agent and capture output
run_agent() {
    echo "Running Logz.io agent with test configuration..."
    
    local agent_script="$TEMP_DIR/$CURRENT_OS/agent.bash"
    local cmd="$agent_script --debug=$TEST_CONFIG --install-dir=$INSTALL_DIR"
    
    echo "Command: $cmd"
    echo ""
    
    # Run the agent directly to capture output in real-time for debugging
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo "Running agent in debug mode (real-time output)..."
        $cmd
        local exit_code=$?
        
        if [[ $exit_code -ne 0 ]]; then
            echo "Error: Agent execution failed with exit code $exit_code"
            return 1
        fi
        
        echo "Agent execution completed successfully."
        echo ""
        return 0
    fi
    
    # Run the agent and capture output
    $cmd > "$AGENT_OUTPUT_FILE" 2> "$AGENT_ERROR_FILE" &
    local agent_pid=$!
    
    # Display a dot every second while the agent is running
    echo -n "Agent is running"
    local counter=0
    while kill -0 $agent_pid 2>/dev/null; do
        echo -n "."
        sleep 1
        ((counter++))
        
        if [[ $counter -ge $MAX_WAIT_TIME ]]; then
            echo ""
            echo "Error: Agent execution timed out after $MAX_WAIT_TIME seconds"
            kill -9 $agent_pid 2>/dev/null || true
            return 1
        fi
    done
    
    echo ""
    
    # Check if agent finished successfully
    wait $agent_pid
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo "Error: Agent execution failed with exit code $exit_code"
        echo "Agent output (last 20 lines):"
        tail -n 20 "$AGENT_OUTPUT_FILE"
        echo ""
        echo "Agent error output:"
        cat "$AGENT_ERROR_FILE"
        return 1
    fi
    
    echo "Agent execution completed successfully in $counter seconds."
    echo ""
    
    return 0
}

# Function to validate generated OTEL configuration files
validate_otel_config() {
    echo "Validating OTEL configuration..."
    
    # Define expected configuration files
    local config_files=(
        "$INSTALL_DIR/otel_config.yaml"
    )
    
    # Optional files that may be generated based on configuration
    local logs_pipeline="$INSTALL_DIR/logs_pipeline.yaml"
    local metrics_pipeline="$INSTALL_DIR/metrics_pipeline.yaml"
    
    # Check if required files exist
    local missing_files=0
    for file in "${config_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            echo "Error: Required configuration file not found: $file"
            missing_files=$((missing_files + 1))
        else
            echo "Found configuration file: $file"
        fi
    done
    
    if [[ $missing_files -gt 0 ]]; then
        echo "Error: $missing_files required configuration files are missing"
        # Check for permissions issues
        echo "Installation directory permissions:"
        ls -la "$INSTALL_DIR"
        return 1
    fi
    
    # Extract telemetry types from the config file
    local telemetries=$(jq '.subtypes[0].datasources[0].telemetries' "$TEST_CONFIG")
    local has_logs=$(echo "$telemetries" | jq 'map(select(.type == "LOG_ANALYTICS")) | length > 0')
    local has_metrics=$(echo "$telemetries" | jq 'map(select(.type == "METRICS")) | length > 0')
    
    # Check for logs pipeline if logs are enabled
    if [[ "$has_logs" == "true" ]]; then
        if [[ ! -f "$logs_pipeline" ]]; then
            echo "Error: Logs pipeline configuration not found: $logs_pipeline"
            missing_files=$((missing_files + 1))
        else
            echo "Found logs pipeline configuration: $logs_pipeline"
            
            # Validate logs pipeline structure
            if ! yq e '.receivers' "$logs_pipeline" > /dev/null 2>&1; then
                echo "Error: Invalid logs pipeline configuration (missing receivers)"
                missing_files=$((missing_files + 1))
            fi
            
            if ! yq e '.exporters' "$logs_pipeline" > /dev/null 2>&1; then
                echo "Error: Invalid logs pipeline configuration (missing exporters)"
                missing_files=$((missing_files + 1))
            fi
        fi
    fi
    
    # Check for metrics pipeline if metrics are enabled
    if [[ "$has_metrics" == "true" ]]; then
        if [[ ! -f "$metrics_pipeline" ]]; then
            echo "Error: Metrics pipeline configuration not found: $metrics_pipeline"
            missing_files=$((missing_files + 1))
        else
            echo "Found metrics pipeline configuration: $metrics_pipeline"
            
            # Validate metrics pipeline structure
            if ! yq e '.receivers' "$metrics_pipeline" > /dev/null 2>&1; then
                echo "Error: Invalid metrics pipeline configuration (missing receivers)"
                missing_files=$((missing_files + 1))
            fi
            
            if ! yq e '.exporters' "$metrics_pipeline" > /dev/null 2>&1; then
                echo "Error: Invalid metrics pipeline configuration (missing exporters)"
                missing_files=$((missing_files + 1))
            fi
        fi
    fi
    
    # Check for service definition file based on OS
    local service_file=""
    if [[ "$CURRENT_OS" == "linux" ]]; then
        service_file="$INSTALL_DIR/logzio-otel-collector.service"
        
        if [[ ! -f "$service_file" ]]; then
            echo "Error: Systemd service file not found: $service_file"
            missing_files=$((missing_files + 1))
        else
            echo "Found systemd service file: $service_file"
            
            # Validate service file structure
            if ! grep -q "ExecStart" "$service_file"; then
                echo "Error: Invalid systemd service file (missing ExecStart)"
                missing_files=$((missing_files + 1))
            fi
        fi
    elif [[ "$CURRENT_OS" == "mac" ]]; then
        service_file="$INSTALL_DIR/io.logz.collector.plist"
        
        if [[ ! -f "$service_file" ]]; then
            echo "Error: LaunchD plist file not found: $service_file"
            missing_files=$((missing_files + 1))
        else
            echo "Found LaunchD plist file: $service_file"
            
            # Validate plist file structure
            if ! grep -q "<key>ProgramArguments</key>" "$service_file"; then
                echo "Error: Invalid LaunchD plist file (missing ProgramArguments)"
                missing_files=$((missing_files + 1))
            fi
        fi
    fi
    
    if [[ $missing_files -gt 0 ]]; then
        echo "Error: $missing_files configuration files or sections are invalid"
        return 1
    fi
    
    echo "OTEL configuration validation passed."
    return 0
}

# Function to generate a validation report
generate_validation_report() {
    local success=$1
    local validation_file="$VALIDATION_DIR/localhost-${CURRENT_OS}-validation.txt"
    
    echo "Generating validation report..."
    
    # Ensure validation directory exists
    mkdir -p "$VALIDATION_DIR"
    
    # Extract important parts from the test config
    local telemetries=$(jq '.subtypes[0].datasources[0].telemetries' "$TEST_CONFIG")
    local has_logs=$(echo "$telemetries" | jq 'map(select(.type == "LOG_ANALYTICS")) | length > 0')
    local has_metrics=$(echo "$telemetries" | jq 'map(select(.type == "METRICS")) | length > 0')
    
    # Generate the report
    {
        echo "=== Validation Report for localhost-$CURRENT_OS-system ==="
        echo "Date: $(date)"
        echo ""
        echo "Test Config File: $TEST_CONFIG"
        echo "Installation Directory: $INSTALL_DIR"
        echo "Has LOG_ANALYTICS: $has_logs"
        echo "Has METRICS: $has_metrics"
        echo ""
        
        echo "Validation Status: $([ "$success" == "true" ] && echo "PASSED" || echo "FAILED")"
        echo ""
        
        echo "Generated Files:"
        if [[ -f "$INSTALL_DIR/otel_config.yaml" ]]; then
            echo "- OTEL Configuration: Found"
        else
            echo "- OTEL Configuration: Not Found (ERROR)"
        fi
        
        if [[ "$CURRENT_OS" == "linux" ]]; then
            if [[ -f "$INSTALL_DIR/logzio-otel-collector.service" ]]; then
                echo "- Systemd Service File: Found"
            else
                echo "- Systemd Service File: Not Found (ERROR)"
            fi
        elif [[ "$CURRENT_OS" == "mac" ]]; then
            if [[ -f "$INSTALL_DIR/io.logz.collector.plist" ]]; then
                echo "- LaunchD plist File: Found"
            else
                echo "- LaunchD plist File: Not Found (ERROR)"
            fi
        fi
        
        if [[ "$has_logs" == "true" ]]; then
            if [[ -f "$INSTALL_DIR/logs_pipeline.yaml" ]]; then
                echo "- Logs Pipeline Configuration: Found"
            else
                echo "- Logs Pipeline Configuration: Not Found (ERROR)"
            fi
        fi
        
        if [[ "$has_metrics" == "true" ]]; then
            if [[ -f "$INSTALL_DIR/metrics_pipeline.yaml" ]]; then
                echo "- Metrics Pipeline Configuration: Found"
            else
                echo "- Metrics Pipeline Configuration: Not Found (ERROR)"
            fi
        fi
        
        echo ""
        echo "Agent Output Summary:"
        if [[ -f "$AGENT_OUTPUT_FILE" ]]; then
            tail -n 50 "$AGENT_OUTPUT_FILE" | grep -v "^\s*$" || echo "No output captured"
        else
            echo "No output file found"
        fi
        
        echo ""
        echo "Agent Error Summary:"
        if [[ -f "$AGENT_ERROR_FILE" ]]; then
            cat "$AGENT_ERROR_FILE" || echo "No errors captured"
        else
            echo "No error file found"
        fi
        
        echo ""
        echo "System Information:"
        echo "- OS: $(uname -a)"
        echo "- User: $(whoami)"
        echo "- Working Directory: $(pwd)"
        
    } > "$validation_file"
    
    echo "Validation report generated: $validation_file"
    
    # Display report summary
    echo ""
    echo "=== Validation Report Summary ==="
    echo "Status: $([ "$success" == "true" ] && echo "PASSED" || echo "FAILED")"
    echo "Report location: $validation_file"
    echo ""
}

# Main test execution
main() {
    # Build binaries only if not skipped
    if [[ "$SKIP_BUILD" != "true" ]]; then
        build_binaries
    else
        echo "Skipping binary build as requested by --skip-build flag"
    fi
    
    # Prepare test environment
    prepare_test_env
    
    # Run agent with test configuration
    run_agent
    local agent_success=$?
    
    if [[ $agent_success -eq 0 ]]; then
        # Validate OTEL configuration
        validate_otel_config
        local config_success=$?
        
        # Generate validation report
        local overall_success=false
        if [[ $config_success -eq 0 ]]; then
            overall_success=true
        fi
        generate_validation_report "$overall_success"
    else
        # Agent failed, generate failure report
        generate_validation_report "false"
    fi
    
    echo "=== Tests completed ==="
    if [[ "$agent_success" -eq 0 ]]; then
        echo "Agent execution passed successfully."
        if [[ $config_success -eq 0 ]]; then
            echo "All validation checks passed."
            exit 0
        else
            echo "Some validation checks failed. Check the validation report for details."
            exit 1
        fi
    else
        echo "Agent execution failed. Check the validation report for details."
        exit 1
    fi
}

# Run the main function
main "$@"