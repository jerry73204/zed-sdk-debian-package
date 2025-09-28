#!/bin/bash
# ZED SDK Test Images Builder
# Builds Docker images for comparison testing between .run and .deb installations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TESTS_DIR="$PROJECT_ROOT/tests"
DOCKER_DIR="$TESTS_DIR/docker"

# Image naming
IMAGE_PREFIX="zed-sdk-test"
TAG="latest"

# Available platforms
PLATFORMS=("amd64" "arm64")
INSTALL_METHODS=("runfile" "deb")

# Function to print colored output
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}[$(date '+%H:%M:%S')] $message${NC}"
}

# Function to check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_status "$RED" "ERROR: Docker is not installed or not in PATH"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_status "$RED" "ERROR: Docker daemon is not running or not accessible"
        exit 1
    fi

    print_status "$GREEN" "Docker is available and running"
}

# Function to check if .deb packages exist
check_deb_packages() {
    local missing_packages=()

    for platform in "${PLATFORMS[@]}"; do
        local deb_file="$PROJECT_ROOT/$platform/zed-sdk_5.0.5-1_$platform.deb"
        if [ ! -f "$deb_file" ]; then
            missing_packages+=("$platform")
        fi
    done

    if [ ${#missing_packages[@]} -ne 0 ]; then
        print_status "$YELLOW" "WARNING: Missing .deb packages for platforms: ${missing_packages[*]}"
        print_status "$YELLOW" "Run 'make build' in the respective platform directories first"

        # Ask user if they want to continue with available packages
        read -p "Continue building images for available packages? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "$RED" "Build cancelled by user"
            exit 1
        fi
    else
        print_status "$GREEN" "All required .deb packages found"
    fi
}

# Function to build a single Docker image
build_image() {
    local platform="$1"
    local method="$2"
    local dockerfile="Dockerfile.$method"
    local image_name="$IMAGE_PREFIX-$platform-$method:$TAG"
    local context_dir="$DOCKER_DIR/$platform"

    print_status "$BLUE" "Building $image_name..."

    # Check if Dockerfile exists
    if [ ! -f "$context_dir/$dockerfile" ]; then
        print_status "$RED" "ERROR: $dockerfile not found in $context_dir"
        return 1
    fi

    # For deb images, check if .deb package exists
    if [ "$method" = "deb" ]; then
        local deb_file="$PROJECT_ROOT/$platform/zed-sdk_5.0.5-1_$platform.deb"
        if [ ! -f "$deb_file" ]; then
            print_status "$YELLOW" "SKIP: .deb package not found for $platform"
            return 0
        fi
    fi

    # Build the image
    local build_start=$(date +%s)

    if docker build \
        -f "$context_dir/$dockerfile" \
        -t "$image_name" \
        "$context_dir" \
        --build-arg BUILDKIT_INLINE_CACHE=1; then

        local build_end=$(date +%s)
        local build_time=$((build_end - build_start))
        print_status "$GREEN" "Successfully built $image_name (${build_time}s)"

        # Get image size
        local image_size=$(docker images "$image_name" --format "table {{.Size}}" | tail -n 1)
        print_status "$CYAN" "Image size: $image_size"

        return 0
    else
        print_status "$RED" "FAILED to build $image_name"
        return 1
    fi
}

# Function to build images for a specific platform
build_platform_images() {
    local platform="$1"
    local success_count=0
    local total_count=${#INSTALL_METHODS[@]}

    print_status "$BLUE" "Building images for platform: $platform"
    print_status "$BLUE" "$(printf '=%.0s' {1..50})"

    for method in "${INSTALL_METHODS[@]}"; do
        if build_image "$platform" "$method"; then
            ((success_count++))
        fi
    done

    print_status "$BLUE" "Platform $platform: $success_count/$total_count images built successfully"
    echo
}

# Function to list built images
list_images() {
    print_status "$BLUE" "Built ZED SDK test images:"
    print_status "$BLUE" "$(printf '=%.0s' {1..50})"

    docker images --filter "reference=$IMAGE_PREFIX-*" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}"
    echo
}

# Function to show usage
show_usage() {
    echo "ZED SDK Test Images Builder"
    echo ""
    echo "Usage: $0 [OPTIONS] [PLATFORMS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -c, --clean         Remove existing test images before building"
    echo "  -l, --list          List existing test images"
    echo "  --no-cache          Build images without using Docker cache"
    echo ""
    echo "Platforms (default: all):"
    echo "  amd64               Build AMD64 images only"
    echo "  arm64               Build ARM64 images only"
    echo ""
    echo "Examples:"
    echo "  $0                  Build all images"
    echo "  $0 amd64            Build AMD64 images only"
    echo "  $0 --clean          Clean and build all images"
    echo "  $0 --list           List existing images"
    echo ""
}

# Function to clean existing images
clean_images() {
    print_status "$YELLOW" "Removing existing ZED SDK test images..."

    local images=$(docker images --filter "reference=$IMAGE_PREFIX-*" -q)
    if [ -n "$images" ]; then
        docker rmi $images || true
        print_status "$GREEN" "Existing images removed"
    else
        print_status "$YELLOW" "No existing images found"
    fi
}

# Parse command line arguments
CLEAN=false
LIST_ONLY=false
NO_CACHE=false
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
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        --no-cache)
            NO_CACHE=true
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
    print_status "$BLUE" "ZED SDK Test Images Builder"
    print_status "$BLUE" "$(printf '=%.0s' {1..50})"

    # Handle list-only mode
    if [ "$LIST_ONLY" = true ]; then
        list_images
        exit 0
    fi

    # Check prerequisites
    check_docker

    # Clean existing images if requested
    if [ "$CLEAN" = true ]; then
        clean_images
        echo
    fi

    # Use selected platforms or all platforms
    local build_platforms=("${SELECTED_PLATFORMS[@]}")
    if [ ${#build_platforms[@]} -eq 0 ]; then
        build_platforms=("${PLATFORMS[@]}")
    fi

    print_status "$BLUE" "Building images for platforms: ${build_platforms[*]}"
    print_status "$BLUE" "Install methods: ${INSTALL_METHODS[*]}"
    echo

    # Check for .deb packages
    check_deb_packages
    echo

    # Build images
    local total_success=0
    local total_attempts=0
    local build_start_time=$(date +%s)

    for platform in "${build_platforms[@]}"; do
        build_platform_images "$platform"

        # Count successes
        for method in "${INSTALL_METHODS[@]}"; do
            local image_name="$IMAGE_PREFIX-$platform-$method:$TAG"
            if docker images "$image_name" --format "{{.Repository}}" | grep -q "$IMAGE_PREFIX-$platform-$method"; then
                ((total_success++))
            fi
            ((total_attempts++))
        done
    done

    local build_end_time=$(date +%s)
    local total_build_time=$((build_end_time - build_start_time))

    # Summary
    print_status "$BLUE" "Build Summary:"
    print_status "$BLUE" "$(printf '=%.0s' {1..50})"
    print_status "$GREEN" "Successfully built: $total_success/$total_attempts images"
    print_status "$CYAN" "Total build time: ${total_build_time}s"
    echo

    # List built images
    list_images

    if [ $total_success -gt 0 ]; then
        print_status "$GREEN" "Images are ready for testing!"
        print_status "$CYAN" "Run './scripts/run-comparison.sh' to start testing"
    else
        print_status "$RED" "No images were built successfully"
        exit 1
    fi
}

# Execute main function
main "$@"