# ZED SDK Debian Package - Technical Documentation

## Project Overview

This project creates Debian packages for the StereoLabs ZED SDK using makedeb's PKGBUILD system. It provides three platform-specific variants (AMD64, ARM64, and Jetson) by extracting content from the official ZED SDK `.run` installers and repackaging them into `.deb` packages suitable for Debian/Ubuntu systems.

## Current Version

- **SDK Version**: 5.0.5
- **Package Release**: 1
- **CUDA Version**: 12.8
- **TensorRT Version**: 10.9
- **L4T Version (Jetson)**: 36.4

## Technology Stack

- **makedeb**: A tool that creates Debian packages from Arch-inspired PKGBUILD scripts
- **Bash scripting**: For package lifecycle management
- **systemd**: For service management on Jetson devices
- **Python pip**: For Python wheel package installation

## Project Structure

```
.
├── amd64/                    # Desktop/Server x86_64 variant
│   ├── PKGBUILD             # AMD64-specific build script
│   ├── postinst.sh          # Post-installation setup
│   ├── prerm.sh             # Pre-removal cleanup
│   ├── postrm.sh            # Post-removal cleanup
│   └── ...                  # Other support files
├── arm64/                    # Generic ARM64 variant
│   ├── PKGBUILD             # ARM64-specific build script
│   └── ...                  # Similar structure to amd64
├── jetpack/                  # NVIDIA Jetson variant
│   ├── PKGBUILD             # Jetson-specific build script
│   └── ...                  # Similar structure + service files
├── python_shebang.patch      # Common patch for Python scripts
├── zed_ai_optimizer          # AI model optimization script
├── Makefile                  # Root build automation
├── BUILD_VARIANTS.md         # Platform-specific build guide
├── ROADMAP.md               # Development roadmap
└── README.md                # User documentation
```

## Three Platform Variants

### AMD64 (Desktop/Server)
- Target: x86_64 desktop and server systems with NVIDIA GPUs
- SDK: `ZED_SDK_Ubuntu22_cuda12.8_tensorrt10.9_v5.0.5.zstd.run`
- Python wheel: `pyzed-5.0-cp310-cp310-linux_x86_64.whl`
- Optimization: CUDA GPU acceleration via TensorRT

### ARM64 (Generic ARM)
- Target: Generic ARM64 systems (non-Jetson)
- SDK: Same as AMD64 but for ARM architecture
- Python wheel: `pyzed-5.0-cp310-cp310-linux_aarch64.whl`
- Optimization: CPU-based optimization fallback

### Jetpack (NVIDIA Jetson)
- Target: NVIDIA Jetson platforms (Orin, Xavier, etc.)
- SDK: `ZED_SDK_Tegra_L4T36.4_v5.0.5.zstd.run`
- Python wheel: Same as ARM64
- Optimization: NPU/DLA hardware acceleration
- Special features:
  - Conflicts with `libv4l-dev` (breaks hardware encoding)
  - Includes `nvidia-l4t-camera` dependency
  - Configures `nvargus-daemon` for multiple cameras
  - Installs and enables `zed_media_server_cli.service`

## makedeb PKGBUILD Specifics

### Architecture Naming
- Uses Debian architecture names: `amd64` (not x86_64), `arm64` (not aarch64)
- Architecture detected via `dpkg --print-architecture`

### Package Scripts
- `postinst`: Post-installation script (creates group, updates ldconfig, configures services)
- `prerm`: Pre-removal script (stops services, removes AI models if requested)
- `postrm`: Post-removal script (cleanup on purge, group removal)

### Key Build Variables
- `${srcdir}`: Temporary source directory for extraction
- `${pkgdir}`: Staging directory for package contents
- `${pkgname}`: Package name (zed-sdk or zed-sdk-jetpack)
- `${pkgver}`: SDK version (5.0.5)

## Build Process

### 1. prepare() Function
- Extracts the self-extracting `.run` installer at line 718
- Uses `zstdcat` for decompression and `tar` for extraction
- Applies `python_shebang.patch` to fix Python script shebangs

### 2. package() Function
Key installation steps:
- Creates directory structure including `/usr/local/zed/settings`
- Installs core SDK components (libraries, headers, firmware)
- Sets up CMake configuration files
- Installs Python wheel using pip with `--no-deps`
- Creates tool symlinks in `/usr/local/bin`
- Installs udev rules (99-slabs.rules)
- Creates `/etc/ld.so.conf.d/001-zed.conf` for library path priority
- [Jetson only] Installs systemd service files

## Installation Scripts

### postinst.sh (All Variants)
1. Creates 'zed' group for SDK access control
2. Sets group ownership on `/usr/local/zed`
3. Updates library cache with `ldconfig`
4. Reloads and triggers udev rules
5. [Jetson only] Modifies nvargus-daemon for infinite camera timeout
6. [Jetson only] Enables zed_media_server_cli service
7. Displays post-installation instructions

### prerm.sh
1. Prompts for AI model removal (interactive)
2. [Jetson only] Stops and disables zed_media_server_cli service
3. Removes AI models if requested

