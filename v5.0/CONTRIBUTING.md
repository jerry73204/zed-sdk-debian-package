# Contributing to ZED SDK Debian Package

This document provides information for developers who want to build, modify, or contribute to the ZED SDK Debian packages.

## Overview

This project repackages the official StereoLabs ZED SDK into proper Debian packages using makedeb PKGBUILD scripts. The packages are designed to integrate cleanly with Debian/Ubuntu package management while maintaining compatibility with the official SDK.

**Status:** Production-ready. All critical features have been implemented.

## Prerequisites for Building

### Install makedeb

```bash
# Install makedeb from official repository
wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1> /dev/null

echo "deb [signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg arch=all] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | \
    sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list

sudo apt update
sudo apt install makedeb
```

### Build Dependencies

```bash
# For x86_64 systems
sudo apt install zstd tar

# For Jetson systems (same)
sudo apt install zstd tar
```

## Building Packages

### Using Makefile (Recommended)

Each package directory contains a Makefile for convenient building:

```bash
# Build x86_64 main SDK package
cd x86_64/zed-sdk
make                    # Build the package
make clean              # Clean build artifacts

# Build x86_64 Python bindings
cd x86_64/python3-pyzed
make

# Build Jetson main SDK package
cd jetson/zed-sdk
make

# Build Jetson Python bindings
cd jetson/python3-pyzed
make
```

### Using makedeb Directly

```bash
cd x86_64/zed-sdk

# Build package
makedeb

# Build and install
makedeb -si
```

### Build Output

Built packages will be in the parent directory (e.g., `x86_64/`):
- `zed-sdk_4.2-1_amd64.deb` or `zed-sdk_4.2-1_arm64.deb`
- `python3-pyzed_4.2-1_amd64.deb` or `python3-pyzed_4.2-1_arm64.deb`

## Repository Architecture

### Directory Structure

```
makedeb-zed-sdk/
├── README.md                    # End-user documentation
├── CONTRIBUTING.md              # This file
├── missing-features.md          # Internal: Feature analysis and implementation tracking
├── shared/                      # Shared files for both architectures
│   ├── python_shebang.patch     # Fix Python shebangs in SDK scripts
│   └── zed_download_ai_models   # Script for AI model download/optimization
├── x86_64/                      # x86_64/Desktop builds
│   ├── zed-sdk/                 # Main SDK package
│   │   ├── PKGBUILD             # Package build script
│   │   ├── Makefile             # Convenience wrapper
│   │   ├── postinst.sh          # Post-installation script
│   │   ├── prerm.sh             # Pre-removal script
│   │   └── postrm.sh            # Post-removal script
│   └── python3-pyzed/           # Python bindings package
│       ├── PKGBUILD
│       └── Makefile
└── jetson/                      # Jetson/ARM64 builds
    ├── zed-sdk/                 # Main SDK package
    │   ├── PKGBUILD
    │   ├── Makefile
    │   ├── postinst.sh
    │   ├── prerm.sh
    │   └── postrm.sh
    └── python3-pyzed/           # Python bindings package
        ├── PKGBUILD
        └── Makefile
```

### Why Separate x86_64 and Jetson Builds?

The architectures have significantly different requirements:

| Aspect              | x86_64               | Jetson                      |
|---------------------|----------------------|-----------------------------|
| **Architecture**    | amd64                | arm64                       |
| **CUDA Source**     | System CUDA 12.1+    | JetPack/L4T 36.3            |
| **AI Libraries**    | From NVIDIA apt repo | Included in JetPack         |
| **SDK URL**         | `cu12/ubuntu22`      | `l4t36.3/jetsons`           |
| **Media Server**    | Not included         | Included + systemd service  |
| **GMSL Drivers**    | Not applicable       | May be included for ZED X   |
| **Hardware Config** | None                 | nvargus-daemon modification |

This separation provides:
- Cleaner maintenance and testing
- Architecture-specific optimizations
- Reduced package size (no unnecessary files)
- Clear documentation per platform

