# Makefile for AWS Infrastructure Inventory Tool

# Version
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "0.0.0")

# Directories
SRC_DIR := src
TEST_DIR := tests
DIST_DIR := dist
DOC_DIR := docs
MAN_DIR := man

# Files
MAIN_SCRIPT := $(SRC_DIR)/aws-inventory.sh
HTML_REPORT := $(SRC_DIR)/html_report.sh
UTILS := $(SRC_DIR)/utils.sh
CONFIG := config.yaml

# Dependencies
DEPS := aws jq yq

# Default target
all: build

# Build the project
build: check-deps
	@echo "Building AWS Infrastructure Inventory Tool v$(VERSION)..."
	@mkdir -p $(DIST_DIR)
	@cp $(MAIN_SCRIPT) $(DIST_DIR)/aws-inventory
	@cp $(HTML_REPORT) $(DIST_DIR)/html_report.sh
	@cp $(UTILS) $(DIST_DIR)/utils.sh
	@cp $(CONFIG) $(DIST_DIR)/config.yaml
	@chmod +x $(DIST_DIR)/aws-inventory
	@echo "Build complete!"

# Check dependencies
check-deps:
	@echo "Checking dependencies..."
	@for dep in $(DEPS); do \
		if ! command -v $$dep &> /dev/null; then \
			echo "Error: $$dep is not installed"; \
			exit 1; \
		fi \
	done
	@echo "All dependencies found."

# Run tests
test: check-deps
	@echo "Running tests..."
	@if [ -d "$(TEST_DIR)" ]; then \
		for test in $(TEST_DIR)/*.sh; do \
			if [ -f "$$test" ]; then \
				echo "Running $$test..."; \
				bash "$$test" || exit 1; \
			fi \
		done \
	fi
	@echo "All tests passed!"

# Run shellcheck
lint: check-deps
	@echo "Running shellcheck..."
	@if command -v shellcheck &> /dev/null; then \
		shellcheck $(SRC_DIR)/*.sh || exit 1; \
	else \
		echo "Error: shellcheck is not installed"; \
		exit 1; \
	fi
	@echo "Shellcheck passed!"

# Generate documentation
docs:
	@echo "Generating documentation..."
	@mkdir -p $(DOC_DIR)
	@if [ -d "$(MAN_DIR)" ]; then \
		for man in $(MAN_DIR)/*.md; do \
			if [ -f "$$man" ]; then \
				man_page=$$(basename "$$man" .md); \
				pandoc -f markdown -t man "$$man" -o "$(DOC_DIR)/$$man_page.1"; \
			fi \
		done \
	fi
	@echo "Documentation generated!"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(DIST_DIR)
	@rm -rf __pycache__
	@rm -rf .pytest_cache
	@echo "Clean complete!"

# Install the tool
install: build
	@echo "Installing AWS Infrastructure Inventory Tool..."
	@sudo cp $(DIST_DIR)/aws-inventory /usr/local/bin/
	@sudo cp $(DIST_DIR)/html_report.sh /usr/local/share/aws-inventory/
	@sudo cp $(DIST_DIR)/utils.sh /usr/local/share/aws-inventory/
	@sudo cp $(DIST_DIR)/config.yaml /etc/aws-inventory/config.yaml
	@echo "Installation complete!"

# Uninstall the tool
uninstall:
	@echo "Uninstalling AWS Infrastructure Inventory Tool..."
	@sudo rm -f /usr/local/bin/aws-inventory
	@sudo rm -rf /usr/local/share/aws-inventory
	@sudo rm -rf /etc/aws-inventory
	@echo "Uninstallation complete!"

# Create a release
release: build test lint docs
	@echo "Creating release v$(VERSION)..."
	@mkdir -p $(DIST_DIR)/release
	@cp -r $(DIST_DIR)/* $(DIST_DIR)/release/
	@tar -czf $(DIST_DIR)/aws-inventory-$(VERSION).tar.gz -C $(DIST_DIR)/release .
	@rm -rf $(DIST_DIR)/release
	@echo "Release created!"

# Show help
help:
	@echo "AWS Infrastructure Inventory Tool Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all          Build the project (default)"
	@echo "  build        Build the project"
	@echo "  test         Run tests"
	@echo "  lint         Run shellcheck"
	@echo "  docs         Generate documentation"
	@echo "  clean        Clean build artifacts"
	@echo "  install      Install the tool"
	@echo "  uninstall    Uninstall the tool"
	@echo "  release      Create a release"
	@echo "  help         Show this help message"

.PHONY: all build check-deps test lint docs clean install uninstall release help 