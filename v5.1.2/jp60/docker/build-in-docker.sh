#!/bin/bash
# Build ZED SDK package inside Docker container (Jetson L4T environment)

set -e

echo "=========================================="
echo "ZED SDK JP60 Docker Build Script"
echo "=========================================="
echo "Version: 5.1.2"
echo "Platform: NVIDIA Jetson (L4T 36.3)"
echo "=========================================="

# Check if we're running inside the container
if [ ! -f "/.dockerenv" ] && [ ! -f "/run/.containerenv" ]; then
    echo "Warning: This script is designed to run inside the Docker container"
    echo "Are you sure you want to continue? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Navigate to the mounted build directory
cd /build/package

# Display current directory and files
echo ""
echo "Current directory: $(pwd)"
echo "Files available:"
ls -la

# Clean previous build artifacts
echo ""
echo "Cleaning previous build artifacts..."
make clean-all || true

# Build the package using debhelper/dpkg-buildpackage
echo ""
echo "Building ZED SDK package with debhelper..."
echo "This will download the SDK and Python wheel (~2GB total)"
echo ""

dpkg-buildpackage -us -uc -b

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "Build completed successfully!"
    echo "=========================================="

    # List generated packages (debhelper puts them in parent directory)
    echo ""
    echo "Generated package(s):"
    ls -lh ../*.deb 2>/dev/null || echo "No .deb files found"

    # Move packages to current directory for easier access
    mv ../*.deb . 2>/dev/null || true

    # Copy to output directory if it exists
    if [ -d "/build/output" ]; then
        echo ""
        echo "Copying package to /build/output..."
        cp -v *.deb /build/output/ 2>/dev/null || true

        # Also copy build logs if they exist
        cp -v *.log /build/output/ 2>/dev/null || true
        cp -v *.buildinfo /build/output/ 2>/dev/null || true
        cp -v *.changes /build/output/ 2>/dev/null || true
    fi

    echo ""
    echo "Package information:"
    dpkg-deb --info *.deb 2>/dev/null | head -20 || true

    echo ""
    echo "=========================================="
    echo "Build process completed!"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "Build failed!"
    echo "=========================================="
    exit 1
fi
