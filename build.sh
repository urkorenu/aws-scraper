#!/usr/bin/env bash

# AWS Infrastructure Inventory Tool - Build Script
# Copyright (c) 2024
# Licensed under MIT License

set -euo pipefail

# Version
VERSION="1.0.0"

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

# Create build directory
create_build_dir() {
    local build_dir="dist/aws-inventory-${VERSION}"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    echo "$build_dir"
}

# Copy files to build directory
copy_files() {
    local build_dir="$1"
    
    # Create directory structure
    mkdir -p "$build_dir"/{bin,src,man,tests}
    
    # Copy files
    cp bin/aws-inventory "$build_dir/bin/"
    cp src/*.sh "$build_dir/src/"
    cp man/aws-inventory.1 "$build_dir/man/"
    cp tests/test_aws_inventory.sh "$build_dir/tests/"
    cp install.sh "$build_dir/"
    cp README.md "$build_dir/"
    cp LICENSE "$build_dir/"
    
    # Make scripts executable
    chmod +x "$build_dir/bin/aws-inventory"
    chmod +x "$build_dir/install.sh"
    chmod +x "$build_dir/tests/test_aws_inventory.sh"
}

# Create archive
create_archive() {
    local build_dir="$1"
    local archive_name="aws-inventory-${VERSION}.tar.gz"
    
    cd "$(dirname "$build_dir")"
    tar -czf "$archive_name" "$(basename "$build_dir")"
    cd - > /dev/null
    
    echo "$archive_name"
}

# Run tests
run_tests() {
    log_info "Running tests..."
    if ! ./tests/test_aws_inventory.sh; then
        log_error "Tests failed"
        exit 1
    fi
    log_info "All tests passed"
}

# Main build function
main() {
    log_info "Building AWS Infrastructure Inventory Tool v${VERSION}"
    
    # Check dependencies
    check_dependencies
    
    # Run tests
    run_tests
    
    # Create build directory
    local build_dir
    build_dir=$(create_build_dir)
    
    # Copy files
    copy_files "$build_dir"
    
    # Create archive
    local archive_name
    archive_name=$(create_archive "$build_dir")
    
    log_info "Build completed successfully!"
    log_info "Archive created: $archive_name"
    log_info "You can now install the package using:"
    log_info "  tar -xzf $archive_name"
    log_info "  cd aws-inventory-${VERSION}"
    log_info "  ./install.sh"
}

# Run build
main 