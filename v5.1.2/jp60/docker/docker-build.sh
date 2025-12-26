#!/bin/bash
# Build the Docker image and run the package build

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"
VERSION_DIR="$(dirname "$PACKAGE_DIR")"
REPO_ROOT="$(dirname "$VERSION_DIR")"

IMAGE_NAME="zed-sdk-jp60-builder"
IMAGE_TAG="5.1.2"
OUTPUT_DIR="${PACKAGE_DIR}/output"

# Get host user UID and GID
HOST_UID=$(id -u)
HOST_GID=$(id -g)
HOST_USER=$(id -un)
HOST_GROUP=$(id -gn)

echo "=========================================="
echo "ZED SDK JP60 Docker Build System"
echo "=========================================="
echo "Package directory: $PACKAGE_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Host user: ${HOST_USER}:${HOST_GROUP} (${HOST_UID}:${HOST_GID})"
echo "=========================================="

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Parse arguments
BUILD_IMAGE=true
RUN_BUILD=true
INTERACTIVE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-image-build)
            BUILD_IMAGE=false
            shift
            ;;
        --build-only)
            RUN_BUILD=false
            shift
            ;;
        --interactive|-i)
            INTERACTIVE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-image-build    Skip Docker image build (use existing image)"
            echo "  --build-only          Only build Docker image, don't run build"
            echo "  --interactive, -i     Run interactive shell instead of build"
            echo "  --help, -h            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                           # Build image and package"
            echo "  $0 --skip-image-build        # Use existing image, build package"
            echo "  $0 -i                        # Run interactive shell in container"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Build Docker image if requested
if [ "$BUILD_IMAGE" = true ]; then
    echo ""
    echo "Building Docker image..."
    echo "This may take several minutes on first run..."
    echo ""

    docker build \
        -f "${SCRIPT_DIR}/Dockerfile.build" \
        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
        -t "${IMAGE_NAME}:latest" \
        "$SCRIPT_DIR"

    if [ $? -eq 0 ]; then
        echo ""
        echo "Docker image built successfully!"
    else
        echo ""
        echo "Failed to build Docker image!"
        exit 1
    fi
fi

# Run build in container if requested
if [ "$RUN_BUILD" = false ]; then
    echo ""
    echo "Docker image build complete. Skipping package build."
    exit 0
fi

# Interactive mode
if [ "$INTERACTIVE" = true ]; then
    echo ""
    echo "Starting interactive shell in container..."
    echo "Build directory: /build/package"
    echo "Output directory: /build/output"
    echo ""

    docker run --rm -it \
        --platform linux/arm64 \
        --user "${HOST_UID}:${HOST_GID}" \
        -e HOME=/tmp \
        -v "${PACKAGE_DIR}:/build/package" \
        -v "${OUTPUT_DIR}:/build/output" \
        -w /build/package \
        "${IMAGE_NAME}:${IMAGE_TAG}" \
        /bin/bash

    exit 0
fi

# Run the build
echo ""
echo "Running package build in container..."
echo ""

docker run --rm \
    --platform linux/arm64 \
    --user "${HOST_UID}:${HOST_GID}" \
    -e HOME=/tmp \
    -v "${PACKAGE_DIR}:/build/package" \
    -v "${OUTPUT_DIR}:/build/output" \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    /build/package/docker/build-in-docker.sh

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "Build completed successfully!"
    echo "=========================================="
    echo ""
    echo "Package location: ${OUTPUT_DIR}"
    echo ""
    ls -lh "${OUTPUT_DIR}"/*.deb 2>/dev/null || echo "No .deb files found in output"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "Build failed!"
    echo "=========================================="
    exit 1
fi
