#!/usr/bin/env bash

# AWS Infrastructure Inventory Tool
# Copyright (c) 2024
# Licensed under MIT License

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Version
VERSION="1.0.0"

# Default configuration
CONFIG_FILE="${HOME}/.aws-inventory/config.yaml"
DEFAULT_CONFIG_DIR="${HOME}/.aws-inventory"
DEFAULT_OUTPUT_DIR="${HOME}/.aws-inventory/reports"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize variables
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error handling
handle_error() {
    local exit_code=$?
    local line_number=$1
    log_error "Error occurred in line $line_number"
    exit $exit_code
}

trap 'handle_error ${LINENO}' ERR

# Main inventory function
run_inventory() {
    log_info "Starting AWS Infrastructure Inventory"
    
    # Load configuration
    load_config
    
    # Validate AWS credentials
    validate_aws_credentials
    
    # Initialize output
    initialize_output
    
    # Collect resource data
    collect_resources
    
    # Generate report
    generate_report
    
    log_info "Inventory completed successfully"
}

# Load configuration from file
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_warn "Configuration file not found at $CONFIG_FILE. Using defaults."
        create_default_config
    fi
    
    # Load configuration with proper error handling
    export EC2_ENABLED=$(yq e '.resources.ec2 // true' "$CONFIG_FILE" 2>/dev/null || echo "true")
    export S3_ENABLED=$(yq e '.resources.s3 // true' "$CONFIG_FILE" 2>/dev/null || echo "true")
    export RDS_ENABLED=$(yq e '.resources.rds // true' "$CONFIG_FILE" 2>/dev/null || echo "true")
    export LAMBDA_ENABLED=$(yq e '.resources.lambda // true' "$CONFIG_FILE" 2>/dev/null || echo "true")
    export VPC_ENABLED=$(yq e '.resources.vpc // true' "$CONFIG_FILE" 2>/dev/null || echo "true")
    
    # Handle output format with proper defaults
    local raw_format
    raw_format=$(yq e '.output.format // "json"' "$CONFIG_FILE" 2>/dev/null || echo "json")
    export OUTPUT_FORMAT="$raw_format"
    
    # Get output directory with proper defaults
    local output_dir
    output_dir=$(yq e '.output.directory // "~/.aws-inventory/reports"' "$CONFIG_FILE" 2>/dev/null || echo "$DEFAULT_OUTPUT_DIR")
    export OUTPUT_DIR="${output_dir/#\~/$HOME}"
    
    # Load filters with proper error handling
    export FILTER_TAG_KEY=$(yq e '.filters.tags | keys | .[0] // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
    if [ -n "$FILTER_TAG_KEY" ]; then
        export FILTER_TAG_VALUE=$(yq e ".filters.tags.[\"$FILTER_TAG_KEY\"] // \"\"" "$CONFIG_FILE" 2>/dev/null || echo "")
    else
        export FILTER_TAG_VALUE=""
    fi
    
    # Load VPC filters with proper defaults
    export VPC_EXCLUDE_DEFAULT=$(yq e '.filters.vpc.exclude_default // true' "$CONFIG_FILE" 2>/dev/null || echo "true")
    export VPC_EXCLUDE_MAIN_ROUTES=$(yq e '.filters.vpc.exclude_main_route_tables // true' "$CONFIG_FILE" 2>/dev/null || echo "true")
    export VPC_EXCLUDE_DEFAULT_SUBNETS=$(yq e '.filters.vpc.exclude_default_subnets // true' "$CONFIG_FILE" 2>/dev/null || echo "true")
}

# Create default configuration
create_default_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")" 2>/dev/null || true
    cat > "$CONFIG_FILE" << EOF
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
    log_info "Created default configuration at $CONFIG_FILE"
}

