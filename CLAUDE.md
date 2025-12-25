# ZED SDK Debian Package - Technical Documentation

## Project Overview

This project creates Debian packages for the StereoLabs ZED SDK using makedeb's PKGBUILD system. It provides packaging scripts for multiple ZED SDK versions (4.2, 5.0, 5.0.5) across different platforms (x86_64/AMD64, ARM64, and NVIDIA Jetson) by extracting content from the official ZED SDK `.run` installers and repackaging them into `.deb` packages suitable for Debian/Ubuntu systems.

## Repository Structure

The repository uses a **version-based organization** where each ZED SDK version is self-contained:

```
zed-sdk-debian-package/
├── v4.2/                     # ZED SDK 4.2 (Legacy)
│   ├── x86_64/              # Split packages: zed-sdk + python3-pyzed
│   ├── jp60/                # JetPack 6.0 / L4T 36.3
│   └── shared/              # Shared files between architectures
│
├── v5.0/                     # ZED SDK 5.0 (Maintenance)
│   ├── x86_64/              # Split packages: zed-sdk + python3-pyzed
│   ├── jp60/                # JetPack 6.0 / L4T 36.3
│   └── shared/
│
└── v5.0.5/                   # ZED SDK 5.0.5 (Latest, Active Development)
    ├── amd64/               # Consolidated package (SDK + Python)
    ├── arm64/               # Generic ARM64 support
    ├── jp60/                # JetPack 6.0 / L4T 36.4
    └── tests/               # Docker-based test suite
```

## Version Comparison

### v4.2 & v5.0 (Legacy Structure)

**Package Strategy:** Split packaging
- Separate `zed-sdk` package (core SDK)
- Separate `python3-pyzed` package (Python bindings)

**Architecture Naming:**
- `x86_64/` - Desktop/Server systems
- `jp60/` - NVIDIA Jetson (JetPack 6.0)

**Features:**
- Basic `zed_download_ai_models` script
- Manual Python package installation required
- L4T 36.3 for Jetson

**Build:** Each architecture has nested package directories

### v5.0.5 (Current Structure)

**Package Strategy:** Consolidated packaging
- Single `zed-sdk` package includes both SDK and Python bindings

**Architecture Naming:**
- `amd64/` - Desktop/Server x86_64 systems
- `arm64/` - Generic ARM64 systems (new!)
- `jp60/` - NVIDIA Jetson (JetPack 6.0)

**Features:**
- Advanced `zed_ai_optimizer` script with platform detection
- Comprehensive Docker-based test suite
- L4T 36.4 for Jetson (JetPack 6.0 GA)
- Improved dependency management

**Build:** Flat architecture directories with all files at top level

## Technology Stack

- **makedeb**: Creates Debian packages from Arch-inspired PKGBUILD scripts
- **Bash scripting**: Package lifecycle management (postinst, prerm, postrm)
- **systemd**: Service management on Jetson devices
- **Python pip**: Python wheel package installation
- **Docker**: Testing and validation (v5.0.5)

## Platform Variants (v5.0.5)

### AMD64 (Desktop/Server)
- **Target:** x86_64 desktop and server systems with NVIDIA GPUs
- **SDK:** `ZED_SDK_Ubuntu22_cuda12.8_tensorrt10.9_v5.0.5.zstd.run`
- **Python wheel:** `pyzed-5.0-cp310-cp310-linux_x86_64.whl`
- **Optimization:** CUDA GPU acceleration via TensorRT
- **CUDA:** 12.8, TensorRT 10.9

### ARM64 (Generic ARM)
- **Target:** Generic ARM64 systems (non-Jetson)
- **SDK:** Same as AMD64 but for ARM architecture
- **Python wheel:** `pyzed-5.0-cp310-cp310-linux_aarch64.whl`
- **Optimization:** CPU-based optimization fallback
- **Note:** No GPU acceleration

### JP60 (NVIDIA Jetson)
- **Target:** NVIDIA Jetson platforms (Orin, Xavier, etc.)
- **SDK:** `ZED_SDK_Tegra_L4T36.4_v5.0.5.zstd.run`
- **Python wheel:** `pyzed-5.0-cp310-cp310-linux_aarch64.whl`
- **Optimization:** NPU/DLA hardware acceleration
- **Special features:**
  - Conflicts with `libv4l-dev` (breaks hardware encoding)
  - Includes `nvidia-l4t-camera` dependency
  - Configures `nvargus-daemon` for multiple cameras
  - Installs and enables `zed_media_server_cli.service`

