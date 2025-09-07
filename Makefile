# ZED SDK Debian Package Makefile
# Build a Debian package from the ZED SDK using makedeb

# Default target
.DEFAULT_GOAL := help

# Package version from PKGBUILD
PKG_VERSION := $(shell grep "^pkgver=" PKGBUILD | cut -d'=' -f2)
PKG_NAME := $(shell grep "^pkgname=" PKGBUILD | cut -d'=' -f2)
ARCH := $(shell dpkg --print-architecture)

# Downloaded SDK files patterns
DOWNLOADED_FILES := ZED_SDK_*.run pyzed-*.whl

# Build artifacts
BUILD_DIRS := src pkg
DEB_FILES := *.deb
LOG_FILES := *.log

.PHONY: help
help: ## Show this help message
	@echo "ZED SDK Debian Package - Makefile Targets"
	@echo "=========================================="
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Package info:"
	@echo "  Name:    $(PKG_NAME)"
	@echo "  Version: $(PKG_VERSION)"
	@echo "  Arch:    $(ARCH)"

.PHONY: build
build: ## Build the Debian package
	@echo "Building $(PKG_NAME) $(PKG_VERSION) for $(ARCH)..."
	makedeb -s

.PHONY: build-no-deps
build-no-deps: ## Build without installing dependencies
	@echo "Building $(PKG_NAME) $(PKG_VERSION) without dependency installation..."
	makedeb

.PHONY: clean
clean: ## Remove build artifacts (keeps downloaded files)
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIRS) $(DEB_FILES) $(LOG_FILES)
	@echo "Build artifacts removed."

.PHONY: clean-all
clean-all: clean ## Remove all generated files including downloads
	@echo "Removing downloaded files..."
	@for pattern in $(DOWNLOADED_FILES); do \
		if ls $$pattern 1> /dev/null 2>&1; then \
			echo "  Removing $$pattern files..."; \
			rm -f $$pattern; \
		fi; \
	done
	@echo "All files cleaned."

.PHONY: install
install: build ## Build and install the package
	@if [ -f "$(PKG_NAME)_$(PKG_VERSION)-1_$(ARCH).deb" ]; then \
		echo "Installing $(PKG_NAME)_$(PKG_VERSION)-1_$(ARCH).deb..."; \
		sudo dpkg -i $(PKG_NAME)_$(PKG_VERSION)-1_$(ARCH).deb; \
	else \
		echo "Package not found. Run 'make build' first."; \
		exit 1; \
	fi

.PHONY: uninstall
uninstall: ## Uninstall the package
	@echo "Uninstalling $(PKG_NAME)..."
	sudo apt remove -y $(PKG_NAME)

.PHONY: info
info: ## Show package information
	@if [ -f "$(PKG_NAME)_$(PKG_VERSION)-1_$(ARCH).deb" ]; then \
		echo "Package information for $(PKG_NAME)_$(PKG_VERSION)-1_$(ARCH).deb:"; \
		echo ""; \
		dpkg-deb -I $(PKG_NAME)_$(PKG_VERSION)-1_$(ARCH).deb; \
	else \
		echo "Package not found. Run 'make build' first."; \
	fi

.PHONY: contents
contents: ## List package contents
	@if [ -f "$(PKG_NAME)_$(PKG_VERSION)-1_$(ARCH).deb" ]; then \
		echo "Contents of $(PKG_NAME)_$(PKG_VERSION)-1_$(ARCH).deb:"; \
		echo ""; \
		dpkg-deb -c $(PKG_NAME)_$(PKG_VERSION)-1_$(ARCH).deb | head -50; \
		echo ""; \
		echo "... (showing first 50 entries)"; \
	else \
		echo "Package not found. Run 'make build' first."; \
	fi

.PHONY: check-deps
check-deps: ## Check for missing build dependencies
	@echo "Checking dependencies for $(PKG_NAME)..."
	makedeb --no-build --print-missing-deps

.PHONY: download
download: ## Download source files only
	@echo "Downloading source files..."
	makedeb --nobuild

.PHONY: verify
verify: ## Verify checksums of downloaded files
	@echo "Verifying checksums..."
	makedeb --verifysource