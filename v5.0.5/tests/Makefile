# ZED SDK Test Suite Makefile
# Provides convenient targets for running installation comparison tests

SHELL := /bin/bash
.PHONY: help all build-images test clean clean-all clean-images clean-results clean-reports results reports list-images

# Configuration
SCRIPTS_DIR := ./scripts
RESULTS_DIR := ./results
REPORTS_DIR := ./reports

# Colors for output (if supported)
ifneq (,$(findstring xterm,${TERM}))
	BLUE := \033[0;34m
	GREEN := \033[0;32m
	YELLOW := \033[1;33m
	RED := \033[0;31m
	NC := \033[0m
else
	BLUE :=
	GREEN :=
	YELLOW :=
	RED :=
	NC :=
endif

help:
	@echo "$(BLUE)ZED SDK Installation Comparison Test Suite$(NC)"
	@echo "=============================================="
	@echo ""
	@echo "$(GREEN)Main Targets:$(NC)"
	@echo "  $(YELLOW)all$(NC)           - Build images, run tests, and generate reports"
	@echo "  $(YELLOW)build-images$(NC)  - Build Docker test images for all platforms"
	@echo "  $(YELLOW)test$(NC)          - Run comparison tests using existing images"
	@echo "  $(YELLOW)reports$(NC)       - Generate detailed analysis reports"
	@echo ""
	@echo "$(GREEN)Image Management:$(NC)"
	@echo "  $(YELLOW)list-images$(NC)   - List available test images"
	@echo "  $(YELLOW)clean-images$(NC)  - Remove all test Docker images"
	@echo ""
	@echo "$(GREEN)Results Management:$(NC)"
	@echo "  $(YELLOW)results$(NC)       - Show existing test results"
	@echo "  $(YELLOW)clean-results$(NC) - Remove test result files"
	@echo "  $(YELLOW)clean-reports$(NC) - Remove generated report files"
	@echo ""
	@echo "$(GREEN)Platform-Specific Targets:$(NC)"
	@echo "  $(YELLOW)amd64$(NC)         - Build, test, and report for AMD64 only"
	@echo "  $(YELLOW)arm64$(NC)         - Build, test, and report for ARM64 only"
	@echo ""
	@echo "$(GREEN)Cleanup:$(NC)"
	@echo "  $(YELLOW)clean$(NC)         - Remove results and reports"
	@echo "  $(YELLOW)clean-all$(NC)     - Remove everything (images, results, reports)"
	@echo ""
	@echo "$(GREEN)Prerequisites:$(NC)"
	@echo "  - Docker must be installed and running"
	@echo "  - .deb packages must be built (run 'make build' in platform dirs)"
	@echo ""
	@echo "$(GREEN)Example Workflow:$(NC)"
	@echo "  1. Build packages:    cd ../amd64 && make build"
	@echo "  2. Run full test:     make all"
	@echo "  3. Review reports:    make results"
	@echo ""

all: build-images test reports
	@echo "$(GREEN)✓ Complete test suite finished!$(NC)"
	@echo "$(BLUE)Check $(REPORTS_DIR)/comprehensive_analysis.txt for final results$(NC)"

build-images:
	@echo "$(BLUE)Building Docker test images...$(NC)"
	@$(SCRIPTS_DIR)/build-test-images.sh
	@echo "$(GREEN)✓ Images built successfully$(NC)"

test:
	@echo "$(BLUE)Running installation comparison tests...$(NC)"
	@$(SCRIPTS_DIR)/run-comparison.sh
	@echo "$(GREEN)✓ Tests completed$(NC)"

reports:
	@echo "$(BLUE)Generating detailed analysis reports...$(NC)"
	@$(SCRIPTS_DIR)/generate-report.sh
	@echo "$(GREEN)✓ Reports generated$(NC)"

# Platform-specific targets
amd64: amd64-build-images amd64-test amd64-reports
	@echo "$(GREEN)✓ AMD64 testing complete$(NC)"

arm64: arm64-build-images arm64-test arm64-reports
	@echo "$(GREEN)✓ ARM64 testing complete$(NC)"

amd64-build-images:
	@echo "$(BLUE)Building AMD64 test images...$(NC)"
	@$(SCRIPTS_DIR)/build-test-images.sh amd64

amd64-test:
	@echo "$(BLUE)Running AMD64 tests...$(NC)"
	@$(SCRIPTS_DIR)/run-comparison.sh amd64

amd64-reports:
	@echo "$(BLUE)Generating AMD64 reports...$(NC)"
	@$(SCRIPTS_DIR)/generate-report.sh amd64

arm64-build-images:
	@echo "$(BLUE)Building ARM64 test images...$(NC)"
	@$(SCRIPTS_DIR)/build-test-images.sh arm64

arm64-test:
	@echo "$(BLUE)Running ARM64 tests...$(NC)"
	@$(SCRIPTS_DIR)/run-comparison.sh arm64

arm64-reports:
	@echo "$(BLUE)Generating ARM64 reports...$(NC)"
	@$(SCRIPTS_DIR)/generate-report.sh arm64

# Quick targets
quick-test: test
	@echo "$(GREEN)✓ Quick test complete - check $(RESULTS_DIR) for results$(NC)"

quick-build:
	@echo "$(BLUE)Building images (no cache)...$(NC)"
	@$(SCRIPTS_DIR)/build-test-images.sh --no-cache

# Information targets
list-images:
	@echo "$(BLUE)Available ZED SDK test images:$(NC)"
	@$(SCRIPTS_DIR)/build-test-images.sh --list

results:
	@echo "$(BLUE)Existing test results:$(NC)"
	@$(SCRIPTS_DIR)/run-comparison.sh --results

status:
	@echo "$(BLUE)Test Suite Status:$(NC)"
	@echo "=================="
	@echo ""
	@echo "$(YELLOW)Docker Images:$(NC)"
	@docker images --filter "reference=zed-sdk-test-*" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" 2>/dev/null || echo "No test images found"
	@echo ""
	@echo "$(YELLOW)Test Results:$(NC)"
	@if [ -d "$(RESULTS_DIR)" ] && [ -n "$$(ls -A $(RESULTS_DIR) 2>/dev/null)" ]; then \
		ls -la $(RESULTS_DIR); \
	else \
		echo "No test results found"; \
	fi
	@echo ""
	@echo "$(YELLOW)Generated Reports:$(NC)"
	@if [ -d "$(REPORTS_DIR)" ] && [ -n "$$(ls -A $(REPORTS_DIR) 2>/dev/null)" ]; then \
		ls -la $(REPORTS_DIR); \
	else \
		echo "No reports found"; \
	fi

# Cleanup targets
clean: clean-results clean-reports
	@echo "$(GREEN)✓ Cleaned results and reports$(NC)"

clean-results:
	@echo "$(YELLOW)Removing test results...$(NC)"
	@rm -rf $(RESULTS_DIR)/*
	@echo "$(GREEN)✓ Test results cleaned$(NC)"

clean-reports:
	@echo "$(YELLOW)Removing generated reports...$(NC)"
	@rm -rf $(REPORTS_DIR)/*
	@echo "$(GREEN)✓ Reports cleaned$(NC)"

clean-images:
	@echo "$(YELLOW)Removing Docker test images...$(NC)"
	@$(SCRIPTS_DIR)/build-test-images.sh --clean
	@echo "$(GREEN)✓ Images cleaned$(NC)"

clean-all: clean-results clean-reports clean-images
	@echo "$(GREEN)✓ Complete cleanup finished$(NC)"

# Development targets
rebuild: clean-images build-images
	@echo "$(GREEN)✓ Images rebuilt$(NC)"

retest: clean-results test
	@echo "$(GREEN)✓ Tests re-run$(NC)"

full-rerun: clean-all all
	@echo "$(GREEN)✓ Full test suite re-run completed$(NC)"

# Validation targets
check-prereqs:
	@echo "$(BLUE)Checking prerequisites...$(NC)"
	@echo -n "Docker: "
	@if command -v docker >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Available$(NC)"; \
	else \
		echo "$(RED)✗ Not found$(NC)"; \
		exit 1; \
	fi
	@echo -n "Docker daemon: "
	@if docker info >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Running$(NC)"; \
	else \
		echo "$(RED)✗ Not accessible$(NC)"; \
		exit 1; \
	fi
	@echo -n "AMD64 .deb package: "
	@if [ -f "../amd64/zed-sdk_5.0.5-1_amd64.deb" ]; then \
		echo "$(GREEN)✓ Found$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Not found$(NC)"; \
	fi
	@echo -n "ARM64 .deb package: "
	@if [ -f "../arm64/zed-sdk_5.0.5-1_arm64.deb" ]; then \
		echo "$(GREEN)✓ Found$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Not found$(NC)"; \
	fi
	@echo "$(GREEN)✓ Prerequisite check complete$(NC)"

validate: check-prereqs
	@echo "$(BLUE)Validating test suite setup...$(NC)"
	@echo -n "Scripts directory: "
	@if [ -d "$(SCRIPTS_DIR)" ]; then \
		echo "$(GREEN)✓ Found$(NC)"; \
	else \
		echo "$(RED)✗ Missing$(NC)"; \
		exit 1; \
	fi
	@echo -n "Build script: "
	@if [ -x "$(SCRIPTS_DIR)/build-test-images.sh" ]; then \
		echo "$(GREEN)✓ Executable$(NC)"; \
	else \
		echo "$(RED)✗ Missing or not executable$(NC)"; \
		exit 1; \
	fi
	@echo -n "Test script: "
	@if [ -x "$(SCRIPTS_DIR)/run-comparison.sh" ]; then \
		echo "$(GREEN)✓ Executable$(NC)"; \
	else \
		echo "$(RED)✗ Missing or not executable$(NC)"; \
		exit 1; \
	fi
	@echo -n "Report script: "
	@if [ -x "$(SCRIPTS_DIR)/generate-report.sh" ]; then \
		echo "$(GREEN)✓ Executable$(NC)"; \
	else \
		echo "$(RED)✗ Missing or not executable$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ Test suite validation complete$(NC)"

# Development helpers
debug:
	@echo "$(BLUE)Debug Information:$(NC)"
	@echo "=================="
	@echo "Working directory: $$(pwd)"
	@echo "Scripts directory: $(SCRIPTS_DIR)"
	@echo "Results directory: $(RESULTS_DIR)"
	@echo "Reports directory: $(REPORTS_DIR)"
	@echo ""
	@echo "Available scripts:"
	@ls -la $(SCRIPTS_DIR)/*.sh 2>/dev/null || echo "No scripts found"

# Make scripts executable if needed
setup:
	@echo "$(BLUE)Setting up test suite...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/*.sh
	@chmod +x docker/common/*.sh
	@chmod +x docker/*/install-*.sh
	@mkdir -p $(RESULTS_DIR) $(REPORTS_DIR)
	@echo "$(GREEN)✓ Test suite setup complete$(NC)"

# Parallel execution for faster testing
parallel-test:
	@echo "$(BLUE)Running tests in parallel...$(NC)"
	@$(SCRIPTS_DIR)/run-comparison.sh amd64 & \
	$(SCRIPTS_DIR)/run-comparison.sh arm64 & \
	wait
	@echo "$(GREEN)✓ Parallel tests completed$(NC)"

.DEFAULT_GOAL := help