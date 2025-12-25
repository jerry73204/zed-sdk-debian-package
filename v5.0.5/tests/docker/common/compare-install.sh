#!/bin/bash
# ZED SDK Installation Comparison Script
# Compares .run file installation vs .deb package installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

COMPARISON_REPORT="/tmp/zed_comparison_report.txt"
DIFF_DETAILS="/tmp/zed_diff_details.txt"

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE} ZED SDK Installation Comparison Report${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# Initialize report
{
    echo "ZED SDK Installation Comparison Report"
    echo "Generated: $(date)"
    echo "Host: $(hostname)"
    echo "Architecture: $(dpkg --print-architecture 2>/dev/null || uname -m)"
    echo "======================================"
    echo ""
} > "$COMPARISON_REPORT"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to add section to report
add_section() {
    local title="$1"
    echo -e "${YELLOW}Testing: $title${NC}"
    echo "$title" >> "$COMPARISON_REPORT"
    echo "$(printf '=%.0s' {1..${#title}})" >> "$COMPARISON_REPORT"
    echo "" >> "$COMPARISON_REPORT"
}

# Function to add result to report
add_result() {
    local status="$1"
    local message="$2"
    local color="${3:-$NC}"

    echo -e "${color}$status: $message${NC}"
    echo "$status: $message" >> "$COMPARISON_REPORT"
}

# Function to compare directories
compare_directories() {
    local dir="$1"
    local label="$2"

    add_section "$label Directory Comparison"

    if [ -d "$dir" ]; then
        # List all files with details
        find "$dir" -type f -exec ls -la {} \; | sort > "/tmp/${label}_files.txt"
        find "$dir" -type l -exec ls -la {} \; | sort > "/tmp/${label}_links.txt"

        local file_count=$(find "$dir" -type f | wc -l)
        local link_count=$(find "$dir" -type l | wc -l)

        add_result "FOUND" "$file_count files, $link_count symlinks in $dir" "$GREEN"

        # Check for common ZED components
        local components=("lib" "include" "tools" "samples" "firmware")
        for comp in "${components[@]}"; do
            if [ -d "$dir/$comp" ]; then
                local comp_files=$(find "$dir/$comp" -type f | wc -l)
                add_result "COMPONENT" "$comp: $comp_files files" "$GREEN"
            else
                add_result "MISSING" "$comp directory not found" "$RED"
            fi
        done
    else
        add_result "ERROR" "Directory $dir not found" "$RED"
    fi

    echo "" >> "$COMPARISON_REPORT"
}

# Function to check Python package
check_python_package() {
    add_section "Python Package (pyzed) Check"

    # Check if pyzed is installed
    if python3 -c "import pyzed" 2>/dev/null; then
        add_result "SUCCESS" "pyzed module imports successfully" "$GREEN"

        # Get pyzed version and location
        local pyzed_info=$(python3 -c "import pyzed; print(f'Version: {pyzed.__version__ if hasattr(pyzed, \"__version__\") else \"unknown\"}, Location: {pyzed.__file__}')" 2>/dev/null || echo "Could not get pyzed info")
        add_result "INFO" "$pyzed_info"

        # List pyzed files
        local pyzed_path=$(python3 -c "import pyzed; import os; print(os.path.dirname(pyzed.__file__))" 2>/dev/null || echo "")
        if [ -n "$pyzed_path" ] && [ -d "$pyzed_path" ]; then
            local pyzed_files=$(find "$pyzed_path" -type f | wc -l)
            add_result "FILES" "pyzed has $pyzed_files files in $pyzed_path"
        fi
    else
        add_result "ERROR" "pyzed module cannot be imported" "$RED"
    fi

    echo "" >> "$COMPARISON_REPORT"
}

# Function to check system configuration
check_system_config() {
    add_section "System Configuration Check"

    # Check groups
    if getent group zed >/dev/null 2>&1; then
        add_result "SUCCESS" "zed group exists" "$GREEN"
    else
        add_result "WARNING" "zed group not found" "$YELLOW"
    fi

    # Check udev rules
    if [ -f "/etc/udev/rules.d/99-slabs.rules" ]; then
        add_result "SUCCESS" "ZED udev rules found" "$GREEN"
        local rules_lines=$(wc -l < "/etc/udev/rules.d/99-slabs.rules")
        add_result "INFO" "udev rules file has $rules_lines lines"
    else
        add_result "WARNING" "ZED udev rules not found" "$YELLOW"
    fi

    # Check ld.so.conf.d
    if [ -f "/etc/ld.so.conf.d/001-zed.conf" ]; then
        add_result "SUCCESS" "ZED library configuration found" "$GREEN"
        local lib_path=$(cat "/etc/ld.so.conf.d/001-zed.conf")
        add_result "INFO" "Library path: $lib_path"
    else
        add_result "WARNING" "ZED library configuration not found" "$YELLOW"
    fi

    # Check ldconfig cache
    if ldconfig -p | grep -q zed; then
        local zed_libs=$(ldconfig -p | grep zed | wc -l)
        add_result "SUCCESS" "$zed_libs ZED libraries in ldconfig cache" "$GREEN"
    else
        add_result "WARNING" "No ZED libraries found in ldconfig cache" "$YELLOW"
    fi

    echo "" >> "$COMPARISON_REPORT"
}

# Function to check tools and binaries
check_tools() {
    add_section "ZED Tools and Binaries Check"

    # Check for ZED tools in /usr/local/bin
    local tools_found=0
    local common_tools=("ZED_Diagnostic" "ZED_Depth_Viewer" "ZED_Explorer")

    for tool in "${common_tools[@]}"; do
        if command_exists "$tool"; then
            add_result "FOUND" "$tool available" "$GREEN"
            tools_found=$((tools_found + 1))
        elif [ -L "/usr/local/bin/$tool" ]; then
            add_result "SYMLINK" "$tool symlink exists" "$GREEN"
            tools_found=$((tools_found + 1))
        else
            add_result "MISSING" "$tool not found" "$YELLOW"
        fi
    done

    # Count all tools in /usr/local/bin with ZED prefix
    if [ -d "/usr/local/bin" ]; then
        local all_zed_tools=$(find /usr/local/bin -name "*ZED*" -o -name "*zed*" | wc -l)
        add_result "INFO" "Total ZED-related tools in /usr/local/bin: $all_zed_tools"
    fi

    # Check zed_ai_optimizer
    if command_exists "zed_ai_optimizer"; then
        add_result "SUCCESS" "zed_ai_optimizer available" "$GREEN"
    else
        add_result "WARNING" "zed_ai_optimizer not found" "$YELLOW"
    fi

    echo "" >> "$COMPARISON_REPORT"
}

# Function to test basic functionality
test_functionality() {
    add_section "Basic Functionality Tests"

    # Test ZED_Diagnostic if available (without requiring hardware)
    if command_exists "ZED_Diagnostic"; then
        add_result "AVAILABLE" "ZED_Diagnostic tool found" "$GREEN"
        # Note: We can't actually run it without ZED hardware in Docker
        add_result "INFO" "Hardware test skipped (no ZED camera in container)"
    else
        add_result "WARNING" "ZED_Diagnostic not available" "$YELLOW"
    fi

    # Test library loading
    if ldconfig -p | grep -q "libsl_zed"; then
        add_result "SUCCESS" "Core ZED library (libsl_zed) can be loaded" "$GREEN"
    else
        add_result "WARNING" "Core ZED library not found in loader cache" "$YELLOW"
    fi

    echo "" >> "$COMPARISON_REPORT"
}

# Function to generate file manifest
generate_manifest() {
    add_section "Installation Manifest"

    # Generate complete file listing
    echo "Generating complete file manifest..."
    {
        echo "Complete ZED SDK file manifest:"
        echo "Generated: $(date)"
        echo ""

        if [ -d "/usr/local/zed" ]; then
            echo "=== /usr/local/zed ==="
            find /usr/local/zed -type f -exec ls -la {} \; | sort
            echo ""
            echo "=== /usr/local/zed symlinks ==="
            find /usr/local/zed -type l -exec ls -la {} \; | sort
            echo ""
        fi

        if [ -d "/usr/local/bin" ]; then
            echo "=== ZED tools in /usr/local/bin ==="
            find /usr/local/bin -name "*zed*" -o -name "*ZED*" | xargs ls -la 2>/dev/null || echo "No ZED tools found"
            echo ""
        fi

        echo "=== System configuration files ==="
        ls -la /etc/udev/rules.d/*zed* /etc/udev/rules.d/*slabs* 2>/dev/null || echo "No ZED udev rules found"
        ls -la /etc/ld.so.conf.d/*zed* 2>/dev/null || echo "No ZED ld.so.conf.d files found"
        echo ""

        echo "=== Python packages ==="
        python3 -c "import pkg_resources; [print(f'{pkg.project_name}=={pkg.version} @ {pkg.location}') for pkg in pkg_resources.working_set if 'pyzed' in pkg.project_name.lower()]" 2>/dev/null || echo "No pyzed package found"

    } > "/tmp/zed_manifest.txt"

    add_result "GENERATED" "Complete manifest saved to /tmp/zed_manifest.txt"
    echo "" >> "$COMPARISON_REPORT"
}

# Main comparison execution
main() {
    echo "Starting ZED SDK installation comparison..."
    echo ""

    # Run all checks
    compare_directories "/usr/local/zed" "ZED_SDK"
    check_python_package
    check_system_config
    check_tools
    test_functionality
    generate_manifest

    # Final summary
    add_section "Comparison Summary"
    add_result "COMPLETED" "Installation comparison finished"
    add_result "REPORT" "Full report saved to $COMPARISON_REPORT"
    add_result "MANIFEST" "File manifest saved to /tmp/zed_manifest.txt"

    echo ""
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}Comparison completed. Check $COMPARISON_REPORT for details.${NC}"
    echo -e "${BLUE}======================================================${NC}"
}

# Execute main function
main "$@"