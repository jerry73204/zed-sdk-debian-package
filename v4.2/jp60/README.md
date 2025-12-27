# ZED SDK 4.2 JP60 - Debhelper Package

This is a Debian package for ZED SDK 4.2 on NVIDIA Jetson platforms, using debhelper build system with Docker support.

## Overview

- **Version**: 4.2
- **Platform**: NVIDIA Jetson (JetPack 5.x / L4T 36.3)
- **Architecture**: arm64
- **Build System**: debhelper + dpkg-buildpackage
- **Package Format**: Consolidated (SDK + Python bindings in one package)

## Quick Start

### Docker Build (Recommended)

```bash
cd v4.2/jp60
make docker-build
```

The package will be in `output/zed-sdk-jetpack_4.2-1_arm64.deb`

### Native Build

```bash
cd v4.2/jp60
make build
```

Requires debhelper and dependencies installed on a Jetson device or ARM64 system.

## Structure

```
v4.2/jp60/
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
├── zed_download_ai_models     # AI model download script
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

- **ZED SDK** v4.2 libraries and headers
- **Python bindings** (pyzed 4.2)
- **Development tools** (ZED_Explorer, ZED_Diagnostic, etc.)
- **Samples** and documentation
- **AI model download script** (`zed_download_ai_models`)
- **ZED Media Server** service
- **GMSL drivers** (if included in SDK)

## Installation

On a Jetson device:

```bash
sudo dpkg -i zed-sdk-jetpack_4.2-1_arm64.deb
sudo apt-get install -f
sudo usermod -a -G video $USER
# Log out and back in
sudo zed_download_ai_models
```

## Docker Build Details

- **Base Image**: `nvcr.io/nvidia/l4t-tensorrt:r8.6.2-devel`
- **L4T Version**: 36.3 (JetPack 5.x)
- **User Permissions**: Runs as host user (UID/GID preserved)
- **Output**: Files owned by your user, no root permission issues

## Notes

- Uses L4T 36.3 (not 36.4 like v5.0.5)
- Uses simpler `zed_download_ai_models` script (not `zed_ai_optimizer`)
- Compatible with JetPack 5.x (v5.0.5 and v5.1.2 require JetPack 6.0)
- Consolidated package: SDK + Python bindings in one .deb file
- Converted from makedeb to debhelper for consistency with v5.x

## Features

✅ **Debhelper packaging** - Standard Debian build system
✅ **Docker build support** - Build on any platform with Docker/QEMU
✅ **Host UID/GID preservation** - No root permission issues on built files
✅ **Consolidated package** - Simpler than split SDK/Python packages
✅ **Consistent structure** - Matches v5.0.5 and v5.1.2 layout

---

**Created**: December 2024
**Maintainer**: Hsiang-Jui Lin <jerry73204@gmail.com>
