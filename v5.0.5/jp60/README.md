# ZED SDK 5.0.5 JP60 - Debhelper Package

This is a Debian package for ZED SDK 5.0.5 on NVIDIA Jetson platforms, using debhelper build system with Docker support.

## Overview

- **Version**: 5.0.5
- **Platform**: NVIDIA Jetson (JetPack 6.0 / L4T 36.4)
- **Architecture**: arm64
- **Build System**: debhelper + dpkg-buildpackage
- **Package Format**: Consolidated (SDK + Python bindings in one package)

## Quick Start

### Docker Build (Recommended)

```bash
cd v5.0.5/jp60
make docker-build
```

The package will be in `output/zed-sdk-jetpack_5.0.5-1_arm64.deb`

### Native Build

```bash
cd v5.0.5/jp60
make build
```

Requires debhelper and dependencies installed on a Jetson device or ARM64 system.

## Structure

```
v5.0.5/jp60/
├── debian/                    # Debian packaging
│   ├── control               # Package metadata
│   ├── rules                 # Build instructions
│   ├── changelog             # Package changelog
│   ├── postinst              # Post-installation script
│   ├── prerm                 # Pre-removal script
│   ├── postrm                # Post-removal script
│   └── source/format         # Source format
├── docker/                    # Docker build system
│   ├── Dockerfile.build      # L4T TensorRT base
│   ├── docker-build.sh       # Main build script
│   └── build-in-docker.sh    # Container build script
├── output/                    # Build outputs
│   └── .gitkeep
├── Makefile                   # Build automation
├── .gitignore                 # Ignore build artifacts
├── python_shebang.patch       # Python script fix
├── zed_ai_optimizer           # AI model optimizer script
└── zed.pc.in                  # pkg-config template
```

## Build Commands

```bash
# Build with Docker
make docker-build

# Interactive Docker shell
make docker-shell

# Native build
make build

# Clean build artifacts
make clean

# Clean everything including downloads
make clean-all
```

## Package Contents

- **ZED SDK** v5.0.5 libraries and headers
- **Python bindings** (pyzed 5.0)
- **Development tools** (ZED_Explorer, ZED_Diagnostic, etc.)
- **Samples** and documentation
- **AI model optimizer** (`zed_ai_optimizer`)
- **ZED Media Server** service

## Installation

On a Jetson device:

```bash
sudo dpkg -i zed-sdk-jetpack_5.0.5-1_arm64.deb
sudo apt-get install -f
sudo usermod -a -G video $USER
# Log out and back in
sudo zed_ai_optimizer
```

## Requirements

### For Runtime
- NVIDIA Jetson (Orin, Xavier series)
- JetPack 6.0 (GA)
- L4T 36.4
- Ubuntu 22.04 (base OS)

### For Building
- Docker (for Docker build method)
- OR Jetson device with debhelper installed (for native build)

## Docker Build Details

- **Base Image**: `nvcr.io/nvidia/l4t-tensorrt:r8.6.2-devel`
- **L4T Version**: 36.4 (JetPack 6.0)
- **User Permissions**: Runs as host user (UID/GID preserved)
- **Output**: Files owned by your user, no root permission issues

### Prerequisites for x86_64 Hosts

If building on x86_64 system, install QEMU for ARM64 emulation:

```bash
sudo apt-get install qemu-user-static binfmt-support
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

## Notes

- Uses L4T 36.4 (JetPack 6.0 GA release)
- Advanced `zed_ai_optimizer` script with NPU/DLA hardware acceleration
- Includes ZED Media Server for streaming capabilities
- Consolidated package: SDK + Python bindings in one .deb file
- Conflicts with `libv4l-dev` (breaks hardware encoding on Jetson)

## Features

✅ **Debhelper packaging** - Standard Debian build system
✅ **Docker build support** - Build on any platform with Docker/QEMU
✅ **Host UID/GID preservation** - No root permission issues on built files
✅ **Consolidated package** - SDK + Python bindings in one .deb
✅ **NPU/DLA optimization** - AI models optimized for Jetson hardware
✅ **Media Server** - Built-in streaming service

---

**Created**: December 2024
**Maintainer**: Hsiang-Jui Lin <jerry73204@gmail.com>
