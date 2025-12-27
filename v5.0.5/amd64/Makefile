# Makefile for ZED SDK AMD64 Debian Package (debhelper-based)

PKG_VERSION := $(shell dpkg-parsechangelog -S Version 2>/dev/null || echo "5.0.5-1")
PKG_NAME := zed-sdk
VER_MAJOR_MINOR := $(shell echo $(PKG_VERSION) | cut -d- -f1 | cut -d. -f1-2)

# File names
RUN_FILE := ZED_SDK_Ubuntu22_cuda12.8_tensorrt10.9_v$(shell echo $(PKG_VERSION) | cut -d- -f1).zstd.run
WHL_FILE := pyzed-$(VER_MAJOR_MINOR)-cp310-cp310-linux_x86_64.whl

.PHONY: help build clean clean-all download check-deps docker-build docker-shell

help:
	@echo "ZED SDK AMD64 Debian Package (debhelper)"
	@echo "========================================="
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build        - Build the Debian package"
	@echo "  docker-build - Build in Docker container (recommended)"
	@echo "  docker-shell - Interactive Docker shell"
	@echo "  download     - Download SDK and Python wheel"
	@echo "  clean        - Clean build artifacts"
	@echo "  clean-all    - Clean everything including downloads"
	@echo "  check-deps   - Check build dependencies"
	@echo "  help         - Show this help"

check-deps:
	@echo "Checking build dependencies..."
	@dpkg-checkbuilddeps debian/control 2>/dev/null || (echo "Missing dependencies. Install with:"; \
		echo "  sudo apt build-dep ."; exit 1)

download:
	@if [ ! -f "$(RUN_FILE)" ]; then \
		echo "Downloading SDK installer..."; \
		wget -O "$(RUN_FILE)" \
			"https://download.stereolabs.com/zedsdk/$(shell echo $(PKG_VERSION) | cut -d- -f1)/cu12/ubuntu22"; \
	else \
		echo "SDK installer already downloaded: $(RUN_FILE)"; \
	fi
	@echo "Python wheel will be downloaded automatically during build"

build: check-deps download
	@echo "Building $(PKG_NAME) $(PKG_VERSION) package..."
	dpkg-buildpackage -us -uc -b

clean:
	@echo "Cleaning build artifacts..."
	rm -rf extract/ debian/.debhelper/ debian/$(PKG_NAME)/
	rm -f debian/files debian/debhelper-build-stamp 001-zed.conf
	rm -f debian/*.substvars debian/*.debhelper.log
	rm -f ../*.buildinfo ../*.changes ../*.deb

clean-all: clean
	@echo "Removing downloaded files..."
	rm -f $(RUN_FILE) $(WHL_FILE)

docker-build:
	@echo "Building $(PKG_NAME) $(PKG_VERSION) in Docker (Ubuntu 22.04 environment)..."
	cd docker && ./docker-build.sh

docker-shell:
	@echo "Starting interactive shell in Docker container..."
	cd docker && ./docker-build.sh --interactive