# Initialize output based on format
initialize_output() {
    # Create output directory
    mkdir -p "$OUTPUT_DIR" 2>/dev/null || {
        log_warn "Failed to create output directory: $OUTPUT_DIR"
        OUTPUT_DIR="$TEMP_DIR"
    }
    
    # Set output filename with timestamp
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    case "$OUTPUT_FORMAT" in
        "html")
            OUTPUT_FILE="$OUTPUT_DIR/aws_inventory_$timestamp.html"
            ;;
        "json")
            OUTPUT_FILE="$OUTPUT_DIR/aws_inventory_$timestamp.json"
            ;;
        "yaml")
            OUTPUT_FILE="$OUTPUT_DIR/aws_inventory_$timestamp.yaml"
            ;;
        "table")
            OUTPUT_FILE="$OUTPUT_DIR/aws_inventory_$timestamp.txt"
            ;;
        *)
            log_error "Invalid output format: $OUTPUT_FORMAT"
            exit 1
            ;;
    esac
    
    # Create a symlink to the latest report
    local latest_link="$OUTPUT_DIR/aws_inventory_latest${OUTPUT_FILE##*aws_inventory_*}"
    ln -sf "$OUTPUT_FILE" "$latest_link" 2>/dev/null || true
}

# Collect resource data
collect_resources() {
    local resources=()
    
    # Collect EC2 instances
    if [ "$EC2_ENABLED" == "true" ]; then
        collect_ec2_instances
    fi
    
    # Collect S3 buckets
    if [ "$S3_ENABLED" == "true" ]; then
        collect_s3_buckets
    fi
    
    # Collect RDS instances
    if [ "$RDS_ENABLED" == "true" ]; then
        collect_rds_instances
    fi
    
    # Collect Lambda functions
    if [ "$LAMBDA_ENABLED" == "true" ]; then
        collect_lambda_functions
    fi
    
    # Collect VPC resources
    if [ "$VPC_ENABLED" == "true" ]; then
        collect_vpc_resources
    fi
}

# Generate report based on format
generate_report() {
    case "$OUTPUT_FORMAT" in
        "html")
            generate_html_report
            ;;
        "json")
            generate_json_report
            ;;
        "yaml")
            generate_yaml_report
            ;;
        "table")
            generate_table_report
            ;;
    esac
    
    log_info "Report generated at: $OUTPUT_FILE"
}

# Resource collection functions
collect_ec2_instances() {
    log_info "Collecting EC2 instances..."
    aws ec2 describe-instances \
        --query "Reservations[*].Instances[*].{
            ID:InstanceId,
            Name:Tags[?Key=='Name'].Value|[0],
            State:State.Name,
            Type:InstanceType,
            Platform:Platform,
            PrivateIP:PrivateIpAddress,
            PublicIP:PublicIpAddress,
            LaunchTime:LaunchTime
        }" \
        --output json > "$TEMP_DIR/ec2.json" || echo "[]" > "$TEMP_DIR/ec2.json"
}

collect_s3_buckets() {
    log_info "Collecting S3 buckets..."
    aws s3api list-buckets \
        --query "Buckets[*].{Name:Name,CreationDate:CreationDate}" \
        --output json > "$TEMP_DIR/s3.json" || echo "[]" > "$TEMP_DIR/s3.json"
}

collect_rds_instances() {
    log_info "Collecting RDS instances..."
    aws rds describe-db-instances \
        --query "DBInstances[*].{
            ID:DBInstanceIdentifier,
            Engine:Engine,
            Status:DBInstanceStatus,
            Endpoint:Endpoint.Address
        }" \
        --output json > "$TEMP_DIR/rds.json" || echo "[]" > "$TEMP_DIR/rds.json"
}

collect_lambda_functions() {
    log_info "Collecting Lambda functions..."
    aws lambda list-functions \
        --query "Functions[*].{
            Name:FunctionName,
            Runtime:Runtime,
            Memory:MemorySize
        }" \
        --output json > "$TEMP_DIR/lambda.json" || echo "[]" > "$TEMP_DIR/lambda.json"
}