## makedeb PKGBUILD System

### Architecture Naming
- Uses Debian architecture names: `amd64` (not x86_64), `arm64` (not aarch64)
- Architecture detected via `dpkg --print-architecture`
- Important for package compatibility with Debian/Ubuntu systems

### Package Scripts (Debian Maintainer Scripts)

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

### Key PKGBUILD Variables
- `${srcdir}`: Temporary source directory for extraction
- `${pkgdir}`: Staging directory for package contents (becomes `/` after install)
- `${pkgname}`: Package name (e.g., zed-sdk)
- `${pkgver}`: SDK version (e.g., 5.0.5)
- `${pkgrel}`: Package release number

## Build Process (v5.0.5)

### 1. prepare() Function
- Extracts the self-extracting `.run` installer at line 718
- Uses `zstdcat -d` for zstd decompression and `tar -xf` for extraction
- Applies `python_shebang.patch` to fix Python script shebangs (#!/usr/bin/env python3)

### 2. package() Function
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

**v5.0.5:**
```bash
cd v5.0.5/amd64/  # or arm64/, or jp60/
make build        # Downloads SDK, builds package
```

**v4.2 & v5.0:**
```bash
cd v5.0/x86_64/zed-sdk/      # or jp60/zed-sdk/
make              # Build main SDK package

cd v5.0/x86_64/python3-pyzed/  # or jp60/python3-pyzed/
make              # Build Python package
```

## AI Model Optimization (v5.0.5)

The `zed_ai_optimizer` script provides comprehensive AI model management:

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

## Testing and Validation (v5.0.5)

### Docker-based Test Suite

The v5.0.5 branch includes a comprehensive test suite:

```
v5.0.5/tests/
├── docker/
│   ├── amd64/                   # AMD64 test containers
│   ├── arm64/                   # ARM64 test containers
│   └── common/                  # Shared scripts
├── scripts/
│   ├── build-test-images.sh     # Build test Docker images
│   ├── run-comparison.sh        # Compare .deb vs .run install
│   └── generate-report.sh       # Generate test reports
└── Makefile                     # Test automation
```

### Running Tests
```bash
cd v5.0.5/tests/
make build-images              # Build test Docker images
make test-amd64                # Test AMD64 package
make test-arm64                # Test ARM64 package
make report                    # Generate comparison report
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
- **v5.0.5**: Active development, new features
- **v5.0**: Maintenance only, bug fixes
- **v4.2**: Legacy, critical fixes only

### Code Standards
1. Choose the correct variant directory (`amd64/`, `arm64/`, `jp60/`)
2. Follow makedeb syntax (Debian-style, not pure Arch PKGBUILD)
3. Use Debian architecture names (`amd64`, not `x86_64`)
4. Test on the specific platform variant
5. Update checksums when changing source files (use `makedeb --printsrcinfo`)

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
1. Package may contain references to `$srcdir` and `$pkgdir` in Python cache files (non-critical, doesn't affect functionality)
2. Users must manually join 'video' group for camera access (security consideration)
3. Initial AI optimization takes 30-60 minutes (one-time process)

### v4.2 & v5.0 Specific
1. Python package must be installed separately
2. No automated testing framework

## Migration Guide

### From Branches to Version Directories

**Old (branch-based):**
```bash
git clone -b v5.0.5 https://github.com/.../zed-sdk-debian-package.git
cd zed-sdk-debian-package/amd64/
```

**New (version directory-based):**
```bash
git clone https://github.com/.../zed-sdk-debian-package.git
cd zed-sdk-debian-package/v5.0.5/amd64/
```

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

## Future Development

Priority tasks:
1. **CI/CD Pipeline:** Automated builds and testing
2. **Runtime-only Package:** Smaller package without development files
3. **Split Packages:** Separate core, dev, python, tools, ai packages
4. **Dependency Management:** Better handling of TensorRT/cuDNN versions
5. **Settings Preservation:** Maintain user settings during upgrades
6. **Multi-version Support:** Allow multiple SDK versions installed simultaneously

See [ROADMAP.md](ROADMAP.md) for detailed planning.

---

**Last updated:** December 2025
**Maintainer:** Hsiang-Jui Lin <jerry73204@gmail.com>
**Repository:** https://github.com/jerry73204/zed-sdk-debian-package
