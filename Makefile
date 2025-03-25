.PHONY: all build clean dist debian homebrew test

# Version
VERSION := 1.0.0

# Build directories
DIST_DIR := dist/aws-inventory-$(VERSION)
BUILD_DIR := build

# Package files
DEB_PACKAGE := aws-inventory_$(VERSION)_all.deb
TAR_PACKAGE := aws-inventory-$(VERSION).tar.gz

all: build

build: clean
	@echo "Building AWS Infrastructure Inventory Tool v$(VERSION)..."
	@mkdir -p $(DIST_DIR)/{bin,src,man,tests}
	@cp bin/aws-inventory $(DIST_DIR)/bin/
	@cp src/*.sh $(DIST_DIR)/src/
	@cp man/aws-inventory.1 $(DIST_DIR)/man/
	@cp tests/test_aws_inventory.sh $(DIST_DIR)/tests/
	@cp install.sh $(DIST_DIR)/
	@cp README.md $(DIST_DIR)/
	@cp LICENSE $(DIST_DIR)/
	@chmod +x $(DIST_DIR)/bin/aws-inventory
	@chmod +x $(DIST_DIR)/install.sh
	@chmod +x $(DIST_DIR)/tests/test_aws_inventory.sh
	@echo "Build completed successfully!"

clean:
	@echo "Cleaning build directories..."
	@rm -rf $(DIST_DIR) $(BUILD_DIR)
	@find . -type f -name "*.tar.gz" -delete
	@find . -type f -name "*.deb" -delete

dist: build
	@echo "Creating distribution package..."
	@cd $(dir $(DIST_DIR)) && tar -czf $(TAR_PACKAGE) $(notdir $(DIST_DIR))
	@echo "Distribution package created: $(TAR_PACKAGE)"

debian: dist
	@echo "Building Debian package..."
	@cp -r $(DIST_DIR) $(BUILD_DIR)
	@cp -r debian $(BUILD_DIR)/
	@cd $(BUILD_DIR) && dpkg-buildpackage -us -uc
	@mv $(BUILD_DIR)/../$(DEB_PACKAGE) .
	@echo "Debian package created: $(DEB_PACKAGE)"

homebrew: dist
	@echo "Updating Homebrew formula..."
	@SHA256=$$(sha256sum $(TAR_PACKAGE) | cut -d' ' -f1) && \
	sed -i "s/sha256 \".*\"/sha256 \"$$SHA256\"/" aws-inventory.rb
	@echo "Homebrew formula updated with new SHA256"

test:
	@echo "Running tests..."
	@./tests/test_aws_inventory.sh

help:
	@echo "Available targets:"
	@echo "  all        - Build the package (default)"
	@echo "  build      - Build the package"
	@echo "  clean      - Clean build directories"
	@echo "  dist       - Create distribution package"
	@echo "  debian     - Build Debian package"
	@echo "  homebrew   - Update Homebrew formula"
	@echo "  test       - Run tests"
	@echo "  help       - Show this help message" 