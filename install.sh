#!/usr/bin/env bash

# AWS Infrastructure Inventory Tool Installer
# Copyright (c) 2024
# Licensed under MIT License

# Installation directories
INSTALL_DIR="${HOME}/.local/share/aws-inventory"
BIN_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.aws-inventory"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

# Create necessary directories
log_info "Creating installation directories..."
mkdir -p "$INSTALL_DIR" 2>/dev/null || {
    log_error "Failed to create installation directory: $INSTALL_DIR"
    exit 1
}

mkdir -p "$BIN_DIR" 2>/dev/null || {
    log_error "Failed to create binary directory: $BIN_DIR"
    exit 1
}

# Copy source files with proper permissions
log_info "Copying source files..."
cp -r src/* "$INSTALL_DIR/" 2>/dev/null || {
    log_error "Failed to copy source files"
    exit 1
}

# Create binary script with proper permissions
log_info "Creating binary script..."
cat > "$BIN_DIR/aws-inventory" << EOF
#!/usr/bin/env bash
exec "$INSTALL_DIR/aws-inventory.sh" "\$@"
EOF

# Set proper permissions during installation
log_info "Setting permissions..."
install -m 755 "$INSTALL_DIR/aws-inventory.sh" "$INSTALL_DIR/"
install -m 755 "$INSTALL_DIR/html_report.sh" "$INSTALL_DIR/"
install -m 755 "$BIN_DIR/aws-inventory" "$BIN_DIR/"

# Create default config if it doesn't exist
if [ ! -f "$CONFIG_DIR/config.yaml" ]; then
    log_info "Creating default configuration..."
    mkdir -p "$CONFIG_DIR" 2>/dev/null || {
        log_warn "Failed to create config directory"
    }
    
    cat > "$CONFIG_DIR/config.yaml" << EOF
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
fi

# Check if ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    log_info "Adding ~/.local/bin to PATH..."
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
fi

log_info "Installation completed successfully!"
log_info "Please run 'source ~/.zshrc' to update your PATH"
log_info "You can now use the 'aws-inventory' command" 