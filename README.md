# ZED SDK Debian Package

<p align="center">
  <a href="https://github.com/jerry73204/zed-sdk-debian-package/releases">
    <strong>Download Debian Packages »</strong>
  </a>
</p>

This repository contains makedeb PKGBUILD scripts to create Debian packages for the StereoLabs ZED SDK. It provides three platform-specific variants optimized for different architectures.

**⚠️ This is not an official release. Use at your own risk.**

## Quick Start

Choose your platform directory and build:

```bash
# For Desktop/Server (x86_64)
cd amd64 && make build

# For Generic ARM64
cd arm64 && make build  

# For NVIDIA Jetson
cd jetpack && make build
```

## Platform Variants

| Platform    | Directory  | Target Systems        | Special Features                   |
|-------------|------------|-----------------------|------------------------------------|
| **AMD64**   | `amd64/`   | Desktop PCs, Servers  | CUDA GPU acceleration              |
| **ARM64**   | `arm64/`   | Generic ARM64 systems | Basic SDK support                  |
| **Jetpack** | `jetpack/` | NVIDIA Jetson devices | NPU/DLA optimization, Media Server |

See [BUILD_VARIANTS.md](BUILD_VARIANTS.md) for detailed platform information.

## Installation

### Prerequisites

1. Install makedeb:
```bash
bash -ci "$(wget -qO - 'https://shlink.makedeb.org/install')"
```

2. Install build dependencies:
```bash
sudo apt update
sudo apt install zstd tar python3-dev python3-pip
```

### Building the Package

1. Clone this repository:
```bash
git clone https://github.com/jerry73204/zed-sdk-debian-package.git
cd zed-sdk-debian-package
```

2. Navigate to your platform directory:
```bash
cd amd64    # or arm64, or jetpack
```

3. Build the package:
```bash
make build
```

4. Install the package:
```bash
sudo dpkg -i zed-sdk*.deb
sudo apt -f install  # Fix any dependencies
```

## Post-Installation Setup

### 1. Add User to Video Group
```bash
sudo usermod -a -G video $(whoami)
# Log out and back in for changes to take effect
```

### 2. Download and Optimize AI Models
```bash
sudo zed_ai_optimizer
```
**Note:** This process takes 30-60 minutes and optimizes models for your specific hardware.

## Important Notes

### For Jetson Users
- **DO NOT** install `libv4l-dev` - it breaks hardware encoding/decoding
- The package automatically configures `nvargus-daemon` for multiple cameras
- ZED Media Server is automatically enabled for streaming

### AI Model Optimization
The `zed_ai_optimizer` tool provides platform-specific optimization:
- **AMD64**: Uses CUDA GPU acceleration
- **ARM64**: CPU-only (slower)
- **Jetpack**: Uses NPU/DLA hardware acceleration

Options:
```bash
zed_ai_optimizer --help     # Show all options
zed_ai_optimizer --status   # Check model status
zed_ai_optimizer --clean    # Remove all models
```

## Documentation

- [BUILD_VARIANTS.md](BUILD_VARIANTS.md) - Platform-specific build information
- [ROADMAP.md](ROADMAP.md) - Project roadmap and feature status
- [CLAUDE.md](CLAUDE.md) - Technical implementation details

## Troubleshooting

### Missing CUDA (AMD64)
Install CUDA 12.8+ from NVIDIA and ensure `nvidia-smi` works.

### Build Fails
Ensure you're in the correct directory for your architecture. Check with:
```bash
dpkg --print-architecture
```

### Package Removal
```bash
# Remove package (keeps settings)
sudo apt remove zed-sdk

# Purge package (removes everything)
sudo apt purge zed-sdk
```

## Contributing

Contributions welcome! Please:
1. Test on target platform
2. Update relevant variant(s)
3. Document changes clearly
4. Test installation and removal

## License

See LICENSE file. The ZED SDK itself is proprietary software by StereoLabs.

## Support

For issues with this packaging:
- [GitHub Issues](https://github.com/jerry73204/zed-sdk-debian-package/issues)

For ZED SDK support:
- [StereoLabs Support](https://www.stereolabs.com/support/)

---
*Maintainer: Hsiang-Jui Lin <jerry73204@gmail.com>*
