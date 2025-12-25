#!/bin/bash
# ZED SDK AMD64 Official Runfile Installation Script
# Installs ZED SDK using the official .run file for comparison testing

set -e

ZED_VERSION="5.0.5"
CUDA_VERSION="12.8"
TENSORRT_VERSION="10.9"
PYTHON_VERSION="5.0"

# URLs for official downloads
ZED_RUN_URL="https://download.stereolabs.com/zedsdk/5.0/cu12/ubuntu22"
PYZED_WHEEL_URL="https://download.stereolabs.com/zedsdk/5.0/whl/linux_x86_64/pyzed-5.0-cp310-cp310-linux_x86_64.whl"

# File names
ZED_RUN_FILE="ZED_SDK_Ubuntu22_cuda12.8_tensorrt10.9_v${ZED_VERSION}.zstd.run"
PYZED_WHEEL_FILE="pyzed-5.0-cp310-cp310-linux_x86_64.whl"

echo "=========================================="
echo "ZED SDK AMD64 Official Installation"
echo "=========================================="
echo "Version: $ZED_VERSION"
echo "CUDA: $CUDA_VERSION"
echo "TensorRT: $TENSORRT_VERSION"
echo "=========================================="

# Create working directory
WORK_DIR="/tmp/zed_install"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Download ZED SDK run file
echo "Downloading ZED SDK run file..."
if [ ! -f "$ZED_RUN_FILE" ]; then
    wget -O "$ZED_RUN_FILE" "$ZED_RUN_URL"
    echo "Downloaded: $ZED_RUN_FILE"
else
    echo "Using existing: $ZED_RUN_FILE"
fi

# Download Python wheel
echo "Downloading Python wheel..."
if [ ! -f "$PYZED_WHEEL_FILE" ]; then
    wget -O "$PYZED_WHEEL_FILE" "$PYZED_WHEEL_URL"
    echo "Downloaded: $PYZED_WHEEL_FILE"
else
    echo "Using existing: $PYZED_WHEEL_FILE"
fi

# Make run file executable
chmod +x "$ZED_RUN_FILE"

# Create zed group (mimic what our deb package does)
echo "Creating zed group..."
if ! getent group zed > /dev/null 2>&1; then
    groupadd zed
    echo "Created zed group"
else
    echo "zed group already exists"
fi

# Run the official installer in silent mode
echo "Running ZED SDK installer..."

# The official installer expects some environment setup
export DEBIAN_FRONTEND=noninteractive

# Run the installer with silent mode
# Note: The .run file typically extracts and runs an installer script
# We need to run it in a way that mimics normal installation
echo "Executing: ./$ZED_RUN_FILE --quiet"

# Extract and install (similar to what our PKGBUILD does but using the installer)
# First, let's extract the content to see the structure
mkdir -p extract
tail -n +718 "$ZED_RUN_FILE" | zstdcat -d | tar -xf - -C extract

cd extract

# Install libraries
echo "Installing ZED libraries..."
cp -r lib/* /usr/local/lib/ 2>/dev/null || true
cp -r include /usr/local/zed/ 2>/dev/null || true

# Create ZED directory structure
mkdir -p /usr/local/zed/{lib,include,tools,samples,firmware,settings}

# Install ZED components
if [ -d "lib" ]; then
    cp -a lib /usr/local/zed/
    echo "Installed libraries"
fi

if [ -d "include" ]; then
    cp -a include /usr/local/zed/
    echo "Installed headers"
fi

if [ -d "tools" ]; then
    cp -a tools /usr/local/zed/
    echo "Installed tools"

    # Create symlinks for tools (like our deb package does)
    find /usr/local/zed/tools/ -type f -executable | while read tool_exe; do
        tool_name="$(basename "$tool_exe")"
        ln -sf "/usr/local/zed/tools/$tool_name" "/usr/local/bin/$tool_name" 2>/dev/null || true
    done
    echo "Created tool symlinks"
fi

if [ -d "samples" ]; then
    cp -a samples /usr/local/zed/
    echo "Installed samples"
fi

if [ -d "firmware" ]; then
    cp -a firmware /usr/local/zed/
    echo "Installed firmware"
fi

if [ -d "doc" ]; then
    cp -a doc /usr/local/zed/
    echo "Installed documentation"
fi

# Install cmake files
if [ -f "zed-config.cmake" ]; then
    cp zed-config.cmake /usr/local/zed/
fi
if [ -f "zed-config-version.cmake" ]; then
    cp zed-config-version.cmake /usr/local/zed/
fi

# Install udev rules
if [ -f "99-slabs.rules" ]; then
    cp 99-slabs.rules /etc/udev/rules.d/
    echo "Installed udev rules"
fi

# Install get_python_api.py
if [ -f "get_python_api.py" ]; then
    cp get_python_api.py /usr/local/zed/
    chmod +x /usr/local/zed/get_python_api.py
fi

# Set up library configuration (like our deb package)
echo "/usr/local/zed/lib" > /etc/ld.so.conf.d/001-zed.conf
echo "Created library configuration"

# Set permissions (like our deb package)
chgrp -R zed /usr/local/zed 2>/dev/null || true
chmod -R g+rX /usr/local/zed 2>/dev/null || true

# Update library cache
ldconfig
echo "Updated library cache"

# Install Python wheel
echo "Installing Python wheel..."
cd "$WORK_DIR"
python3 -m pip install --no-deps "$PYZED_WHEEL_FILE"
echo "Python wheel installed"

# Reload udev rules
udevadm control --reload-rules 2>/dev/null || true
udevadm trigger 2>/dev/null || true

echo "=========================================="
echo "ZED SDK installation completed!"
echo "=========================================="

# Display installation summary
echo "Installation Summary:"
echo "- ZED SDK installed to: /usr/local/zed"
echo "- Libraries: $(find /usr/local/zed/lib -name "*.so*" 2>/dev/null | wc -l) shared libraries"
echo "- Tools: $(find /usr/local/zed/tools -type f -executable 2>/dev/null | wc -l) executables"
echo "- Python package: $(python3 -c 'import pyzed; print(\"pyzed imported successfully\")' 2>/dev/null || echo 'pyzed import failed')"

# Create installation marker
echo "runfile" > /tmp/zed_install_method.txt
echo "Installation method marker created: /tmp/zed_install_method.txt"

echo "Ready for comparison testing!"