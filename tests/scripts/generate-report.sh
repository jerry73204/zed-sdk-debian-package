#!/bin/bash
# ZED SDK Test Report Generator
# Generates detailed difference reports and analysis from test results

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
REPORTS_DIR="$TESTS_DIR/reports"

# Available platforms
PLATFORMS=("amd64" "arm64")

# Create reports directory
mkdir -p "$REPORTS_DIR"

# Function to print colored output
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}[$(date '+%H:%M:%S')] $message${NC}"
}

# Function to check if test results exist
check_results() {
    if [ ! -d "$RESULTS_DIR" ] || [ -z "$(ls -A "$RESULTS_DIR" 2>/dev/null)" ]; then
        print_status "$RED" "ERROR: No test results found in $RESULTS_DIR"
        print_status "$YELLOW" "Run './scripts/run-comparison.sh' first"
        exit 1
    fi

    print_status "$GREEN" "Test results found in $RESULTS_DIR"
}

# Function to extract file manifests from containers
extract_manifests() {
    local platform="$1"
    print_status "$BLUE" "Extracting file manifests for $platform..."

    local runfile_manifest="$REPORTS_DIR/${platform}_runfile_manifest.txt"
    local deb_manifest="$REPORTS_DIR/${platform}_deb_manifest.txt"

    # Extract manifests from running containers or saved files
    for method in "runfile" "deb"; do
        local image_name="zed-sdk-test-$platform-$method:latest"
        local manifest_file="$REPORTS_DIR/${platform}_${method}_manifest.txt"

        # Try to get manifest from saved results first
        local saved_manifest="$RESULTS_DIR/${platform}_${method}_manifest.txt"
        if [ -f "$saved_manifest" ]; then
            cp "$saved_manifest" "$manifest_file"
            print_status "$GREEN" "Using saved manifest for $platform $method"
        else
            # Extract from container if needed
            if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$image_name$"; then
                docker run --rm "$image_name" cat /tmp/zed_manifest.txt > "$manifest_file" 2>/dev/null || {
                    print_status "$YELLOW" "Could not extract manifest from $image_name"
                    echo "Manifest not available" > "$manifest_file"
                }
            else
                print_status "$YELLOW" "Image $image_name not found"
                echo "Image not available" > "$manifest_file"
            fi
        fi
    done
}

# Function to generate detailed file comparison
generate_file_diff() {
    local platform="$1"
    local runfile_manifest="$REPORTS_DIR/${platform}_runfile_manifest.txt"
    local deb_manifest="$REPORTS_DIR/${platform}_deb_manifest.txt"
    local diff_report="$REPORTS_DIR/${platform}_file_diff.txt"

    print_status "$BLUE" "Generating file difference report for $platform..."

    if [ -f "$runfile_manifest" ] && [ -f "$deb_manifest" ]; then
        {
            echo "ZED SDK File Difference Report - $platform"
            echo "Generated: $(date)"
            echo "=============================================="
            echo ""

            echo "SIDE-BY-SIDE COMPARISON:"
            echo "$(printf '=%.0s' {1..50})"
            echo ""

            # Extract file lists (excluding the manifest headers)
            local runfile_files=$(mktemp)
            local deb_files=$(mktemp)

            # Extract actual file listings
            sed -n '/=== \/usr\/local\/zed ===/,/=== /p' "$runfile_manifest" | head -n -1 | tail -n +2 > "$runfile_files" || true
            sed -n '/=== \/usr\/local\/zed ===/,/=== /p' "$deb_manifest" | head -n -1 | tail -n +2 > "$deb_files" || true

            # Generate unified diff
            echo "UNIFIED DIFF (- runfile, + deb):"
            echo "$(printf '=%.0s' {1..40})"
            if diff -u "$runfile_files" "$deb_files" || true; then
                echo "(No differences in core file listings)"
            fi
            echo ""

            # Count files
            local runfile_count=$(wc -l < "$runfile_files" 2>/dev/null || echo "0")
            local deb_count=$(wc -l < "$deb_files" 2>/dev/null || echo "0")

            echo "FILE COUNT COMPARISON:"
            echo "$(printf '=%.0s' {1..30})"
            echo "Runfile installation: $runfile_count files"
            echo "Deb installation:     $deb_count files"

            if [ "$runfile_count" -eq "$deb_count" ]; then
                echo "Status: ✓ EQUAL file counts"
            else
                local diff_count=$((deb_count - runfile_count))
                if [ $diff_count -gt 0 ]; then
                    echo "Status: ⚠ Deb has $diff_count more files"
                else
                    echo "Status: ⚠ Runfile has $((-diff_count)) more files"
                fi
            fi
            echo ""

            # Analyze specific file types
            echo "FILE TYPE ANALYSIS:"
            echo "$(printf '=%.0s' {1..30})"

            for ext in "so" "so.*" "a" "h" "hpp" "py" "pyc"; do
                local runfile_ext_count=$(grep -c "\.$ext" "$runfile_files" 2>/dev/null || echo "0")
                local deb_ext_count=$(grep -c "\.$ext" "$deb_files" 2>/dev/null || echo "0")

                if [ "$runfile_ext_count" -ne 0 ] || [ "$deb_ext_count" -ne 0 ]; then
                    printf "%-10s: runfile=%3d, deb=%3d" "$ext" "$runfile_ext_count" "$deb_ext_count"
                    if [ "$runfile_ext_count" -eq "$deb_ext_count" ]; then
                        echo " ✓"
                    else
                        echo " ⚠"
                    fi
                fi
            done
            echo ""

            # Check for common critical files
            echo "CRITICAL FILE CHECK:"
            echo "$(printf '=%.0s' {1..30})"

            local critical_files=(
                "libsl_zed.so"
                "ZED_Diagnostic"
                "zed-config.cmake"
                "99-slabs.rules"
            )

            for file in "${critical_files[@]}"; do
                local in_runfile=$(grep -q "$file" "$runfile_files" && echo "✓" || echo "✗")
                local in_deb=$(grep -q "$file" "$deb_files" && echo "✓" || echo "✗")

                printf "%-20s: runfile=%s, deb=%s" "$file" "$in_runfile" "$in_deb"

                if [ "$in_runfile" = "$in_deb" ]; then
                    echo " ✓"
                else
                    echo " ⚠"
                fi
            done

            # Cleanup temp files
            rm -f "$runfile_files" "$deb_files"

        } > "$diff_report"

        print_status "$GREEN" "File difference report saved to: $diff_report"
    else
        print_status "$YELLOW" "Cannot generate file diff - missing manifests for $platform"
    fi
}

