# ZED SDK Debian Package

<p align="center">
  <a href="https://github.com/jerry73204/zed-sdk-debian-package/releases/tag/4.2-1">
    <strong>Download Debian Packages »</strong>
  </a>
</p>

This repository contains makedeb PKGBUILD scripts to create Debian packages for the StereoLabs ZED SDK. It extracts the content from the ZED SDK run file and re-packages it into a Debian package file.

**This is not an official release. Use at your own risk.**

## Repository Structure

The repository has been restructured to support separate builds for different architectures:

```
makedeb-zed-sdk/
├── README.md                    # This file
├── shared/                      # Shared files
├── x86_64/                      # x86_64/Desktop builds
│   ├── zed-sdk/                 # Main SDK package
│   └── python3-pyzed/           # Python bindings
└── jetson/                      # Jetson/ARM64 builds
    ├── zed-sdk/                 # Main SDK package
    └── python3-pyzed/           # Python bindings
```

## Prerequisites

### For x86_64 (Desktop) Systems

- **Operating System:** Ubuntu 22.04
- **CUDA:** Version 12.1 or higher
- **NVIDIA AI Libraries:** cuDNN 8.9.7+, TensorRT 8.6.1+

**Set up NVIDIA apt repository:**
```bash
# Add NVIDIA package repository
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update

# Install required AI libraries
sudo apt install libcudnn8 libcudnn8-dev libnvinfer8 libnvinfer-plugin8 libnvonnxparsers8
```

### For Jetson (ARM64) Systems

- **Operating System:** JetPack 6.0 / L4T 36.3
- **Note:** AI libraries (cuDNN, TensorRT) are included in JetPack

## Build the Debian Package

**For building packages from source**, you need to install `makedeb`. Please visit [makedeb.org](https://www.makedeb.org/) to install this command. See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed build instructions.

### For x86_64 (Desktop) Systems

Build the main SDK:
```bash
cd x86_64/zed-sdk
make
```

Build Python bindings (optional):
```bash
cd x86_64/python3-pyzed
make
```

### For Jetson (ARM64) Systems

Build the main SDK:
```bash
cd jetson/zed-sdk
make
```

Build Python bindings (optional):
```bash
cd jetson/python3-pyzed
make
```

## Installation

After building the packages (or downloading pre-built packages from releases):

### For x86_64 (Desktop) Systems

```bash
# Install the main SDK package
sudo apt install ./zed-sdk_4.2-1_amd64.deb

# Optionally install Python bindings
sudo apt install ./python3-pyzed_4.2-1_amd64.deb
```

### For Jetson (ARM64) Systems

```bash
# Install the main SDK package
sudo apt install ./zed-sdk_4.2-1_arm64.deb

# Optionally install Python bindings
sudo apt install ./python3-pyzed_4.2-1_arm64.deb
```

**Note:** The Python bindings package (`python3-pyzed`) is optional but recommended if you plan to use the ZED SDK with Python.

## Important Notes

### For x86_64/Desktop Users

1. **CUDA and AI Dependencies:**
   - CUDA 12.1+ is required
   - AI features require cuDNN and TensorRT from NVIDIA apt repository (see Prerequisites)
   - This package uses system libraries instead of bundling them (~2.4GB saved)

2. **User Groups and Permissions:**
   - The installer automatically adds you to `zed` and `video` groups
   - Multi-user support is enabled via the `zed` group
   - **You must log out and log back in** for group membership to take effect

3. **AI Models:**
   - AI models are not included in the package
   - Download and optimize models after installation: `sudo zed_download_ai_models`
   - This process downloads models from StereoLabs servers and optimizes them for your system

### For Jetson Users

1. **System Requirements:**
   - **JetPack 6.0 / L4T 36.3 is required** for this package version
   - AI libraries (cuDNN, TensorRT) are included in JetPack

2. **libv4l-dev Conflict:**
   - **DO NOT** install the `libv4l-dev` package on Jetson devices
   - It will break hardware encoding/decoding support
   - This package is configured to conflict with `libv4l-dev` to prevent accidental installation

3. **Automatic Configuration:**
   - The installer modifies `nvargus-daemon.service` to enable infinite timeout for camera connections
   - Improves stability with multiple cameras
   - The `zed_media_server_cli.service` is automatically enabled and started
   - User groups (`zed` and `video`) are configured automatically

4. **ZED X Camera Support:**
   - GMSL drivers are installed if present in the SDK package
   - For specific hardware configurations, you may need additional driver packages
   - See [official ZED X documentation](https://www.stereolabs.com/docs/get-started-with-zed-x/) for details

5. **AI Models:**
   - Download and optimize models after installation: `sudo zed_download_ai_models`
   - **You must log out and log back in** for group membership to take effect

## Post-Installation

After installing the package, follow these steps:

### 1. Apply Group Membership

**Log out and log back in** (or reboot) for the `zed` and `video` group membership to take effect.

Verify your group membership:
```bash
groups
# Should show: ... zed video ...
```

### 2. Download AI Models (Optional but Recommended)

If you plan to use AI features (object detection, body tracking, neural depth):

```bash
sudo zed_download_ai_models
```

This will:
- Download all available AI models from StereoLabs servers
- Optimize them for your specific hardware
- May take significant time depending on your system

### 3. Verify Installation

Test that the SDK is working:

```bash
# Check ZED SDK version
ZED_Diagnostic

# List available ZED tools
ls /usr/local/zed/tools/

# Test with a ZED camera (if connected)
ZED_Explorer
```

### 4. Test Python Bindings (if installed)

```bash
python3 -c "import pyzed.sl as sl; print(f'ZED SDK {sl.Camera.get_sdk_version()}')"
```

## Contributing

Interested in building from source or contributing to this project? See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- How to build packages from source
- Package architecture and design decisions
- Key differences from the official installer
- Testing guidelines
