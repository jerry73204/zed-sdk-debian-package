#!/bin/bash
# Docker build script for ZED SDK 4.2 AMD64

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PACKAGE_DIR/output"

# Docker image settings
IMAGE_NAME="zed-sdk-build-amd64"
IMAGE_TAG="4.2-ubuntu22.04"

# Get host user UID and GID
HOST_UID=$(id -u)
HOST_GID=$(id -g)
HOST_USER=$(id -un)
HOST_GROUP=$(id -gn)

echo "=========================================="
echo "ZED SDK 4.2 AMD64 Docker Build"
echo "=========================================="
echo "Package dir: $PACKAGE_DIR"
echo "Output dir:  $OUTPUT_DIR"
echo "Host user:   $HOST_USER ($HOST_UID:$HOST_GID)"
echo "=========================================="

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Build Docker image if it doesn't exist
if ! docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" >/dev/null 2>&1; then
    echo ""
    echo "Building Docker image ${IMAGE_NAME}:${IMAGE_TAG}..."
    docker build \
        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
        -f "$SCRIPT_DIR/Dockerfile.build" \
        "$SCRIPT_DIR"
    echo "Docker image built successfully"
else
    echo "Docker image ${IMAGE_NAME}:${IMAGE_TAG} already exists"
fi

echo ""

# Check if interactive mode requested
if [ "$1" = "--interactive" ] || [ "$1" = "-i" ]; then
    echo "Starting interactive shell..."
    echo "Build the package with: /build/package/docker/build-in-docker.sh"
    echo ""
    docker run --rm -it \
        --user "${HOST_UID}:${HOST_GID}" \
        -e HOME=/tmp \
        -v "${PACKAGE_DIR}:/build/package" \
        -v "${OUTPUT_DIR}:/build/output" \
        "${IMAGE_NAME}:${IMAGE_TAG}" \
        /bin/bash
else
    echo "Running build in Docker container..."
    echo ""
    docker run --rm \
        --user "${HOST_UID}:${HOST_GID}" \
        -e HOME=/tmp \
        -v "${PACKAGE_DIR}:/build/package" \
        -v "${OUTPUT_DIR}:/build/output" \
        "${IMAGE_NAME}:${IMAGE_TAG}" \
        /build/package/docker/build-in-docker.sh
fi