# Function to analyze Python package differences
analyze_python_packages() {
    local platform="$1"
    local python_report="$REPORTS_DIR/${platform}_python_analysis.txt"

    print_status "$BLUE" "Analyzing Python packages for $platform..."

    {
        echo "ZED SDK Python Package Analysis - $platform"
        echo "Generated: $(date)"
        echo "============================================"
        echo ""

        # Extract Python package info from test results
        local runfile_results="$RESULTS_DIR/${platform}_runfile_results.txt"
        local deb_results="$RESULTS_DIR/${platform}_deb_results.txt"

        if [ -f "$runfile_results" ] && [ -f "$deb_results" ]; then
            echo "PYTHON IMPORT TEST RESULTS:"
            echo "$(printf '=%.0s' {1..40})"

            echo "Runfile installation:"
            grep -A 5 -B 5 "pyzed" "$runfile_results" | head -10
            echo ""

            echo "Deb installation:"
            grep -A 5 -B 5 "pyzed" "$deb_results" | head -10
            echo ""

            # Compare Python package locations
            echo "PACKAGE LOCATION COMPARISON:"
            echo "$(printf '=%.0s' {1..40})"

            local runfile_location=$(grep "Location:" "$runfile_results" | head -1 || echo "Not found")
            local deb_location=$(grep "Location:" "$deb_results" | head -1 || echo "Not found")

            echo "Runfile: $runfile_location"
            echo "Deb:     $deb_location"

            if [ "$runfile_location" = "$deb_location" ]; then
                echo "Status:  ✓ SAME location"
            else
                echo "Status:  ⚠ DIFFERENT locations"
            fi
            echo ""

            # Compare import success
            echo "IMPORT SUCCESS COMPARISON:"
            echo "$(printf '=%.0s' {1..40})"

            local runfile_import=$(grep -c "pyzed module imports successfully" "$runfile_results" 2>/dev/null || echo "0")
            local deb_import=$(grep -c "pyzed module imports successfully" "$deb_results" 2>/dev/null || echo "0")

            echo "Runfile import: $([ "$runfile_import" -gt 0 ] && echo "✓ SUCCESS" || echo "✗ FAILED")"
            echo "Deb import:     $([ "$deb_import" -gt 0 ] && echo "✓ SUCCESS" || echo "✗ FAILED")"

            if [ "$runfile_import" -eq "$deb_import" ]; then
                echo "Status:         ✓ CONSISTENT"
            else
                echo "Status:         ⚠ INCONSISTENT"
            fi

        else
            echo "ERROR: Missing test result files for Python analysis"
        fi

    } > "$python_report"

    print_status "$GREEN" "Python analysis saved to: $python_report"
}

