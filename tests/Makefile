# ZED SDK Build Test Suite
# Tests docker-build across all versions and platforms

SHELL := /bin/bash
.PHONY: help all test clean test-v4.2 test-v5.0.5 test-v5.1.2 status

# All testable platforms
PLATFORMS_V4_2 := v4.2/amd64 v4.2/jp60
PLATFORMS_V5_0_5 := v5.0.5/amd64 v5.0.5/jp60
PLATFORMS_V5_1_2 := v5.1.2/amd64 v5.1.2/jp60
ALL_PLATFORMS := $(PLATFORMS_V4_2) $(PLATFORMS_V5_0_5) $(PLATFORMS_V5_1_2)

help:
	@echo "ZED SDK Build Test Suite"
	@echo "========================="
	@echo ""
	@echo "Targets:"
	@echo "  all          - Test all versions and platforms"
	@echo "  test-v4.2    - Test ZED SDK 4.2 (amd64, jp60)"
	@echo "  test-v5.0.5  - Test ZED SDK 5.0.5 (amd64, jp60)"
	@echo "  test-v5.1.2  - Test ZED SDK 5.1.2 (amd64, jp60)"
	@echo "  status       - Show build status for all platforms"
	@echo "  clean        - Remove all built packages"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - Docker installed and running"
	@echo "  - QEMU for ARM64 emulation (x86_64 hosts)"
	@echo ""
	@echo "Example:"
	@echo "  make test-v5.1.2    # Test latest version"
	@echo "  make all            # Test everything"
	@echo ""

all: test-v4.2 test-v5.0.5 test-v5.1.2
	@echo ""
	@echo "========================================"
	@echo "All builds completed successfully!"
	@echo "========================================"
	@$(MAKE) --no-print-directory status

test-v4.2:
	@echo ""
	@echo "========================================"
	@echo "Testing ZED SDK 4.2"
	@echo "========================================"
	@for platform in $(PLATFORMS_V4_2); do \
		$(MAKE) --no-print-directory test-platform PLATFORM=$$platform; \
	done

test-v5.0.5:
	@echo ""
	@echo "========================================"
	@echo "Testing ZED SDK 5.0.5"
	@echo "========================================"
	@for platform in $(PLATFORMS_V5_0_5); do \
		$(MAKE) --no-print-directory test-platform PLATFORM=$$platform; \
	done

test-v5.1.2:
	@echo ""
	@echo "========================================"
	@echo "Testing ZED SDK 5.1.2"
	@echo "========================================"
	@for platform in $(PLATFORMS_V5_1_2); do \
		$(MAKE) --no-print-directory test-platform PLATFORM=$$platform; \
	done

test-platform:
	@echo ""
	@echo "Building $(PLATFORM)..."
	@cd ../$(PLATFORM) && make docker-build
	@if [ $$? -eq 0 ]; then \
		echo "✓ $(PLATFORM) build successful"; \
		$(MAKE) --no-print-directory verify-package PLATFORM=$(PLATFORM); \
	else \
		echo "✗ $(PLATFORM) build failed"; \
		exit 1; \
	fi

verify-package:
	@echo "  Verifying package..."
	@if ls ../$(PLATFORM)/output/*.deb >/dev/null 2>&1; then \
		PKG=$$(ls ../$(PLATFORM)/output/*.deb | head -1); \
		SIZE=$$(du -h $$PKG | cut -f1); \
		echo "  ✓ Package found: $$(basename $$PKG) ($$SIZE)"; \
		dpkg-deb --info $$PKG | grep -E "Package:|Version:|Architecture:" | sed 's/^/    /'; \
	else \
		echo "  ✗ Package not found in output/"; \
		exit 1; \
	fi

status:
	@echo ""
	@echo "========================================"
	@echo "Build Status Summary"
	@echo "========================================"
	@echo ""
	@for platform in $(ALL_PLATFORMS); do \
		printf "%-20s " "$$platform:"; \
		if ls ../$$platform/output/*.deb >/dev/null 2>&1; then \
			PKG=$$(ls ../$$platform/output/*.deb | head -1); \
			SIZE=$$(du -h $$PKG | cut -f1); \
			printf "✓ Built ($${SIZE})\n"; \
		else \
			printf "○ Not built\n"; \
		fi; \
	done
	@echo ""

clean:
	@echo "Cleaning all built packages..."
	@for platform in $(ALL_PLATFORMS); do \
		if [ -d "../$$platform/output" ]; then \
			rm -f ../$$platform/output/*.deb; \
			echo "  Cleaned $$platform/output/"; \
		fi; \
	done
	@echo "✓ All packages removed"

check-docker:
	@echo "Checking Docker..."
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "✗ Docker not found"; \
		exit 1; \
	fi
	@if ! docker info >/dev/null 2>&1; then \
		echo "✗ Docker daemon not running"; \
		exit 1; \
	fi
	@echo "✓ Docker ready"

check-qemu:
	@echo "Checking QEMU (for ARM64 builds on x86_64)..."
	@if [ "$$(uname -m)" = "x86_64" ]; then \
		if command -v qemu-aarch64-static >/dev/null 2>&1; then \
			echo "✓ QEMU installed"; \
		else \
			echo "⚠ QEMU not found - ARM64 builds may fail"; \
			echo "  Install: sudo apt-get install qemu-user-static binfmt-support"; \
		fi; \
	else \
		echo "✓ Running on ARM64, QEMU not needed"; \
	fi

validate: check-docker check-qemu
	@echo "✓ Prerequisites validated"

.DEFAULT_GOAL := help
