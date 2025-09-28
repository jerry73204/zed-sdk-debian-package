#!/bin/bash
# ZED SDK Installation Comparison Test Runner
# Runs comparison tests between .run file and .deb package installations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TESTS_DIR="$PROJECT_ROOT/tests"
RESULTS_DIR="$TESTS_DIR/results"

# Image naming
IMAGE_PREFIX="zed-sdk-test"
TAG="latest"

# Available platforms and methods
PLATFORMS=("amd64" "arm64")
INSTALL_METHODS=("runfile" "deb")

# Create results directory
mkdir -p "$RESULTS_DIR"

# Function to print colored output
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}[$(date '+%H:%M:%S')] $message${NC}"
}

# Function to check Docker availability
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_status "$RED" "ERROR: Docker is not installed or not in PATH"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_status "$RED" "ERROR: Docker daemon is not running or not accessible"
        exit 1
    fi
}

# Function to check if test images exist
check_test_images() {
    local missing_images=()

    for platform in "${PLATFORMS[@]}"; do
        for method in "${INSTALL_METHODS[@]}"; do
            local image_name="$IMAGE_PREFIX-$platform-$method:$TAG"
            if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$image_name$"; then
                missing_images+=("$image_name")
            fi
        done
    done

    if [ ${#missing_images[@]} -ne 0 ]; then
        print_status "$RED" "ERROR: Missing test images:"
        for image in "${missing_images[@]}"; do
            print_status "$RED" "  - $image"
        done
        print_status "$YELLOW" "Run './scripts/build-test-images.sh' first"
        exit 1
    fi

    print_status "$GREEN" "All required test images found"
}

# Function to run a single container and collect results
run_container_test() {
    local platform="$1"
    local method="$2"
    local image_name="$IMAGE_PREFIX-$platform-$method:$TAG"
    local container_name="zed-test-$platform-$method-$(date +%s)"
    local result_file="$RESULTS_DIR/${platform}_${method}_results.txt"
    local manifest_file="$RESULTS_DIR/${platform}_${method}_manifest.txt"

    print_status "$BLUE" "Testing $image_name..."

    # Run the container
    local run_start=$(date +%s)

    if docker run \
        --name "$container_name" \
        --rm \
        "$image_name" > "$result_file" 2>&1; then

        local run_end=$(date +%s)
        local run_time=$((run_end - run_start))

        print_status "$GREEN" "Container test completed successfully (${run_time}s)"

        # Extract manifest if available
        docker run --rm "$image_name" cat /tmp/zed_manifest.txt > "$manifest_file" 2>/dev/null || true

        # Extract additional comparison data
        docker run --rm "$image_name" cat /tmp/zed_comparison_report.txt >> "$result_file" 2>/dev/null || true

        return 0
    else
        print_status "$RED" "Container test failed"
        print_status "$YELLOW" "Error output saved to: $result_file"
        return 1
    fi
}

# Function to run tests for a platform
run_platform_tests() {
    local platform="$1"
    local success_count=0

    print_status "$MAGENTA" "Running tests for platform: $platform"
    print_status "$MAGENTA" "$(printf '=%.0s' {1..50})"

    for method in "${INSTALL_METHODS[@]}"; do
        if run_container_test "$platform" "$method"; then
            ((success_count++))
        fi
        echo
    done

    print_status "$MAGENTA" "Platform $platform: $success_count/${#INSTALL_METHODS[@]} tests completed successfully"
    return $success_count
}

# Function to compare results between methods
compare_platform_results() {
    local platform="$1"
    local runfile_results="$RESULTS_DIR/${platform}_runfile_results.txt"
    local deb_results="$RESULTS_DIR/${platform}_deb_results.txt"
    local comparison_file="$RESULTS_DIR/${platform}_comparison.txt"

    print_status "$CYAN" "Comparing results for $platform..."

    if [ -f "$runfile_results" ] && [ -f "$deb_results" ]; then
        {
            echo "ZED SDK Installation Comparison Report - $platform"
            echo "Generated: $(date)"
            echo "=================================================="
            echo ""

            echo "RUNFILE INSTALLATION SUMMARY:"
            echo "$(printf '=%.0s' {1..30})"
            grep -E "(SUCCESS|ERROR|WARNING|FOUND|MISSING):" "$runfile_results" | head -20
            echo ""

            echo "DEB INSTALLATION SUMMARY:"
            echo "$(printf '=%.0s' {1..30})"
            grep -E "(SUCCESS|ERROR|WARNING|FOUND|MISSING):" "$deb_results" | head -20
            echo ""

            echo "DETAILED COMPARISON:"
            echo "$(printf '=%.0s' {1..30})"

            # Compare specific aspects
            local runfile_files=$(grep "files," "$runfile_results" | grep -o '[0-9]* files' | head -1 | cut -d' ' -f1 || echo "0")
            local deb_files=$(grep "files," "$deb_results" | grep -o '[0-9]* files' | head -1 | cut -d' ' -f1 || echo "0")

            echo "File counts:"
            echo "  Runfile: $runfile_files files"
            echo "  Deb:     $deb_files files"

            if [ "$runfile_files" = "$deb_files" ]; then
                echo "  Status:  ✓ MATCH"
            else
                echo "  Status:  ✗ DIFFER"
            fi
            echo ""

            # Compare Python package status
            local runfile_python=$(grep "pyzed" "$runfile_results" | grep -c "SUCCESS" || echo "0")
            local deb_python=$(grep "pyzed" "$deb_results" | grep -c "SUCCESS" || echo "0")

            echo "Python package (pyzed):"
            echo "  Runfile: $([ "$runfile_python" -gt 0 ] && echo "✓ SUCCESS" || echo "✗ FAILED")"
            echo "  Deb:     $([ "$deb_python" -gt 0 ] && echo "✓ SUCCESS" || echo "✗ FAILED")"
            echo ""

            # Compare library configuration
            local runfile_libs=$(grep "ZED libraries in ldconfig" "$runfile_results" | grep -o '[0-9]*' | head -1 || echo "0")
            local deb_libs=$(grep "ZED libraries in ldconfig" "$deb_results" | grep -o '[0-9]*' | head -1 || echo "0")

            echo "Library configuration:"
            echo "  Runfile: $runfile_libs libraries in ldconfig"
            echo "  Deb:     $deb_libs libraries in ldconfig"

            if [ "$runfile_libs" = "$deb_libs" ]; then
                echo "  Status:  ✓ MATCH"
            else
                echo "  Status:  ✗ DIFFER"
            fi
            echo ""

            # Overall assessment
            echo "OVERALL ASSESSMENT:"
            echo "$(printf '=%.0s' {1..30})"

            local major_differences=0

            if [ "$runfile_files" != "$deb_files" ]; then
                ((major_differences++))
                echo "⚠ File count mismatch detected"
            fi

            if [ "$runfile_python" != "$deb_python" ]; then
                ((major_differences++))
                echo "⚠ Python package installation differs"
            fi

            if [ "$runfile_libs" != "$deb_libs" ]; then
                ((major_differences++))
                echo "⚠ Library configuration differs"
            fi

            if [ $major_differences -eq 0 ]; then
                echo "✓ Installations appear equivalent"
                echo "✓ No major differences detected"
            else
                echo "✗ $major_differences major difference(s) detected"
                echo "⚠ Manual review recommended"
            fi

        } > "$comparison_file"

        print_status "$GREEN" "Comparison saved to: $comparison_file"
        return 0
    else
        print_status "$YELLOW" "Cannot compare - missing result files for $platform"
        return 1
    fi
}

# Function to generate summary report
generate_summary_report() {
    local summary_file="$RESULTS_DIR/test_summary.txt"

    print_status "$CYAN" "Generating test summary..."

    {
        echo "ZED SDK Installation Test Summary"
        echo "Generated: $(date)"
        echo "========================================"
        echo ""

        echo "TEST EXECUTION RESULTS:"
        echo "$(printf '=%.0s' {1..30})"

        for platform in "${PLATFORMS[@]}"; do
            echo ""
            echo "Platform: $platform"
            echo "$(printf '-%.0s' {1..20})"

            for method in "${INSTALL_METHODS[@]}"; do
                local result_file="$RESULTS_DIR/${platform}_${method}_results.txt"
                if [ -f "$result_file" ]; then
                    local status="✓ COMPLETED"
                    local errors=$(grep -c "ERROR:" "$result_file" 2>/dev/null || echo "0")
                    local warnings=$(grep -c "WARNING:" "$result_file" 2>/dev/null || echo "0")

                    echo "  $method: $status ($errors errors, $warnings warnings)"
                else
                    echo "  $method: ✗ FAILED (no results)"
                fi
            done

            # Show comparison status
            local comparison_file="$RESULTS_DIR/${platform}_comparison.txt"
            if [ -f "$comparison_file" ]; then
                if grep -q "No major differences detected" "$comparison_file"; then
                    echo "  Comparison: ✓ EQUIVALENT"
                else
                    echo "  Comparison: ⚠ DIFFERENCES FOUND"
                fi
            else
                echo "  Comparison: ✗ NOT AVAILABLE"
            fi
        done

        echo ""
        echo ""
        echo "RESULT FILES:"
        echo "$(printf '=%.0s' {1..30})"
        ls -la "$RESULTS_DIR"

    } > "$summary_file"

    print_status "$GREEN" "Test summary saved to: $summary_file"

    # Display summary
    echo ""
    print_status "$BLUE" "TEST SUMMARY:"
    print_status "$BLUE" "$(printf '=%.0s' {1..50})"
    cat "$summary_file"
}

# Function to show usage
show_usage() {
    echo "ZED SDK Installation Comparison Test Runner"
    echo ""
    echo "Usage: $0 [OPTIONS] [PLATFORMS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -c, --clean         Clean previous results before running"
    echo "  -r, --results       Show existing results without running tests"
    echo "  -v, --verbose       Enable verbose output"
    echo ""
    echo "Platforms (default: all):"
    echo "  amd64               Test AMD64 images only"
    echo "  arm64               Test ARM64 images only"
    echo ""
    echo "Examples:"
    echo "  $0                  Run all comparison tests"
    echo "  $0 amd64            Test AMD64 platform only"
    echo "  $0 --clean          Clean and run all tests"
    echo "  $0 --results        Show existing results"
    echo ""
}

# Function to clean previous results
clean_results() {
    print_status "$YELLOW" "Cleaning previous test results..."
    rm -rf "$RESULTS_DIR"/*
    print_status "$GREEN" "Results cleaned"
}

# Function to show existing results
show_results() {
    if [ ! -d "$RESULTS_DIR" ] || [ -z "$(ls -A "$RESULTS_DIR" 2>/dev/null)" ]; then
        print_status "$YELLOW" "No existing results found"
        return 1
    fi

    print_status "$BLUE" "Existing test results:"
    print_status "$BLUE" "$(printf '=%.0s' {1..50})"

    ls -la "$RESULTS_DIR"

    local summary_file="$RESULTS_DIR/test_summary.txt"
    if [ -f "$summary_file" ]; then
        echo ""
        print_status "$CYAN" "Latest test summary:"
        cat "$summary_file"
    fi
}

# Parse command line arguments
CLEAN=false
RESULTS_ONLY=false
VERBOSE=false
SELECTED_PLATFORMS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -r|--results)
            RESULTS_ONLY=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        amd64|arm64)
            SELECTED_PLATFORMS+=("$1")
            shift
            ;;
        *)
            print_status "$RED" "ERROR: Unknown option $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_status "$BLUE" "ZED SDK Installation Comparison Test Runner"
    print_status "$BLUE" "$(printf '=%.0s' {1..50})"

    # Handle results-only mode
    if [ "$RESULTS_ONLY" = true ]; then
        show_results
        exit 0
    fi

    # Check prerequisites
    check_docker
    check_test_images

    # Clean results if requested
    if [ "$CLEAN" = true ]; then
        clean_results
        echo
    fi

    # Use selected platforms or all platforms
    local test_platforms=("${SELECTED_PLATFORMS[@]}")
    if [ ${#test_platforms[@]} -eq 0 ]; then
        test_platforms=("${PLATFORMS[@]}")
    fi

    print_status "$BLUE" "Testing platforms: ${test_platforms[*]}"
    print_status "$BLUE" "Install methods: ${INSTALL_METHODS[*]}"
    print_status "$CYAN" "Results will be saved to: $RESULTS_DIR"
    echo

    # Run tests
    local total_success=0
    local total_tests=0
    local test_start_time=$(date +%s)

    for platform in "${test_platforms[@]}"; do
        if run_platform_tests "$platform"; then
            local platform_success=$?
            total_success=$((total_success + platform_success))
        fi
        total_tests=$((total_tests + ${#INSTALL_METHODS[@]}))

        # Generate platform comparison
        compare_platform_results "$platform"
        echo
    done

    local test_end_time=$(date +%s)
    local total_test_time=$((test_end_time - test_start_time))

    # Generate summary
    generate_summary_report

    # Final status
    echo
    print_status "$BLUE" "Test Execution Complete!"
    print_status "$BLUE" "$(printf '=%.0s' {1..50})"
    print_status "$GREEN" "Tests completed: $total_success/$total_tests"
    print_status "$CYAN" "Total test time: ${total_test_time}s"
    print_status "$CYAN" "Results directory: $RESULTS_DIR"

    if [ $total_success -eq $total_tests ]; then
        print_status "$GREEN" "All tests completed successfully!"
    else
        local failed=$((total_tests - total_success))
        print_status "$YELLOW" "$failed test(s) failed - check results for details"
    fi
}

# Execute main function
main "$@"