# Function to analyze system configuration differences
analyze_system_config() {
    local platform="$1"
    local config_report="$REPORTS_DIR/${platform}_system_config.txt"

    print_status "$BLUE" "Analyzing system configuration for $platform..."

    {
        echo "ZED SDK System Configuration Analysis - $platform"
        echo "Generated: $(date)"
        echo "================================================"
        echo ""

        local runfile_results="$RESULTS_DIR/${platform}_runfile_results.txt"
        local deb_results="$RESULTS_DIR/${platform}_deb_results.txt"

        if [ -f "$runfile_results" ] && [ -f "$deb_results" ]; then

            # Compare group creation
            echo "GROUP CONFIGURATION:"
            echo "$(printf '=%.0s' {1..30})"

            local runfile_group=$(grep -c "zed group exists" "$runfile_results" 2>/dev/null || echo "0")
            local deb_group=$(grep -c "zed group exists" "$deb_results" 2>/dev/null || echo "0")

            echo "Runfile: $([ "$runfile_group" -gt 0 ] && echo "✓ zed group" || echo "✗ no group")"
            echo "Deb:     $([ "$deb_group" -gt 0 ] && echo "✓ zed group" || echo "✗ no group")"
            echo ""

            # Compare udev rules
            echo "UDEV RULES:"
            echo "$(printf '=%.0s' {1..30})"

            local runfile_udev=$(grep -c "ZED udev rules found" "$runfile_results" 2>/dev/null || echo "0")
            local deb_udev=$(grep -c "ZED udev rules found" "$deb_results" 2>/dev/null || echo "0")

            echo "Runfile: $([ "$runfile_udev" -gt 0 ] && echo "✓ udev rules" || echo "✗ no rules")"
            echo "Deb:     $([ "$deb_udev" -gt 0 ] && echo "✓ udev rules" || echo "✗ no rules")"
            echo ""

            # Compare library configuration
            echo "LIBRARY CONFIGURATION:"
            echo "$(printf '=%.0s' {1..30})"

            local runfile_ldconf=$(grep -c "ZED library configuration found" "$runfile_results" 2>/dev/null || echo "0")
            local deb_ldconf=$(grep -c "ZED library configuration found" "$deb_results" 2>/dev/null || echo "0")

            echo "Runfile: $([ "$runfile_ldconf" -gt 0 ] && echo "✓ ld.so.conf.d" || echo "✗ no config")"
            echo "Deb:     $([ "$deb_ldconf" -gt 0 ] && echo "✓ ld.so.conf.d" || echo "✗ no config")"
            echo ""

            # Compare library cache
            echo "LDCONFIG CACHE:"
            echo "$(printf '=%.0s' {1..30})"

            local runfile_libs=$(grep "ZED libraries in ldconfig cache" "$runfile_results" | grep -o '[0-9]*' | head -1 || echo "0")
            local deb_libs=$(grep "ZED libraries in ldconfig cache" "$deb_results" | grep -o '[0-9]*' | head -1 || echo "0")

            echo "Runfile: $runfile_libs libraries in cache"
            echo "Deb:     $deb_libs libraries in cache"

            if [ "$runfile_libs" -eq "$deb_libs" ]; then
                echo "Status:  ✓ SAME library count"
            else
                echo "Status:  ⚠ DIFFERENT library counts"
            fi
            echo ""

            # Overall system config assessment
            echo "SYSTEM CONFIG ASSESSMENT:"
            echo "$(printf '=%.0s' {1..40})"

            local config_issues=0

            if [ "$runfile_group" != "$deb_group" ]; then
                ((config_issues++))
                echo "⚠ Group configuration differs"
            fi

            if [ "$runfile_udev" != "$deb_udev" ]; then
                ((config_issues++))
                echo "⚠ Udev rules differ"
            fi

            if [ "$runfile_ldconf" != "$deb_ldconf" ]; then
                ((config_issues++))
                echo "⚠ Library configuration differs"
            fi

            if [ "$runfile_libs" != "$deb_libs" ]; then
                ((config_issues++))
                echo "⚠ Library cache differs"
            fi

            if [ $config_issues -eq 0 ]; then
                echo "✓ System configurations are equivalent"
            else
                echo "✗ $config_issues configuration difference(s) found"
            fi

        else
            echo "ERROR: Missing test result files for system config analysis"
        fi

    } > "$config_report"

    print_status "$GREEN" "System config analysis saved to: $config_report"
}

