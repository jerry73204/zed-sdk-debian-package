# ZED SDK Debian Package - Technical Documentation

## Project Overview

This project creates Debian packages for the StereoLabs ZED SDK using the standard **debhelper** packaging system. It provides packaging scripts for multiple ZED SDK versions (4.2, 5.0.5, 5.1.2) across different platforms (AMD64 and NVIDIA Jetson) by extracting content from the official ZED SDK `.run` installers and repackaging them into `.deb` packages suitable for Debian/Ubuntu systems.

All builds use Docker containers to ensure reproducible builds across different host environments.

## Repository Structure

The repository uses a **version-based organization** where each ZED SDK version is self-contained:

```
zed-sdk-debian-package/
├── v4.2/                     # ZED SDK 4.2 (Legacy)
│   ├── amd64/               # x86_64 desktop/server (Ubuntu 22.04, CUDA 12)
│   └── jp60/                # JetPack 6.0 / L4T 36.3
│
├── v5.0.5/                   # ZED SDK 5.0.5 (Stable)
│   ├── amd64/               # x86_64 desktop/server (Ubuntu 22.04, CUDA 12.8)
│   └── jp60/                # JetPack 6.0 / L4T 36.4
│
├── v5.1.2/                   # ZED SDK 5.1.2 (Latest)
│   ├── amd64/               # x86_64 desktop/server (Ubuntu 22.04, CUDA 12.8)
│   └── jp60/                # JetPack 6.0 / L4T 36.3
│
└── tests/                    # Build test suite (docker-build for all versions)
```

Each platform directory contains:
- `debian/` - Debhelper packaging files (control, rules, changelog, maintainer scripts)
- `docker/` - Docker build environment (Dockerfile.build, build scripts)
- `Makefile` - Build automation
- `README.md` - Platform-specific documentation
- `zed.pc.in` - pkg-config template

## Version Comparison

All versions now use **debhelper** with **consolidated packaging** (SDK + Python in single .deb).

### v4.2 (Legacy)

**SDK Version:** 4.2
**Platforms:** amd64, jp60
**CUDA:** 12.0
**L4T:** 36.3 (Jetson)
**AI Tools:** Basic `zed_download_ai_models` script
**Status:** Legacy, critical fixes only

### v5.0.5 (Stable)

**SDK Version:** 5.0.5
**Platforms:** amd64, jp60
**CUDA:** 12.8
**TensorRT:** 10.9
**L4T:** 36.4 (Jetson, JetPack 6.0 GA)
**AI Tools:** Advanced `zed_ai_optimizer` with platform detection
**Status:** Stable, maintenance mode

### v5.1.2 (Latest)

**SDK Version:** 5.1.2
**Platforms:** amd64, jp60
**CUDA:** 12.8
**TensorRT:** 10.9
**L4T:** 36.3 (Jetson)
**AI Tools:** Advanced `zed_ai_optimizer` with platform detection
**Status:** Active development, latest features

## Technology Stack

- **debhelper**: Standard Debian package building system (dpkg-buildpackage, dh)
- **Docker**: Isolated build environments for reproducible builds
- **Bash scripting**: Package lifecycle management (postinst, prerm, postrm)
- **systemd**: Service management on Jetson devices
- **Python pip**: Python wheel package installation
- **Make**: Build automation and test orchestration

## Platform Variants

### AMD64 (Desktop/Server)
- **Target:** x86_64 desktop and server systems with NVIDIA GPUs
- **SDK installer:** `ZED_SDK_Ubuntu22_cuda12.8_tensorrt10.9_v*.zstd.run`
- **Python wheel:** `pyzed-*.0-cp310-cp310-linux_x86_64.whl`
- **Optimization:** CUDA GPU acceleration via TensorRT
- **Base image:** Ubuntu 22.04
- **CUDA:** 12.0-12.8 (version dependent)
- **TensorRT:** 10.9 (v5.x)

### JP60 (NVIDIA Jetson)
- **Target:** NVIDIA Jetson platforms (Orin, Xavier, etc.)
- **SDK installer:** `ZED_SDK_Tegra_L4T36.*_v*.zstd.run`
- **Python wheel:** `pyzed-*.0-cp310-cp310-linux_aarch64.whl`
- **Optimization:** NPU/DLA hardware acceleration
- **Base image:** NVIDIA L4T with TensorRT
- **L4T:** 36.3-36.4 (JetPack 6.0)
- **Special features:**
  - Conflicts with `libv4l-dev` (breaks hardware encoding)
  - Includes `nvidia-l4t-camera` dependency
  - Configures `nvargus-daemon` for infinite camera timeout
  - Installs and enables `zed_media_server_cli.service`

