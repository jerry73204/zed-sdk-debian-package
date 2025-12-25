# ZED SDK Debian Package - Root Makefile
# This Makefile provides convenience targets for the platform-specific builds

.PHONY: help all clean clean-all

help:
	@echo "ZED SDK Debian Package - Multi-Platform Build System"
	@echo "====================================================="
	@echo ""
	@echo "This project has been reorganized into platform-specific directories:"
	@echo ""
	@echo "  amd64/    - For x86_64 desktop/server systems"
	@echo "  arm64/    - For generic ARM64 systems"  
	@echo "  jetpack/  - For NVIDIA Jetson platforms"
	@echo ""
	@echo "Usage:"
	@echo "  cd <platform>  # Navigate to your platform directory"
	@echo "  make build     # Build the package"
	@echo ""
	@echo "Root Makefile Targets:"
	@echo "  make clean     - Clean all platform build directories"
	@echo "  make clean-all - Remove all artifacts including downloads"
	@echo "  make help      - Show this help message"
	@echo ""
	@echo "Example:"
	@echo "  cd amd64 && make build"
	@echo ""

clean:
	@echo "Cleaning all platform build directories..."
	@for dir in amd64 arm64 jetpack; do \
		if [ -d "$$dir" ]; then \
			echo "  Cleaning $$dir..."; \
			$(MAKE) -C $$dir clean 2>/dev/null || true; \
		fi; \
	done
	@echo "All build directories cleaned."

clean-all:
	@echo "Removing all artifacts from all platforms..."
	@for dir in amd64 arm64 jetpack; do \
		if [ -d "$$dir" ]; then \
			echo "  Cleaning $$dir..."; \
			$(MAKE) -C $$dir clean-all 2>/dev/null || true; \
		fi; \
	done
	@echo "All artifacts removed."