collect_vpc_resources() {
    log_info "Collecting VPC resources..."
    aws ec2 describe-vpcs \
        --query "Vpcs[*].{
            VpcId:VpcId,
            CidrBlock:CidrBlock,
            State:State,
            IsDefault:IsDefault
        }" \
        --output json > "$TEMP_DIR/vpc.json" || echo "[]" > "$TEMP_DIR/vpc.json"
}

# Report generation functions
generate_html_report() {
    source "$SCRIPT_DIR/html_report.sh"
    generate_html_report "$TEMP_DIR" "$OUTPUT_FILE"
}

generate_json_report() {
    jq -s '{
        ec2: (.[0] // []),
        s3: (.[1] // []),
        rds: (.[2] // []),
        lambda: (.[3] // []),
        vpc: (.[4] // [])
    }' \
    "$TEMP_DIR"/{ec2,s3,rds,lambda,vpc}.json > "$OUTPUT_FILE"
}

generate_yaml_report() {
    jq -s '{
        ec2: (.[0] // []),
        s3: (.[1] // []),
        rds: (.[2] // []),
        lambda: (.[3] // []),
        vpc: (.[4] // [])
    }' \
    "$TEMP_DIR"/{ec2,s3,rds,lambda,vpc}.json | yq eval -P - > "$OUTPUT_FILE"
}

generate_table_report() {
    {
        echo "EC2 Instances:"
        jq -r '.[] | "\(.ID) | \(.Name) | \(.State) | \(.Type)"' "$TEMP_DIR/ec2.json" 2>/dev/null || echo "No EC2 instances found"
        echo -e "\nS3 Buckets:"
        jq -r '.[] | "\(.Name) | \(.CreationDate)"' "$TEMP_DIR/s3.json" 2>/dev/null || echo "No S3 buckets found"
        echo -e "\nRDS Instances:"
        jq -r '.[] | "\(.ID) | \(.Engine) | \(.Status)"' "$TEMP_DIR/rds.json" 2>/dev/null || echo "No RDS instances found"
        echo -e "\nLambda Functions:"
        jq -r '.[] | "\(.Name) | \(.Runtime) | \(.Memory)MB"' "$TEMP_DIR/lambda.json" 2>/dev/null || echo "No Lambda functions found"
        echo -e "\nVPC Resources:"
        jq -r '.[] | "\(.VpcId) | \(.CidrBlock) | \(.State)"' "$TEMP_DIR/vpc.json" 2>/dev/null || echo "No VPC resources found"
    } > "$OUTPUT_FILE"
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    for cmd in aws jq yq; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_error "Please install the missing dependencies and try again."
        exit 1
    fi
}

# Create necessary directories
setup_directories() {
    mkdir -p "$DEFAULT_CONFIG_DIR" 2>/dev/null || true
    mkdir -p "$DEFAULT_OUTPUT_DIR" 2>/dev/null || true
}

# Parse command line arguments
parse_args() {
    local format=""
    local output=""
    local verbose=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--format)
                format="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -o|--output)
                output="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Set output format
    if [ -n "$format" ]; then
        export OUTPUT_FORMAT="$format"
    fi
    
    # Set output file
    if [ -n "$output" ]; then
        export OUTPUT_FILE="$output"
    fi
    
    # Set verbose mode
    if [ "$verbose" = true ]; then
        export VERBOSE=true
    fi
}

# Show help message
show_help() {
    cat << EOF
AWS Infrastructure Inventory Tool v${VERSION}

Usage: aws-inventory [OPTIONS]

Options:
  -f, --format FORMAT    Output format (json|html|table|yaml)
  -c, --config FILE     Configuration file path
  -o, --output FILE     Output file path
  -v, --verbose         Enable verbose logging
  -h, --help           Show this help message

For more information, visit: https://github.com/yourusername/aws-scraper
EOF
}

# Main function
main() {
    # Initialize
    setup_directories
    check_dependencies
    parse_args "$@"
    
    # Run the inventory
    run_inventory
}

# Run main function with all arguments
main "$@" 