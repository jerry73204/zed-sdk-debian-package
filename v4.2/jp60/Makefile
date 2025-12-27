# Makefile for ZED SDK Jetpack package (debhelper)

PKG_VERSION := 4.2
PKG_NAME := zed-sdk-jetpack

.PHONY: help build clean clean-all docker-build docker-shell

help:
	@echo "ZED SDK Jetpack Package Build (debhelper)"
	@echo "=========================================="
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build         - Build the Jetpack package (native)"
	@echo "  docker-build  - Build using Docker (simulated Jetson env)"
	@echo "  docker-shell  - Run interactive shell in Docker container"
	@echo "  clean         - Remove build artifacts"
	@echo "  clean-all     - Remove all files including downloads"
	@echo "  help          - Show this help"
	@echo ""
	@echo "Docker builds use NVIDIA L4T container to simulate Jetson Linux"

build:
	@echo "Building $(PKG_NAME) $(PKG_VERSION) for NVIDIA Jetson..."
	dpkg-buildpackage -us -uc -b

docker-build:
	@echo "Building $(PKG_NAME) $(PKG_VERSION) in Docker (L4T environment)..."
	cd docker && ./docker-build.sh

docker-shell:
	@echo "Starting interactive shell in Docker container..."
	cd docker && ./docker-build.sh --interactive

clean:
	@echo "Cleaning build artifacts..."
	rm -rf build debian/.debhelper debian/files debian/debhelper-build-stamp
	rm -rf debian/zed-sdk-jetpack debian/zed-sdk-jetpack.substvars
	rm -f ../*.deb ../*.buildinfo ../*.changes
	rm -rf output/*
	dh_clean

clean-all: clean
	@echo "Removing downloaded files..."
	rm -f ZED_SDK_*.run pyzed-*.whl