## Package Features

### pkg-config Support
All packages install a pkg-config file for easy library discovery:

**AMD64:** `/usr/lib/x86_64-linux-gnu/pkgconfig/zed.pc`
**JP60:** `/usr/lib/aarch64-linux-gnu/pkgconfig/zed.pc`

Usage:
```bash
pkg-config --cflags --libs zed
# Output: -I/usr/local/zed/include -L/usr/local/zed/lib -lsl_zed -lsl_ai
```

CMake integration:
```cmake
find_package(PkgConfig REQUIRED)
pkg_check_modules(ZED REQUIRED zed)
include_directories(${ZED_INCLUDE_DIRS})
link_directories(${ZED_LIBRARY_DIRS})
target_link_libraries(your_target ${ZED_LIBRARIES})
```

## Debhelper Packaging System

### Package Structure
- **debian/control** - Package metadata, dependencies, conflicts
- **debian/rules** - Build instructions (uses dh sequencer)
- **debian/changelog** - Version history in Debian format
- **debian/source/format** - Source package format (3.0 quilt)
- **debian/*.{postinst,prerm,postrm}** - Maintainer scripts

### Architecture Naming
- Uses Debian architecture names: `amd64` (not x86_64), `arm64` (not aarch64)
- Architecture detected via `dpkg --print-architecture`
- Important for package compatibility with Debian/Ubuntu systems

### Maintainer Scripts (Package Lifecycle)

**postinst.sh** - Post-installation script
1. Creates 'zed' group for SDK access control
2. Sets group ownership on `/usr/local/zed`
3. Updates library cache with `ldconfig`
4. Reloads and triggers udev rules for camera access
5. [Jetson only] Modifies nvargus-daemon for infinite camera timeout
6. [Jetson only] Enables zed_media_server_cli service
7. Displays post-installation instructions to user

**prerm.sh** - Pre-removal script
1. Prompts for AI model removal (interactive)
2. [Jetson only] Stops and disables zed_media_server_cli service
3. Removes AI models if user confirms

**postrm.sh** - Post-removal script
- **remove**: Basic cleanup, keeps configuration
- **purge**: Complete removal including:
  - AI models and optimization files
  - Broken symlinks in `/usr/local/bin`
  - 'zed' group (if empty)
  - Settings and resources directories

### Key Debhelper Variables (debian/rules)
- `$(CURDIR)`: Current source directory
- `$(DEB_DESTDIR)`: Staging directory for package contents (becomes `/` after install)
- `PKG_NAME`: Package name from debian/control (zed-sdk)
- `PKG_VERSION`: Version from debian/changelog
- `ZED_VERSION`: Extracted SDK version for substitution

## Docker Build Infrastructure

All platforms include Docker-based build environments for reproducible builds:

### Directory Structure
```
{version}/{platform}/docker/
├── Dockerfile.build         # Build environment definition
├── docker-build.sh          # Main build orchestration script
└── build-in-docker.sh       # Runs inside container
```

### Build Environment Images

**AMD64:**
- Base: `ubuntu:22.04`
- Tools: debhelper, dpkg-dev, devscripts, fakeroot, zstd, python3-dev
- Purpose: Clean Ubuntu 22.04 environment for x86_64 builds

**JP60 (Jetson):**
- Base: `nvcr.io/nvidia/l4t-tensorrt:r8.6.2.3-runtime` (or similar L4T base)
- Tools: Same as AMD64 plus L4T-specific dependencies
- Purpose: Jetson L4T environment with TensorRT support

### Host UID/GID Preservation
Docker containers run as host user to avoid permission issues:
```bash
--user "${HOST_UID}:${HOST_GID}"
```

This ensures:
- Output files owned by host user (not root)
- No permission denied errors when writing packages
- Build artifacts can be accessed by host user

### Temporary Build Directory
To avoid permission issues, builds use `/tmp` inside containers:
```bash
BUILD_DIR="/tmp/zed-build-$$"
```

This solves permission issues when the mounted `/build` directory parent is not writable by the container user.

## Build Process

### Docker Build Workflow
1. **Build Docker image** - Creates Ubuntu 22.04 (AMD64) or L4T (Jetson) environment
2. **Run build container** - Mounts source directory, runs as host UID/GID
3. **Execute dpkg-buildpackage** - Standard Debian package build inside container
4. **Copy output** - Package files copied to `output/` directory

### Debhelper Build Phases (debian/rules)

**override_dh_auto_clean:**
- Removes extracted SDK files and build artifacts

**override_dh_auto_build:**
- Downloads SDK `.run` installer if not present
- Extracts installer using `tail -n +718` and `zstdcat -d`
- Downloads Python wheel if not present
- Applies `python_shebang.patch` to fix Python shebangs

**override_dh_auto_install:**
Key installation steps:
1. Creates directory structure including `/usr/local/zed/settings`
2. Installs core SDK components:
   - Libraries (`.so` files) to `/usr/local/zed/lib`
   - Headers (`.h`, `.hpp`) to `/usr/local/zed/include`
   - Firmware to `/usr/local/zed/`
3. Sets up CMake configuration files for easy integration
4. Installs Python wheel using `pip install --no-deps --prefix=/usr/local`
5. Creates tool symlinks in `/usr/local/bin` (ZED_Explorer, ZED_Diagnostic, etc.)
6. Installs udev rules (`99-slabs.rules`) for camera permissions
7. Creates `/etc/ld.so.conf.d/001-zed.conf` for library path priority
8. [Jetson only] Installs systemd service files

### Build Commands

**Recommended (Docker build):**
```bash
cd v5.1.2/amd64/         # Choose version and platform
make docker-build        # Build in Docker container
```

Output: `output/zed-sdk_*.deb` and build metadata files

**Native build (requires Ubuntu 22.04):**
```bash
cd v5.1.2/amd64/
make build              # Builds using host dpkg-buildpackage
```

**Interactive debugging:**
```bash
make docker-shell       # Opens shell in build container
```

**All platforms follow the same pattern:**
- v4.2/{amd64,jp60}
- v5.0.5/{amd64,jp60}
- v5.1.2/{amd64,jp60}

## AI Model Optimization (v5.x)

The `zed_ai_optimizer` script (included in v5.0.5 and v5.1.2) provides comprehensive AI model management:

### Features
- **Platform detection:** Automatically detects Jetson/GPU/CPU
- **Model download:** Downloads models from StereoLabs servers
- **Platform-specific optimization:**
  - **Jetson (jp60):** NPU/DLA optimization for hardware acceleration
  - **Desktop (amd64):** CUDA/TensorRT GPU optimization
  - **Generic ARM (arm64):** CPU-based optimization
- **Progress tracking:** Colored output with progress indicators
- **Multiple operation modes:**
  - `--download`: Download models only
  - `--optimize`: Optimize existing models
  - `--clean`: Remove optimization files
  - `--status`: Check current model status

### Usage
```bash
sudo zed_ai_optimizer           # Download and optimize all models
sudo zed_ai_optimizer --status  # Check model status
sudo zed_ai_optimizer --help    # Show all options
```

**Note:** Optimization can take 30-60 minutes but only needs to be done once per system.

## Installation File Locations

### Core SDK
- **Libraries:** `/usr/local/zed/lib/`
- **Headers:** `/usr/local/zed/include/`
- **Resources:** `/usr/local/zed/resources/`
- **Firmware:** `/usr/local/zed/`
- **Settings:** `/usr/local/zed/settings/` (created during install)

### Python Bindings
- **Package:** `/usr/local/lib/python3.10/dist-packages/pyzed/`

### Tools and Executables
- **Symlinks:** `/usr/local/bin/` (ZED_Explorer, ZED_Diagnostic, etc.)
- **AI Models:** `/usr/local/zed/resources/` (after optimization)

### System Configuration
- **Library config:** `/etc/ld.so.conf.d/001-zed.conf`
- **Udev rules:** `/etc/udev/rules.d/99-slabs.rules`
- **[Jetson] Service:** `/lib/systemd/system/zed_media_server_cli.service`

## Testing and Validation

### Build Test Suite

The repository includes a comprehensive build test suite in the top-level `tests/` directory:

```
tests/
├── Makefile                     # Test orchestration
└── README.md                    # Test documentation
```

The test suite runs `docker-build` for all versions and platforms, verifying that:
- Docker images build successfully
- Packages build without errors
- Output `.deb` files are created
- Package metadata is correct

### Running Tests
```bash
cd tests/

# Test all versions and platforms
make all

# Test specific version
make test-v5.1.2
make test-v5.0.5
make test-v4.2

# Check build status
make status

# Clean built packages
make clean
```

Example output:
```
========================================
Build Status Summary
========================================

v4.2/amd64:          ✓ Built (65M)
v4.2/jp60:           ✓ Built (55M)
v5.0.5/amd64:        ✓ Built (72M)
v5.0.5/jp60:         ✓ Built (32M)
v5.1.2/amd64:        ✓ Built (73M)
v5.1.2/jp60:         ✓ Built (32M)
```

### Manual Installation Testing
```bash
# Install the package
sudo dpkg -i zed-sdk*.deb

# Fix any dependency issues
sudo apt-get install -f

# Verify installation
ldconfig -p | grep zed
which ZED_Diagnostic
ls -la /usr/local/zed/
python3 -c "import pyzed.sl as sl; print(sl.__version__)"
```

### Jetson-Specific Testing
```bash
# Check service status
systemctl status zed_media_server_cli

# Verify nvargus-daemon modification
grep enableCamInfiniteTimeout /etc/systemd/system/nvargus-daemon.service.d/override.conf

# Test camera functionality
ZED_Diagnostic
```

## Dependencies by Platform

### Common Dependencies (All Platforms)
- **Core:** `libjpeg-turbo8`, `libusb-1.0-0`, `libopenblas-dev`, `libarchive-dev`
- **Qt5:** `qtbase5-dev`, `libqt5opengl5`, `libqt5svg5`
- **OpenGL:** `libglew-dev`, `freeglut3-dev`, `mesa-utils`
- **Python:** `python3-numpy`, `python3-requests`, `python3-pyqt5`

### Platform-Specific Dependencies

**AMD64:**
- CUDA 12.8 or higher (from NVIDIA)
- Compatible NVIDIA drivers (535+)
- TensorRT 10.9 (optional, for AI models)

**ARM64:**
- Generic ARM libraries
- No specific GPU requirements
- CPU-only AI optimization

**JP60 (Jetson):**
- `nvidia-l4t-camera` (L4T camera stack)
- **Conflicts:** `libv4l-dev` (breaks hardware encoding)
- JetPack 6.0 (L4T 36.4)

## Troubleshooting

### Missing Python Package
**Symptom:** `import pyzed.sl` fails
**Solution:**
- Ensure Python wheel is downloaded and installed
- Check `/usr/local/lib/python3.10/dist-packages/pyzed/`
- Reinstall package: `sudo apt reinstall zed-sdk`

### Jetson Hardware Encoding Issues
**Symptom:** Video encoding/decoding fails on Jetson
**Solution:**
- Verify `libv4l-dev` is NOT installed: `dpkg -l | grep libv4l-dev`
- Package explicitly conflicts with it
- Remove if present: `sudo apt remove libv4l-dev`

### Camera Timeout on Jetson
**Symptom:** Camera detection timeout after 30 seconds
**Solution:**
- Automatically fixed via nvargus-daemon modification
- Verify: `systemctl show nvargus-daemon | grep Environment`
- Should see `enableCamInfiniteTimeout=1`

### AI Model Issues
**Symptom:** AI features don't work or crash
**Solution:**
- Check model status: `sudo zed_ai_optimizer --status`
- Clean and re-optimize: `sudo zed_ai_optimizer --clean && sudo zed_ai_optimizer`
- Ensure sufficient disk space (~2GB required)

### Library Not Found
**Symptom:** `error while loading shared libraries: libsl_zed.so`
**Solution:**
- Run `sudo ldconfig` to update library cache
- Check `/etc/ld.so.conf.d/001-zed.conf` exists
- Verify libraries: `ldconfig -p | grep zed`

## Contributing

### Version Selection
When contributing, choose the appropriate version:
- **v5.1.2**: Active development, latest features
- **v5.0.5**: Stable, maintenance mode
- **v4.2**: Legacy, critical fixes only

### Code Standards
1. Choose the correct variant directory (`amd64/`, `jp60/`)
2. Follow standard debhelper conventions (debian/control, debian/rules)
3. Use Debian architecture names (`amd64`, not `x86_64`)
4. Test builds using Docker: `make docker-build`
5. Update debian/changelog when changing package version
6. Ensure all platforms have consistent structure (debian/, docker/, Makefile, README.md, zed.pc.in)

### Documentation Markers
Document platform-specific changes in ROADMAP.md or commit messages:
- 🌐 All platforms
- 🖥️ AMD64 specific
- 🔧 ARM64 specific
- 🚀 JP60/Jetson specific

### Testing Checklist
- [ ] Package builds without errors
- [ ] Installation completes successfully
- [ ] Python bindings import correctly
- [ ] Tools are accessible via PATH
- [ ] AI optimizer runs (if applicable)
- [ ] Removal/purge works cleanly

## Known Issues

### All Versions
1. Users must manually join 'video' group for camera access (security consideration)
2. Initial AI optimization takes 30-60 minutes (one-time process, v5.x only)
3. Docker builds on ARM64 platforms may be slow on x86_64 hosts due to QEMU emulation

### v4.2 Specific
1. Uses older AI model download script (zed_download_ai_models) instead of zed_ai_optimizer
2. CUDA 12.0 support only (newer versions use CUDA 12.8)

## Migration Guide

### From makedeb to debhelper (Completed December 2024)

The repository was converted from makedeb (PKGBUILD-based) to standard debhelper:

**What changed:**
- Build system: `makedeb` → `dpkg-buildpackage`
- Package files: `PKGBUILD` → `debian/{control,rules,changelog}`
- Build method: Native → Docker-based (recommended)
- All platforms now use consistent structure

**For existing users:**
- Old .deb packages still work - no reinstallation needed
- New builds use same package name (`zed-sdk`)
- Installation paths unchanged
- To rebuild from source, use `make docker-build` instead of `makedeb`

### Upgrading Between Versions
To upgrade from one ZED SDK version to another:

```bash
# Remove old version
sudo apt remove zed-sdk        # or sudo apt purge zed-sdk

# Install new version
cd v5.0.5/amd64/               # or your platform
make build
sudo dpkg -i zed-sdk*.deb
sudo apt -f install
```

## Conversion History

### December 2024: makedeb to debhelper Migration

The repository was converted from makedeb (PKGBUILD-based) to standard debhelper:

**Platforms converted:**
1. v5.1.2/jp60 - First conversion, established pattern
2. v5.0.5/jp60 - Applied same pattern
3. v5.0.5/amd64 - Extended to AMD64 platform
4. v4.2/jp60 - Legacy platform conversion
5. v4.2/amd64 - Completed AMD64 coverage
6. v5.1.2/amd64 - Latest version AMD64 support

**Key improvements:**
- Added Docker build infrastructure to all platforms
- Unified directory structure (debian/, docker/, Makefile, README.md)
- Added pkg-config support (zed.pc.in) to v5.x versions
- Created top-level test suite (tests/) for build validation
- Fixed permission issues with temporary build directories
- Standardized documentation across all platforms
- Removed legacy makedeb files and patterns

**Issues fixed:**
- Permission denied errors when building .deb in Docker (#1)
- Garbled ANSI codes in test output (#2)
- Missing docker-build targets in some platforms (#3)
- Inconsistent .gitignore patterns (#4)

## Future Development

Priority tasks:
1. **CI/CD Pipeline:** Automated builds and testing for all platforms
2. **GitHub Actions:** Automated build verification on push
3. **Runtime-only Package:** Smaller package without development files
4. **Split Packages:** Separate core, dev, python, tools, ai packages
5. **Dependency Management:** Better handling of TensorRT/cuDNN versions
6. **Settings Preservation:** Maintain user settings during upgrades
7. **Multi-version Support:** Allow multiple SDK versions installed simultaneously
8. **ARM64 Generic Support:** Add v5.1.2/arm64 platform

See [ROADMAP.md](ROADMAP.md) for detailed planning.

---

**Last updated:** December 2025
**Maintainer:** Hsiang-Jui Lin <jerry73204@gmail.com>
**Repository:** https://github.com/jerry73204/zed-sdk-debian-package