## Package Details

### Main Package: zed-sdk

**What it includes:**
- ZED SDK libraries (`/usr/local/zed/lib/`)
- Headers for development (`/usr/local/zed/include/`)
- SDK tools (ZED_Explorer, ZED_Diagnostic, etc.)
- Sample code (`/usr/local/zed/samples/`)
- Firmware files (`/usr/local/zed/firmware/`)
- CMake configuration files
- udev rules for ZED cameras
- License documentation

**What it does NOT include:**
- AI models (downloaded via `zed_download_ai_models`)
- Python bindings (separate `python3-pyzed` package)
- Bundled AI libraries on x86_64 (uses system packages)

### Python Bindings: python3-pyzed

**What it includes:**
- Python 3 bindings for ZED SDK
- Installed via pip from official wheel

**Dependencies:**
- Depends on `zed-sdk`
- Depends on `python3`, `python3-numpy`
- Marked as "Recommends" in main package (optional but suggested)

### Multi-User Support

The package implements proper multi-user access:

**User Groups:**
- `zed` group: Created for multi-user SDK access
- `video` group: Required for camera access

**File Permissions:**
- `/usr/local/zed/`: Group ownership set to `zed`, mode 775
- Settings directory is group-writable for calibration file storage

**Installation behavior:**
- Creates `zed` group if it doesn't exist
- Adds installing user to both `zed` and `video` groups
- User must log out/in for group changes to take effect

### Settings Directory Preservation

The `/usr/local/zed/settings/` directory stores important user data:
- Camera calibration files (e.g., `SN12345678.conf`)
- Firmware update tracking (`.updates`)

**During package upgrades:**
- Directory structure is owned by package (upgraded)
- User files are NOT owned by package (preserved automatically)
- No manual backup needed - dpkg handles this correctly

This is superior to the official installer which uses manual backup/restore.

## Key Differences from Official Installer

### 1. AI Dependencies (x86_64 Only)

**Official installer:**
- Bundles cuDNN 8.9.7 (~1.2GB) and TensorRT 8.6.1 (~1.2GB)
- Copies to `/usr/local/cuda/lib64/` and `/usr/local/cuda/include/`
- Not tracked by package manager
- Potential conflicts with system installations

**Our approach:**
- Declares dependencies on NVIDIA apt packages
- Uses system-installed libraries in `/usr/lib/x86_64-linux-gnu/`
- Properly tracked by dpkg/apt
- Saves ~2.4GB in package size
- No files written to `/usr/local/cuda/`

**Technical details:**
- ZED SDK uses `dlopen()` to load AI libraries at runtime
- Standard library search paths work correctly
- No patching or modifications needed

### 2. Python API Installation

**Official installer:**
- Runs `get_python_api.py` during installation
- Integrates Python installation into main package

**Our approach:**
- Separate `python3-pyzed` package
- Clean separation of concerns
- Optional installation (recommended but not required)
- Better dependency tracking

### 3. Settings/Resources Backup

**Official installer:**
- Manually backs up to `/tmp/zed_previous`
- Uses `rm -rf /usr/local/zed` then restores

**Our approach:**
- No manual backup needed
- Debian package manager preserves non-owned files automatically
- More reliable and follows Debian best practices

**Note:** The `resources/` directory doesn't exist in SDK 4.2 - the installer backup code is legacy/non-functional.

### 4. User Group Management

**Official installer:**
- Creates groups and adds users
- Manual setup in shell script

**Our approach:**
- Same functionality via postinst.sh
- Proper cleanup in postrm.sh (removes group if empty)
- Follows Debian maintainer script conventions

### 5. Jetson-Specific Changes

**Removed (not needed for JP6.0/L4T 36.3):**
- V4L2 symlink creation (only needed for old JP4.3)
- CUDA stubs folder rename (questionable practice, unclear benefit)

