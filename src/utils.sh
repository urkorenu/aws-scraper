#!/usr/bin/env bash

# AWS Infrastructure Inventory Tool - Utility Functions
# Copyright (c) 2024
# Licensed under MIT License

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Check if a command exists
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Required command '$cmd' not found"
        return 1
    fi
    return 0
}

# Validate AWS credentials
validate_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured or invalid"
        log_error "Please run 'aws configure' to set up your credentials"
        exit 1
    fi
}

# Get AWS account ID
get_aws_account_id() {
    aws sts get-caller-identity --query Account --output text
}

# Get AWS region
get_aws_region() {
    aws configure get region || echo "us-east-1"
}

# Format date for AWS API
format_date() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Get resource cost
get_resource_cost() {
    local resource_type="$1"
    local start_date="$2"
    local end_date="$3"
    
    aws ce get-cost-and-usage \
        --time-period Start="$start_date",End="$end_date" \
        --granularity MONTHLY \
        --metrics "BlendedCost" \
        --group-by Type=DIMENSION,Key=SERVICE \
        --filter "{\"Dimensions\": {\"Key\": \"SERVICE\",\"Values\": [\"$resource_type\"]}}" \
        --query "ResultsByTime[*].Groups[*].Metrics.BlendedCost.Amount" \
        --output text
}

# Convert JSON to table format
json_to_table() {
    local json="$1"
    local headers="$2"
    
    echo "$json" | jq -r "$headers" | column -t -s $'\t'
}

# Convert JSON to HTML table
json_to_html_table() {
    local json="$1"
    local title="$2"
    
    echo "<div class='resource-section'>"
    echo "<h2>$title</h2>"
    
    if [ "$json" == "[]" ] || [ "$json" == "null" ] || [ -z "$json" ]; then
        echo "<p class='no-resources'>No resources found.</p>"
    else
        echo "<div class='table-responsive'>"
        echo "<table class='resource-table'>"
        
        echo "<thead><tr>"
        echo "$json" | jq -r 'if type == "array" then .[0] else . end | keys[] | "<th>\(.)</th>"' 2>/dev/null || echo "<th>Value</th>"
        echo "</tr></thead><tbody>"
        
        echo "$json" | jq -r '
            if type == "array" then .[] else . end |
            to_entries |
            map(.value) |
            @tsv
        ' 2>/dev/null | while IFS=$'\t' read -r line; do
            echo "<tr>"
            for value in $line; do
                if [[ $value == "["* ]] || [[ $value == "{"* ]]; then
                    echo "<td><pre class='json-data'>$value</pre></td>"
                else
                    echo "<td>$value</td>"
                fi
            done
            echo "</tr>"
        done
        
        echo "</tbody></table></div>"
    fi
    echo "</div>"
}

# Export functions
export -f log_info log_warn log_error handle_error check_command validate_aws_credentials
export -f get_aws_account_id get_aws_region format_date get_resource_cost
export -f json_to_table json_to_html_table 