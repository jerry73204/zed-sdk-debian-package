# ZED SDK 5.0.5 AMD64 - Debhelper Package

This is a Debian package for ZED SDK 5.0.5 on x86_64/AMD64 systems, using debhelper build system with Docker support.

## Overview

- **Version**: 5.0.5
- **Platform**: AMD64 (x86_64) desktop and server systems
- **Architecture**: amd64
- **Build System**: debhelper + dpkg-buildpackage
- **Package Format**: Consolidated (SDK + Python bindings in one package)
- **Base OS**: Ubuntu 22.04 (Jammy)
- **CUDA**: 12.8
- **TensorRT**: 10.9

## Quick Start

### Docker Build (Recommended)

```bash
cd v5.0.5/amd64
make docker-build
```

The package will be in `output/zed-sdk_5.0.5-1_amd64.deb`

### Native Build

```bash
cd v5.0.5/amd64
make build
```

Requires debhelper and dependencies installed on an Ubuntu 22.04 system.

## Structure

```
v5.0.5/amd64/
├── debian/                    # Debian packaging
│   ├── control               # Package metadata
│   ├── rules                 # Build instructions
│   ├── changelog             # Package changelog
│   ├── postinst              # Post-installation script
│   ├── prerm                 # Pre-removal script
│   ├── postrm                # Post-removal script
│   └── source/format         # Source format
├── docker/                    # Docker build system
│   ├── Dockerfile.build      # Ubuntu 22.04 base
│   ├── docker-build.sh       # Main build script
│   └── build-in-docker.sh    # Container build script
├── output/                    # Build outputs
│   └── .gitkeep
├── Makefile                   # Build automation
├── .gitignore                 # Ignore build artifacts
├── python_shebang.patch       # Python script fix
└── zed_ai_optimizer           # AI model optimizer script
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
- **CUDA 12.8** and **TensorRT 10.9** support

## Installation

On an Ubuntu 22.04 system with NVIDIA GPU:

```bash
sudo dpkg -i zed-sdk_5.0.5-1_amd64.deb
sudo apt-get install -f
sudo usermod -a -G video $USER
# Log out and back in
sudo zed_ai_optimizer
```

## Requirements

### For Runtime
- Ubuntu 22.04 (Jammy)
- NVIDIA GPU with CUDA support
- CUDA 12.8 or higher
- Compatible NVIDIA drivers (535+)
- TensorRT 10.9 (optional, for AI features)

### For Building
- Docker (for Docker build method)
- OR Ubuntu 22.04 with debhelper installed (for native build)

## Docker Build Details

- **Base Image**: `ubuntu:22.04`
- **User Permissions**: Runs as host user (UID/GID preserved)
- **Output**: Files owned by your user, no root permission issues

## Notes

- Package includes both SDK and Python bindings (consolidated)
- AI model optimization can take 30-60 minutes (one-time)
- Requires CUDA 12.8 for GPU acceleration
- TensorRT 10.9 for optimal AI model performance

## Features

✅ **Debhelper packaging** - Standard Debian build system
✅ **Docker build support** - Build on any platform with Docker
✅ **Host UID/GID preservation** - No root permission issues on built files
✅ **Consolidated package** - SDK + Python bindings in one .deb
✅ **AI optimizer** - Advanced model optimization for CUDA/TensorRT

---

**Created**: December 2024
**Maintainer**: Hsiang-Jui Lin <jerry73204@gmail.com>