# Function to generate comprehensive final report
generate_final_report() {
    local final_report="$REPORTS_DIR/comprehensive_analysis.txt"

    print_status "$CYAN" "Generating comprehensive analysis report..."

    {
        echo "ZED SDK Installation Comparison - Comprehensive Analysis"
        echo "Generated: $(date)"
        echo "========================================================"
        echo ""

        echo "EXECUTIVE SUMMARY:"
        echo "$(printf '=%.0s' {1..30})"
        echo ""

        local total_platforms=0
        local equivalent_platforms=0

        for platform in "${PLATFORMS[@]}"; do
            if [ -f "$RESULTS_DIR/${platform}_runfile_results.txt" ] && [ -f "$RESULTS_DIR/${platform}_deb_results.txt" ]; then
                ((total_platforms++))

                echo "Platform: $platform"
                echo "$(printf '-%.0s' {1..20})"

                # Check if platform passed all major tests
                local platform_issues=0

                # Check file comparison
                local comparison_file="$RESULTS_DIR/${platform}_comparison.txt"
                if [ -f "$comparison_file" ]; then
                    if grep -q "No major differences detected" "$comparison_file"; then
                        echo "  Files:          ✓ Equivalent"
                    else
                        echo "  Files:          ⚠ Differences found"
                        ((platform_issues++))
                    fi
                else
                    echo "  Files:          ✗ Not analyzed"
                    ((platform_issues++))
                fi

                # Check Python package
                local runfile_python=$(grep -c "pyzed module imports successfully" "$RESULTS_DIR/${platform}_runfile_results.txt" 2>/dev/null || echo "0")
                local deb_python=$(grep -c "pyzed module imports successfully" "$RESULTS_DIR/${platform}_deb_results.txt" 2>/dev/null || echo "0")

                if [ "$runfile_python" -eq "$deb_python" ] && [ "$runfile_python" -gt 0 ]; then
                    echo "  Python:         ✓ Equivalent"
                else
                    echo "  Python:         ⚠ Issues detected"
                    ((platform_issues++))
                fi

                # Check system config
                local runfile_libs=$(grep "ZED libraries in ldconfig cache" "$RESULTS_DIR/${platform}_runfile_results.txt" | grep -o '[0-9]*' | head -1 || echo "0")
                local deb_libs=$(grep "ZED libraries in ldconfig cache" "$RESULTS_DIR/${platform}_deb_results.txt" | grep -o '[0-9]*' | head -1 || echo "0")

                if [ "$runfile_libs" -eq "$deb_libs" ] && [ "$runfile_libs" -gt 0 ]; then
                    echo "  System Config:  ✓ Equivalent"
                else
                    echo "  System Config:  ⚠ Issues detected"
                    ((platform_issues++))
                fi

                # Overall platform assessment
                if [ $platform_issues -eq 0 ]; then
                    echo "  Overall:        ✓ EQUIVALENT"
                    ((equivalent_platforms++))
                else
                    echo "  Overall:        ⚠ $platform_issues issue(s) found"
                fi

                echo ""
            fi
        done

        echo ""
        echo "FINAL ASSESSMENT:"
        echo "$(printf '=%.0s' {1..30})"

        if [ $equivalent_platforms -eq $total_platforms ] && [ $total_platforms -gt 0 ]; then
            echo "✓ SUCCESS: All tested platforms show equivalent installations"
            echo "✓ The .deb packages produce the same results as .run files"
            echo "✓ Ready for production use"
        elif [ $equivalent_platforms -gt 0 ]; then
            echo "⚠ PARTIAL SUCCESS: $equivalent_platforms/$total_platforms platforms equivalent"
            echo "⚠ Some differences detected - review individual reports"
            echo "⚠ Consider investigating differences before production use"
        else
            echo "✗ ISSUES DETECTED: Significant differences found"
            echo "✗ .deb packages may not be equivalent to .run files"
            echo "✗ Investigation and fixes required before production use"
        fi

        echo ""
        echo "DETAILED REPORTS AVAILABLE:"
        echo "$(printf '=%.0s' {1..40})"

        for platform in "${PLATFORMS[@]}"; do
            echo "Platform: $platform"
            echo "  - File diff:      $REPORTS_DIR/${platform}_file_diff.txt"
            echo "  - Python analysis: $REPORTS_DIR/${platform}_python_analysis.txt"
            echo "  - System config:  $REPORTS_DIR/${platform}_system_config.txt"
            echo ""
        done

        echo "Next Steps:"
        echo "$(printf '=%.0s' {1..20})"
        echo "1. Review detailed reports for any platform showing differences"
        echo "2. Investigate root causes of any detected differences"
        echo "3. Fix issues in PKGBUILD or installation scripts as needed"
        echo "4. Re-run tests after fixes to verify equivalence"
        echo "5. Document any acceptable/expected differences"

    } > "$final_report"

    print_status "$GREEN" "Comprehensive analysis saved to: $final_report"

    # Display summary
    echo ""
    print_status "$MAGENTA" "COMPREHENSIVE ANALYSIS COMPLETE"
    print_status "$MAGENTA" "$(printf '=%.0s' {1..50})"
    cat "$final_report"
}

