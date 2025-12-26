# Docker Build Environment for ZED SDK JP60

This directory contains Docker-based build tools for creating ZED SDK Debian packages in a simulated Jetson Linux 6.0 (L4T 36.3) environment.

## Overview

The build system uses the NVIDIA L4T TensorRT container (`nvcr.io/nvidia/l4t-tensorrt:r8.6.2-devel`) to simulate a Jetson environment on any host system, allowing you to build ARM64 packages for Jetson devices without needing physical Jetson hardware.

## Prerequisites

- Docker installed on your system
- Docker with ARM64/aarch64 emulation support (automatic on ARM hosts, requires QEMU on x86_64)
- At least 10GB free disk space
- Good internet connection (initial setup downloads ~2GB)

### Setting up ARM64 Emulation on x86_64

If you're building on an x86_64 system, you'll need QEMU for ARM64 emulation:

```bash
# On Ubuntu/Debian
sudo apt-get install qemu-user-static binfmt-support

# Verify
docker run --rm --platform linux/arm64 arm64v8/ubuntu uname -m
# Should output: aarch64
```

## Files

- **Dockerfile.build** - Defines the L4T-based build container
- **docker-build.sh** - Main build script (builds image and package)
- **build-in-docker.sh** - Internal script that runs inside the container
- **README.md** - This file

## Quick Start

### Build Everything (Image + Package)

```bash
cd v5.1.2/jp60/docker
./docker-build.sh
```

This will:
1. Build the Docker image with makedeb and all dependencies
2. Download the ZED SDK and Python wheel
3. Build the Debian package
4. Copy the package to `../output/`

### Build Options

```bash
# Skip image build (use existing image)
./docker-build.sh --skip-image-build

# Only build the Docker image (don't build package)
./docker-build.sh --build-only

# Run interactive shell in container
./docker-build.sh --interactive

# Show help
./docker-build.sh --help
```

## Interactive Development

For development and debugging, you can run an interactive shell:

```bash
./docker-build.sh -i
```

Inside the container:

```bash
# You'll be in /build/package directory (mounted from v5.1.2/jp60)
ls -la

# Build manually
make build

# Or step by step
makedeb -s

# Check the package
dpkg-deb --info *.deb

# Copy to output
cp *.deb /build/output/
```

## Directory Structure

```
v5.1.2/jp60/
├── docker/
│   ├── Dockerfile.build      # Docker image definition
│   ├── docker-build.sh       # Main build script (run this)
│   ├── build-in-docker.sh    # Internal build script
│   └── README.md             # This file
├── output/                   # Build output (created automatically)
│   └── *.deb                 # Generated packages appear here
├── PKGBUILD                  # makedeb build instructions
├── Makefile                  # Build automation
├── postinst.sh               # Post-install script
├── prerm.sh                  # Pre-removal script
├── postrm.sh                 # Post-removal script
├── python_shebang.patch      # Python shebang fix
└── zed_ai_optimizer          # AI optimizer tool
```

## Build Process Details

### 1. Docker Image Build

The Docker image is based on `nvcr.io/nvidia/l4t-tensorrt:r8.6.2-devel` which provides:
- Ubuntu 22.04 for ARM64
- NVIDIA L4T 36.x libraries
- TensorRT 8.6.2
- CUDA libraries for Jetson

Additional installations:
- Debian packaging tools (debhelper, dpkg-dev, devscripts, fakeroot)
- ZED SDK dependencies (Qt, OpenGL, Python, etc.)
- Build tools (wget, zstd, tar, etc.)

### 2. Package Build

The build process:
1. Downloads `ZED_SDK_Tegra_L4T36.3_v5.1.2.zstd.run` (~1.5GB)
2. Downloads `pyzed-5.1-cp310-cp310-linux_aarch64.whl` (~50MB)
3. Extracts the run file
4. Applies Python shebang patch
5. Packages everything into a `.deb` file
6. Copies artifacts to `output/` directory

### 3. Output

Generated files in `v5.1.2/jp60/output/`:
- `zed-sdk-jetpack_5.1.2-1_arm64.deb` - Main package
- `*.buildinfo` - Build information
- `*.changes` - Package changes
- `*.log` - Build logs (if any)

## Troubleshooting

### ARM64 Emulation Issues

If you see errors like "exec format error":

```bash
# Install QEMU
sudo apt-get install qemu-user-static binfmt-support

# Register binfmt
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

### Download Failures

If SDK downloads fail:
- Check internet connection
- Verify the download URL in PKGBUILD is correct
- Try manually downloading and placing files in the build directory

### Build Failures

Check the build logs:

```bash
# Interactive mode for debugging
./docker-build.sh -i

# Inside container, check logs
cd /build/package
cat build/extract/doc/license/LICENSE.txt  # Verify extraction
ls -la build/                               # Check extracted files
```

### Permission Issues

The container runs as root, so output files are owned by root:

```bash
# Fix ownership after build
sudo chown -R $USER:$USER output/
```

## Platform Notes

### L4T Version Compatibility

- This build uses **L4T 36.3** (Jetson Linux 6.0)
- Compatible with JetPack 6.0 (GA release)
- Works on: Jetson Orin series, Xavier series

### Why L4T TensorRT Image?

The L4T TensorRT image provides:
- Authentic Jetson environment
- Pre-installed NVIDIA libraries
- Correct library versions for Jetson
- TensorRT and CUDA support

This ensures the package is built with the same libraries it will use on real Jetson hardware.

## Advanced Usage

### Custom SDK Version

Edit `debian/rules` to change versions:

```bash
ZED_VERSION = 5.1.2                    # Change this
ZED_VERSION_MAJOR_MINOR = 5.1          # Change this too
```

### Build with Different Base Image

Edit `Dockerfile.build`:

```dockerfile
FROM nvcr.io/nvidia/l4t-tensorrt:r8.6.2-devel  # Change this
```

Available L4T images: https://catalog.ngc.nvidia.com/orgs/nvidia/containers/l4t-tensorrt

### Automated CI/CD

Use in CI pipelines:

```yaml
# Example GitHub Actions
- name: Build ZED SDK Package
  run: |
    cd v5.1.2/jp60/docker
    ./docker-build.sh --skip-image-build
```

## Resources

- [NVIDIA L4T Container Catalog](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/l4t-tensorrt)
- [ZED SDK Documentation](https://www.stereolabs.com/docs/)
- [Debian Packaging Guide](https://www.debian.org/doc/manuals/maint-guide/)
- [Jetson Linux Documentation](https://developer.nvidia.com/embedded/jetson-linux)

## Support

For issues specific to:
- **Docker build system**: Check this README and troubleshooting section
- **Package contents**: See main PKGBUILD and CLAUDE.md
- **ZED SDK**: Visit StereoLabs support

---

**Last updated**: December 2025
**Maintainer**: Hsiang-Jui Lin <jerry73204@gmail.com>
