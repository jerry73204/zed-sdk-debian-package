# ZED SDK Debian Packages

Build scripts to create Debian packages for the StereoLabs ZED SDK.

## ⚠️ Legal Notice

**This repository contains build scripts only. It does NOT distribute the ZED SDK.**

- Download the ZED SDK from [StereoLabs official website](https://www.stereolabs.com/developers/release/)
- Accept StereoLabs' license agreement
- The ZED SDK is proprietary software - redistribution of binaries is prohibited
- These scripts are for personal use only

---

## Quick Start

```bash
git clone https://github.com/jerry73204/zed-sdk-debian-package.git
cd zed-sdk-debian-package

# Choose your platform
cd v5.1.2/amd64       # Latest: x86_64 desktop
# or v5.1.2/jp60      # Latest: NVIDIA Jetson
# or v5.0.5/amd64     # Stable: x86_64 desktop
# or v5.0.5/jp60      # Stable: NVIDIA Jetson

# Build with Docker (recommended)
make docker-build

# Install
sudo dpkg -i output/zed-sdk*.deb
sudo apt-get install -f
```

---

## Repository Structure

```
zed-sdk-debian-package/
├── v5.1.2/              # ZED SDK 5.1.2 (Latest)
│   ├── amd64/           # Ubuntu 22.04 x86_64, CUDA 12.8
│   └── jp60/            # JetPack 6.0, L4T 36.3
│
├── v5.0.5/              # ZED SDK 5.0.5 (Stable)
│   ├── amd64/           # Ubuntu 22.04 x86_64, CUDA 12.8
│   └── jp60/            # JetPack 6.0, L4T 36.4
│
├── v4.2/                # ZED SDK 4.2 (Legacy)
│   ├── amd64/           # Ubuntu 22.04 x86_64
│   └── jp60/            # JetPack 5.x, L4T 36.3
│
└── tests/               # Build test suite
```

---

## Platform Support

| Platform                          | v4.2 | v5.0.5 | v5.1.2 |
|-----------------------------------|------|--------|--------|
| **AMD64** (x86_64 desktop/server) | ✅   | ✅     | ✅     |
| **JP60** (NVIDIA Jetson)          | ✅   | ✅     | ✅     |

---

## Build Methods

### Docker Build (Recommended)

No dependencies needed except Docker:

```bash
cd v5.1.2/amd64
make docker-build
```

Output: `output/zed-sdk_5.1.2-1_amd64.deb`

### Native Build

Requires Ubuntu 22.04 with debhelper:

```bash
sudo apt-get install debhelper dpkg-dev devscripts fakeroot zstd python3-dev python3-pip
cd v5.1.2/amd64
make build
```

---

## Installation

```bash
# Install package
sudo dpkg -i output/zed-sdk*.deb
sudo apt-get install -f

# Add user to video group
sudo usermod -a -G video $USER

# Log out and back in, then optimize AI models
sudo zed_ai_optimizer
```

---

## Requirements

### For Runtime
- Ubuntu 22.04 (or compatible)
- NVIDIA GPU with CUDA support (AMD64)
- Or NVIDIA Jetson device (JP60)
- Valid ZED camera

### For Docker Build
- Docker installed
- For ARM64 builds on x86_64: QEMU ARM64 emulation

### For Native Build
- Ubuntu 22.04
- debhelper, dpkg-dev, devscripts, fakeroot
- zstd, python3-dev, python3-pip

---

## License

These build scripts are provided as-is for personal use. The ZED SDK itself is proprietary software from StereoLabs. See the [ZED SDK license](https://www.stereolabs.com/developers/license/) for SDK terms.

**Maintainer:** Hsiang-Jui Lin <jerry73204@gmail.com>
