# ZED SDK 5.1.2 JP60 Build Guide

## Quick Start

### Option 1: Docker Build (Recommended)

Build in a simulated Jetson Linux 6.0 environment:

```bash
cd v5.1.2/jp60
make docker-build
```

The built package will be in `output/zed-sdk-jetpack_5.1.2-1_arm64.deb`

### Option 2: Native Build

Build directly on a Jetson device or ARM64 system with makedeb installed:

```bash
cd v5.1.2/jp60
make build
```

## Docker Build System

### Prerequisites

- Docker installed
- For x86_64 hosts: QEMU ARM64 emulation

```bash
# Install QEMU on Ubuntu/Debian
sudo apt-get install qemu-user-static binfmt-support
```

### Usage

```bash
# Full build (image + package)
make docker-build

# Interactive shell for debugging
make docker-shell

# Inside shell:
#   make build               # Build package
#   dpkg-buildpackage -b     # Build with debhelper directly
#   dpkg-deb --info ../*.deb # Inspect package
```

### How It Works

1. Uses `nvcr.io/nvidia/l4t-tensorrt:r8.6.2-devel` base image
2. Installs debhelper and Debian packaging tools
3. Downloads ZED SDK (L4T 36.3) and Python wheel
4. Builds Debian package using dpkg-buildpackage
5. Outputs to `output/` directory

### Build Artifacts

```
v5.1.2/jp60/output/
├── zed-sdk-jetpack_5.1.2-1_arm64.deb
├── zed-sdk-jetpack_5.1.2-1_arm64.buildinfo
└── zed-sdk-jetpack_5.1.2-1_arm64.changes
```

## Native Build System

### Prerequisites

```bash
# Install Debian packaging tools
sudo apt-get install debhelper dh-make dpkg-dev devscripts fakeroot

# Install build dependencies
sudo apt-get install zstd tar python3-pip python3-dev
```

### Usage

```bash
cd v5.1.2/jp60

# Build package
make build

# Clean build artifacts
make clean

# Clean everything including downloads
make clean-all
```

## Package Details

- **Name**: zed-sdk-jetpack
- **Version**: 5.1.2-1
- **Architecture**: arm64
- **Platform**: NVIDIA Jetson (JetPack 6.0 / L4T 36.3)
- **SDK Run File**: `ZED_SDK_Tegra_L4T36.3_v5.1.2.zstd.run`
- **Python Wheel**: `pyzed-5.1-cp310-cp310-linux_aarch64.whl`

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

## Compatibility

- **Jetson Devices**: Orin, Xavier, TX2 series
- **JetPack**: 6.0 (GA)
- **L4T**: 36.3
- **Ubuntu**: 22.04 (base OS)
- **Python**: 3.10

## Docker Build Details

See [docker/README.md](docker/README.md) for:
- Detailed Docker setup instructions
- Troubleshooting ARM64 emulation
- Advanced usage and customization
- CI/CD integration

## Files Structure

```
v5.1.2/jp60/
├── debian/               # Debian packaging directory
│   ├── control          # Package metadata and dependencies
│   ├── rules            # Build instructions
│   ├── changelog        # Package changelog
│   ├── compat           # Debhelper compatibility level
│   ├── postinst         # Post-installation script
│   ├── prerm            # Pre-removal script
│   ├── postrm           # Post-removal script
│   └── source/format    # Source format
├── Makefile              # Build automation
├── BUILD_GUIDE.md        # This file
├── python_shebang.patch  # Python script fix
├── zed_ai_optimizer      # AI model optimizer
├── docker/               # Docker build system
│   ├── Dockerfile.build
│   ├── docker-build.sh
│   ├── build-in-docker.sh
│   └── README.md
└── output/               # Build outputs (created)
    └── *.deb
```

## Troubleshooting

### Docker build fails with "exec format error"

Install QEMU:
```bash
sudo apt-get install qemu-user-static binfmt-support
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

### Download failures

Check internet connection and verify URLs in PKGBUILD are accessible.

### Permission issues

Docker creates files as root:
```bash
sudo chown -R $USER:$USER output/
```

## Development

### Testing changes

```bash
# Make changes to PKGBUILD or scripts
vim PKGBUILD

# Test in Docker
make docker-shell

# Inside container
make build
dpkg-deb --info *.deb
```

### Updating SDK version

1. Edit `PKGBUILD`: Change `pkgver`
2. Update download URLs if needed
3. Rebuild: `make docker-build`

## Resources

- [Main Documentation](../../CLAUDE.md)
- [Docker Build README](docker/README.md)
- [ZED SDK Docs](https://www.stereolabs.com/docs/)
- [makedeb Docs](https://docs.makedeb.org/)

---

**Version**: 5.1.2
**Platform**: JP60 (Jetson Linux 6.0 / L4T 36.3)
**Last Updated**: December 2025
