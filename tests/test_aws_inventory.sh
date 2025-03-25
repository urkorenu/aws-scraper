#!/usr/bin/env bash

# Test suite for AWS Infrastructure Inventory Tool
# Copyright (c) 2024
# Licensed under MIT License

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
SRC_DIR="$PROJECT_ROOT/src"

# Source the main script
source "$SRC_DIR/aws-inventory.sh"

# Helper functions
log_test() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [ "$status" == "PASS" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}[PASS]${NC} $test_name: $message"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}[FAIL]${NC} $test_name: $message"
    fi
}

test_dependencies() {
    local test_name="Dependencies Check"
    
    for cmd in aws jq yq; do
        if ! command -v "$cmd" &> /dev/null; then
            log_test "$test_name" "FAIL" "Missing dependency: $cmd"
            return 1
        fi
    done
    
    log_test "$test_name" "PASS" "All dependencies found"
}

test_config_loading() {
    local test_name="Config Loading"
    local temp_config="$TEST_DIR/temp_config.yaml"
    
    # Create test config
    cat > "$temp_config" << EOF
output:
  format: html
  directory: ~/.aws-inventory/reports

resources:
  ec2: true
  s3: true
  rds: true
  lambda: true
  vpc: true

filters:
  tags: {}
  vpc:
    exclude_default: true
    exclude_main_route_tables: true
    exclude_default_subnets: true
EOF
    
    # Test config loading
    CONFIG_FILE="$temp_config"
    load_config
    
    # Verify config values
    if [ "$EC2_ENABLED" != "true" ] || \
       [ "$S3_ENABLED" != "true" ] || \
       [ "$RDS_ENABLED" != "true" ] || \
       [ "$LAMBDA_ENABLED" != "true" ] || \
       [ "$VPC_ENABLED" != "true" ]; then
        log_test "$test_name" "FAIL" "Config values not loaded correctly"
        rm -f "$temp_config"
        return 1
    fi
    
    log_test "$test_name" "PASS" "Config loaded successfully"
    rm -f "$temp_config"
}

test_output_initialization() {
    local test_name="Output Initialization"
    local temp_dir="$TEST_DIR/temp_output"
    
    # Test output initialization
    OUTPUT_DIR="$temp_dir"
    OUTPUT_FORMAT="html"
    initialize_output
    
    # Verify output directory and file creation
    if [ ! -d "$temp_dir" ] || [ ! -f "$OUTPUT_FILE" ]; then
        log_test "$test_name" "FAIL" "Output directory or file not created"
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_test "$test_name" "PASS" "Output initialized successfully"
    rm -rf "$temp_dir"
}

test_resource_collection() {
    local test_name="Resource Collection"
    local temp_dir="$TEST_DIR/temp_resources"
    
    # Create temp directory for resource data
    mkdir -p "$temp_dir"
    TEMP_DIR="$temp_dir"
    
    # Test resource collection
    collect_resources
    
    # Verify resource files
    for resource in ec2 s3 rds lambda vpc; do
        if [ ! -f "$temp_dir/$resource.json" ]; then
            log_test "$test_name" "FAIL" "Resource file not created: $resource.json"
            rm -rf "$temp_dir"
            return 1
        fi
    done
    
    log_test "$test_name" "PASS" "Resources collected successfully"
    rm -rf "$temp_dir"
}

test_html_report_generation() {
    local test_name="HTML Report Generation"
    local temp_dir="$TEST_DIR/temp_html"
    local output_file="$temp_dir/report.html"
    
    # Create temp directory and test data
    mkdir -p "$temp_dir"
    echo '[]' > "$temp_dir/ec2.json"
    echo '[]' > "$temp_dir/s3.json"
    echo '[]' > "$temp_dir/rds.json"
    
    # Test HTML report generation
    source "$SRC_DIR/html_report.sh"
    generate_html_report "$temp_dir" "$output_file"
    
    # Verify HTML file
    if [ ! -f "$output_file" ]; then
        log_test "$test_name" "FAIL" "HTML report not generated"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Verify HTML content
    if ! grep -q "<!DOCTYPE html>" "$output_file"; then
        log_test "$test_name" "FAIL" "Invalid HTML content"
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_test "$test_name" "PASS" "HTML report generated successfully"
    rm -rf "$temp_dir"
}

test_error_handling() {
    local test_name="Error Handling"
    
    # Test invalid config file
    CONFIG_FILE="/nonexistent/config.yaml"
    if load_config; then
        log_test "$test_name" "FAIL" "Failed to handle missing config file"
        return 1
    fi
    
    # Test invalid AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        log_test "$test_name" "PASS" "AWS credentials valid"
    else
        log_test "$test_name" "FAIL" "AWS credentials invalid"
        return 1
    fi
    
    log_test "$test_name" "PASS" "Error handling working correctly"
}

# Run all tests
run_tests() {
    echo "Running AWS Infrastructure Inventory Tool tests..."
    echo "================================================"
    
    test_dependencies
    test_config_loading
    test_output_initialization
    test_resource_collection
    test_html_report_generation
    test_error_handling
    
    echo "================================================"
    echo "Test Summary:"
    echo "Total: $TESTS_TOTAL"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    
    # Exit with failure if any tests failed
    if [ $TESTS_FAILED -gt 0 ]; then
        exit 1
    fi
}

# Run tests
run_tests 