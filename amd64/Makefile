# Makefile for ZED SDK AMD64 package

PKG_VERSION := $(shell grep "^pkgver=" PKGBUILD | cut -d'=' -f2)
PKG_NAME := zed-sdk

.PHONY: help build clean clean-all

help:
	@echo "ZED SDK AMD64 Package Build"
	@echo "==========================="
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build       - Build the AMD64 package"
	@echo "  clean       - Remove build artifacts"
	@echo "  clean-all   - Remove all files including downloads"
	@echo "  help        - Show this help"

build:
	@echo "Building $(PKG_NAME) $(PKG_VERSION) for AMD64..."
	makedeb -s

clean:
	@echo "Cleaning build artifacts..."
	rm -rf src pkg *.deb *.log

clean-all: clean
	@echo "Removing downloaded files..."
	rm -f ZED_SDK_*.run pyzed-*.whl