# Function to show usage
show_usage() {
    echo "ZED SDK Test Report Generator"
    echo ""
    echo "Usage: $0 [OPTIONS] [PLATFORMS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -c, --clean         Clean previous reports before generating"
    echo "  -a, --all           Generate all types of reports"
    echo "  -f, --files         Generate file difference reports only"
    echo "  -p, --python        Generate Python analysis reports only"
    echo "  -s, --system        Generate system config reports only"
    echo ""
    echo "Platforms (default: all):"
    echo "  amd64               Generate reports for AMD64 only"
    echo "  arm64               Generate reports for ARM64 only"
    echo ""
    echo "Examples:"
    echo "  $0                  Generate all reports for all platforms"
    echo "  $0 -f amd64         Generate file diff report for AMD64 only"
    echo "  $0 --clean --all    Clean and generate all reports"
    echo ""
}

# Function to clean previous reports
clean_reports() {
    print_status "$YELLOW" "Cleaning previous reports..."
    rm -rf "$REPORTS_DIR"/*
    print_status "$GREEN" "Reports cleaned"
}

# Parse command line arguments
CLEAN=false
GENERATE_ALL=true
GENERATE_FILES=false
GENERATE_PYTHON=false
GENERATE_SYSTEM=false
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
        -a|--all)
            GENERATE_ALL=true
            shift
            ;;
        -f|--files)
            GENERATE_ALL=false
            GENERATE_FILES=true
            shift
            ;;
        -p|--python)
            GENERATE_ALL=false
            GENERATE_PYTHON=true
            shift
            ;;
        -s|--system)
            GENERATE_ALL=false
            GENERATE_SYSTEM=true
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
    print_status "$BLUE" "ZED SDK Test Report Generator"
    print_status "$BLUE" "$(printf '=%.0s' {1..50})"

    # Check prerequisites
    check_results

    # Clean reports if requested
    if [ "$CLEAN" = true ]; then
        clean_reports
        echo
    fi

    # Use selected platforms or all platforms
    local report_platforms=("${SELECTED_PLATFORMS[@]}")
    if [ ${#report_platforms[@]} -eq 0 ]; then
        report_platforms=("${PLATFORMS[@]}")
    fi

    print_status "$BLUE" "Generating reports for platforms: ${report_platforms[*]}"
    print_status "$CYAN" "Reports will be saved to: $REPORTS_DIR"
    echo

    # Generate reports
    local report_start_time=$(date +%s)

    for platform in "${report_platforms[@]}"; do
        print_status "$MAGENTA" "Processing platform: $platform"
        print_status "$MAGENTA" "$(printf '=%.0s' {1..30})"

        # Extract manifests first
        extract_manifests "$platform"

        # Generate requested reports
        if [ "$GENERATE_ALL" = true ] || [ "$GENERATE_FILES" = true ]; then
            generate_file_diff "$platform"
        fi

        if [ "$GENERATE_ALL" = true ] || [ "$GENERATE_PYTHON" = true ]; then
            analyze_python_packages "$platform"
        fi

        if [ "$GENERATE_ALL" = true ] || [ "$GENERATE_SYSTEM" = true ]; then
            analyze_system_config "$platform"
        fi

        echo
    done

    # Generate comprehensive final report if generating all reports
    if [ "$GENERATE_ALL" = true ]; then
        generate_final_report
    fi

    local report_end_time=$(date +%s)
    local total_report_time=$((report_end_time - report_start_time))

    # Final status
    echo
    print_status "$BLUE" "Report Generation Complete!"
    print_status "$BLUE" "$(printf '=%.0s' {1..50})"
    print_status "$GREEN" "Total generation time: ${total_report_time}s"
    print_status "$CYAN" "Reports directory: $REPORTS_DIR"

    # List generated reports
    print_status "$CYAN" "Generated reports:"
    ls -la "$REPORTS_DIR"
}

# Execute main function
main "$@"