# ZED SDK 5.1.2 JP60 - Debhelper Package

This is a Debian package for ZED SDK 5.1.2 on NVIDIA Jetson platforms, using debhelper build system with Docker support.

## Overview

- **Version**: 5.1.2
- **Platform**: NVIDIA Jetson (JetPack 6.0 / L4T 36.3)
- **Architecture**: arm64
- **Build System**: debhelper + dpkg-buildpackage
- **Package Format**: Consolidated (SDK + Python bindings in one package)

## Quick Start

### Docker Build (Recommended)

Build in a simulated Jetson Linux 6.0 environment:

```bash
cd v5.1.2/jp60
make docker-build
```

The package will be in `output/zed-sdk-jetpack_5.1.2-1_arm64.deb`

### Native Build

Build directly on a Jetson device or ARM64 system:

```bash
cd v5.1.2/jp60
make build
```

Requires debhelper and dependencies installed on a Jetson device or ARM64 system.

## Structure

```
v5.1.2/jp60/
├── debian/                    # Debian packaging
│   ├── control               # Package metadata and dependencies
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
# Build with Docker (recommended)
make docker-build

# Interactive Docker shell for debugging
make docker-shell

# Native build
make build

# Clean build artifacts
make clean

# Clean everything including downloads
make clean-all
```

## Package Contents

- **ZED SDK** v5.1.2 libraries and headers
- **Python bindings** (pyzed 5.1)
- **Development tools** (ZED_Explorer, ZED_Diagnostic, etc.)
- **Samples** and documentation
- **AI model optimizer** (`zed_ai_optimizer`)
- **ZED Media Server** service

## Installation

On a Jetson device:

```bash
# Install the package
sudo dpkg -i zed-sdk-jetpack_5.1.2-1_arm64.deb

# Fix any missing dependencies
sudo apt-get install -f

# Add user to video group
sudo usermod -a -G video $USER

# Log out and back in, then optimize AI models
sudo zed_ai_optimizer
```

## Requirements

### For Runtime
- **Jetson Devices**: Orin, Xavier, TX2 series
- **JetPack**: 6.0 (GA)
- **L4T**: 36.3
- **Ubuntu**: 22.04 (base OS)
- **Python**: 3.10

### For Building with Docker
- Docker installed
- For x86_64 hosts: QEMU ARM64 emulation
- At least 10GB free disk space
- Good internet connection (~2GB download)

### For Native Building
- Jetson device or ARM64 system
- debhelper, dpkg-dev, devscripts, fakeroot
- zstd, python3-dev, python3-pip

## Docker Build Details

The build system uses the NVIDIA L4T TensorRT container to simulate a Jetson environment on any host system.

- **Base Image**: `nvcr.io/nvidia/l4t-tensorrt:r8.6.2-devel`
- **L4T Version**: 36.3 (JetPack 6.0)
- **User Permissions**: Runs as host user (UID/GID preserved)
- **Output**: Files owned by your user, no root permission issues

### Prerequisites for x86_64 Hosts

Install QEMU for ARM64 emulation:

```bash
# On Ubuntu/Debian
sudo apt-get install qemu-user-static binfmt-support

# Verify
docker run --rm --platform linux/arm64 arm64v8/ubuntu uname -m
# Should output: aarch64
```

### Docker Build Process

1. Downloads `ZED_SDK_Tegra_L4T36.3_v5.1.2.zstd.run` (~1.5GB)
2. Downloads `pyzed-5.1-cp310-cp310-linux_aarch64.whl` (~50MB)
3. Extracts the run file
4. Applies Python shebang patch
5. Packages everything into a `.deb` file
6. Copies artifacts to `output/` directory

### Build Artifacts

```
v5.1.2/jp60/output/
├── zed-sdk-jetpack_5.1.2-1_arm64.deb       # Main package
├── zed-sdk-jetpack_5.1.2-1_arm64.buildinfo # Build information
└── zed-sdk-jetpack_5.1.2-1_arm64.changes   # Package changes
```

### Interactive Development

For development and debugging:

```bash
make docker-shell

# Inside the container:
ls -la                    # View files
make build                # Build manually
dpkg-buildpackage -b      # Build with debhelper directly
dpkg-deb --info ../*.deb  # Inspect package
```

## Compatibility

- **Jetson Devices**: Orin, Xavier, TX2 series
- **JetPack**: 6.0 (GA release)
- **L4T**: 36.3
- **Ubuntu**: 22.04
- **Python**: 3.10

## Troubleshooting

### Docker build fails with "exec format error"

Install QEMU:
```bash
sudo apt-get install qemu-user-static binfmt-support
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

### Download failures

- Check internet connection
- Verify URLs in `debian/rules` are accessible
- Try manually downloading files to the build directory

### Permission issues after build

Docker creates files as the host user (no permission issues with current setup).

## Notes

- Uses L4T 36.3 for JetPack 6.0 compatibility
- Advanced `zed_ai_optimizer` script with NPU/DLA hardware acceleration
- Includes ZED Media Server for streaming capabilities
- Consolidated package: SDK + Python bindings in one .deb file
- Conflicts with `libv4l-dev` (breaks hardware encoding on Jetson)
- AI model optimization can take 30-60 minutes (one-time process)

## Features

✅ **Debhelper packaging** - Standard Debian build system
✅ **Docker build support** - Build on any platform with Docker/QEMU
✅ **Host UID/GID preservation** - No root permission issues on built files
✅ **Consolidated package** - SDK + Python bindings in one .deb
✅ **NPU/DLA optimization** - AI models optimized for Jetson hardware
✅ **Media Server** - Built-in streaming service

## Resources

- [Main Documentation](../../CLAUDE.md)
- [ZED SDK Docs](https://www.stereolabs.com/docs/)
- [Jetson Linux Documentation](https://developer.nvidia.com/embedded/jetson-linux)
- [NVIDIA L4T Container Catalog](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/l4t-tensorrt)

---

**Created**: December 2024
**Maintainer**: Hsiang-Jui Lin <jerry73204@gmail.com>