**Kept:**
- GMSL drivers installation (if present)
- nvargus-daemon configuration (camera timeout)
- Media server systemd service

## Testing

### Before Release

Test on clean systems:

**x86_64 testing:**
```bash
# Fresh Ubuntu 22.04 system with CUDA 12.1+
sudo apt install ./zed-sdk_4.2-1_amd64.deb
groups  # Verify zed and video membership
# Log out and back in
ZED_Diagnostic
# Test with ZED camera if available
```

**Jetson testing:**
```bash
# Fresh Jetson with JetPack 6.0
sudo apt install ./zed-sdk_4.2-1_arm64.deb
groups  # Verify zed and video membership
# Log out and back in
systemctl status zed_media_server_cli  # Should be active
systemctl status nvargus-daemon  # Check config applied
ZED_Diagnostic
```

### Multi-User Testing

```bash
# Install as user A
sudo apt install ./zed-sdk_4.2-1_amd64.deb

# Switch to user B
sudo usermod -aG zed userB
# User B logs in
cd /usr/local/zed/settings
touch test_file  # Should work (group writable)
```

### Upgrade Testing

```bash
# Install old version
sudo apt install ./zed-sdk_4.1-1_amd64.deb

# Create test calibration file
echo "test" | sudo tee /usr/local/zed/settings/TEST.conf

# Upgrade
sudo apt install ./zed-sdk_4.2-1_amd64.deb

# Verify file preserved
cat /usr/local/zed/settings/TEST.conf  # Should still exist
```

## Release Process

1. **Update version** in PKGBUILD files if needed:
   ```bash
   pkgver=4.2
   pkgrel=1
   ```

2. **Update checksums** if source files changed:
   ```bash
   cd x86_64/zed-sdk
   makedeb --geninteg  # Generates new sha256sums
   # Copy output to PKGBUILD sha256sums array
   ```

3. **Build all packages:**
   ```bash
   # x86_64
   cd x86_64/zed-sdk && make && cd ../..
   cd x86_64/python3-pyzed && make && cd ../..

   # Jetson
   cd jetson/zed-sdk && make && cd ../..
   cd jetson/python3-pyzed && make && cd ../..
   ```

4. **Test packages** (see Testing section above)

5. **Create GitHub release:**
   - Tag: `v4.2-1`
   - Upload all 4 .deb files
   - Include installation instructions

6. **Update README.md** download links if needed

## Common Issues

### Build fails with "Unable to download file"

The ZED SDK download URLs sometimes change or require authentication. Check:
- Is the URL in PKGBUILD correct?
- Is the version number correct?
- Try downloading manually with wget to see the error

### Checksum mismatch

The run file was updated by StereoLabs. Download the new file and update checksums:
```bash
makedeb --geninteg
```

### Python bindings build fails

Check that the main SDK package is installed first, as python3-pyzed depends on it.

## Useful Commands

```bash
# Check package contents
dpkg -L zed-sdk

# Check package info
apt show zed-sdk

# List files in .deb without installing
dpkg-deb -c zed-sdk_4.2-1_amd64.deb

# Extract .deb contents to inspect
dpkg-deb -x zed-sdk_4.2-1_amd64.deb /tmp/extracted/

# Check package dependencies
dpkg-deb -I zed-sdk_4.2-1_amd64.deb | grep Depends

# Verify package can be installed
sudo apt install --dry-run ./zed-sdk_4.2-1_amd64.deb
```

## Additional Resources

- **makedeb Documentation:** https://docs.makedeb.org/
- **ZED SDK Documentation:** https://www.stereolabs.com/docs/
- **NVIDIA CUDA Documentation:** https://docs.nvidia.com/cuda/
- **Debian Maintainer Scripts:** https://www.debian.org/doc/debian-policy/ch-maintainerscripts.html

## Questions or Issues?

- Check `missing-features.md` for detailed implementation analysis
- Open an issue on GitHub
- Review official ZED SDK documentation