### postrm.sh
Handles both `remove` and `purge` operations:
- **remove**: Basic cleanup, keeps configuration
- **purge**: Complete removal including:
  - AI models and optimization files
  - Broken symlinks in `/usr/local/bin`
  - 'zed' group (if empty)
  - Settings and resources directories

## AI Model Optimization

The `zed_ai_optimizer` script provides comprehensive AI model management:

### Features
- Platform detection (Jetson/GPU/CPU)
- Model download from StereoLabs servers
- Platform-specific optimization:
  - **Jetson**: NPU/DLA optimization for hardware acceleration
  - **Desktop**: CUDA/TensorRT GPU optimization
  - **Generic ARM**: CPU-based optimization
- Progress tracking with colored output
- Multiple operation modes:
  - `--download`: Download models only
  - `--optimize`: Optimize existing models
  - `--clean`: Remove optimization files
  - `--status`: Check current model status

### Usage
```bash
sudo zed_ai_optimizer          # Download and optimize all models
sudo zed_ai_optimizer --status  # Check model status
sudo zed_ai_optimizer --help    # Show all options
```

Note: Optimization can take 30-60 minutes but only needs to be done once.

## Recent Updates (September 2025)

### Completed Features
1. **Version Update**: Updated from SDK 4.2 to 5.0.5
2. **Python Package Fix**: Added Python wheel installation to PKGBUILD
3. **AI Optimizer**: Created comprehensive optimization script
4. **Three-Way Split**: Separated into platform-specific variants
5. **Group Management**: Added 'zed' group creation and removal
6. **Settings Directory**: Created `/usr/local/zed/settings` during installation
7. **Priority Library Path**: Renamed to `001-zed.conf` for load priority
8. **Service File Fixes**: Corrected Jetson PKGBUILD script references

### Known Issues
1. Package contains references to `$srcdir` and `$pkgdir` in Python cache (non-critical)
2. Users must manually join 'video' group (security consideration)
3. Initial AI optimization takes 30-60 minutes (one-time process)

## Build Commands

### Building Packages
```bash
# Build all variants
make all

# Build specific variant
make amd64
make arm64
make jetpack

# Clean build artifacts
make clean-all

# Show help
make help
```

### Using makedeb Directly
```bash
cd amd64/  # or arm64/ or jetpack/
makedeb -s  # Build with dependency installation
```

## Testing and Validation

### Installation Testing
```bash
# Install the package
sudo dpkg -i zed-sdk*.deb

# Fix any dependency issues
sudo apt-get install -f

# Verify installation
ldconfig -p | grep zed
which ZED_Diagnostic
ls -la /usr/local/zed/
```

### Jetson-Specific Testing
```bash
# Check service status
systemctl status zed_media_server_cli

# Verify nvargus-daemon modification
grep enableCamInfiniteTimeout /etc/systemd/system/nvargus-daemon.service

# Test camera functionality
ZED_Diagnostic
```

## Dependencies by Platform

### Common Dependencies
- Core: `libjpeg-turbo8`, `libusb-1.0-0`, `libopenblas-dev`
- Qt5: `qtbase5-dev`, `libqt5opengl5`, `libqt5svg5`
- OpenGL: `libglew-dev`, `freeglut3-dev`
- Python: `python3-numpy`, `python3-requests`, `python3-pyqt5`

### Platform-Specific
- **AMD64**: Expects CUDA 12.8 and compatible NVIDIA drivers
- **ARM64**: Generic ARM libraries, no specific GPU requirements
- **Jetson**: `nvidia-l4t-camera`, conflicts with `libv4l-dev`

## Troubleshooting

### Missing Python Package
- Ensure Python wheel is downloaded and installed via pip
- Check `/usr/local/lib/python3.10/dist-packages/` for pyzed

### Jetson Hardware Encoding Issues
- Verify `libv4l-dev` is NOT installed
- Package explicitly conflicts with it to prevent issues

### Camera Timeout on Jetson
- Automatically fixed via nvargus-daemon modification
- Check with: `systemctl show nvargus-daemon | grep Environment`

### AI Model Issues
- Run `sudo zed_ai_optimizer --status` to check model state
- Use `--clean` then re-optimize if models are corrupted
- Ensure sufficient disk space (~2GB required)

## Contributing

When modifying the project:
1. Choose the correct variant directory (amd64/arm64/jetpack)
2. Follow makedeb syntax (not pure Arch PKGBUILD)
3. Use Debian architecture names
4. Test the specific platform variant
5. Update checksums when changing source files
6. Document platform-specific changes in ROADMAP.md with markers:
   - 🌐 All platforms
   - 🖥️ AMD64 specific
   - 🔧 ARM64 specific
   - 🚀 Jetpack specific

## Next Steps for Future Sessions

Priority tasks from ROADMAP.md:
1. Automated testing and CI/CD pipeline
2. Runtime-only package variant (without dev tools)
3. Split packages (core, dev, python, tools, ai)
4. TensorRT/cuDNN dependency handling
5. Settings preservation during upgrades

---

*Last updated: September 2025*
*Maintainer: Hsiang-Jui Lin <jerry73204@gmail.com>*