# ZED SDK Debian Packages

This repository provides makedeb PKGBUILD scripts to create Debian packages for the StereoLabs ZED SDK. It converts the official ZED SDK installer into properly packaged `.deb` files that integrate cleanly with Ubuntu/Debian systems.

**This is not an official release from StereoLabs. Use at your own risk.**

---

## Available Versions

This repository maintains separate branches for different ZED SDK versions. Please select the appropriate branch for your needs:

### ZED SDK 5.0.7 (Latest)
- **Branch:** [v5.0](https://github.com/jerry73204/zed-sdk-debian-package/tree/v5.0)
- **Platforms:** Ubuntu 22.04 (x86_64), JetPack 6.0 / L4T 36.3 (ARM64)
- **CUDA:** 12.1 with TensorRT 8.6 (broader GPU compatibility)
- **Status:** Active development

### ZED SDK 4.2
- **Branch:** [v4.2](https://github.com/jerry73204/zed-sdk-debian-package/tree/v4.2)
- **Platforms:** Ubuntu 22.04 (x86_64), JetPack 6.0 / L4T 36.3 (ARM64)
- **CUDA:** 12.1 with TensorRT 8.6
- **Status:** Maintenance only

---

## Getting Started

### Building Packages

This repository provides source files only. To build packages:

1. **Clone the desired version branch:**
   ```bash
   # For ZED SDK 5.0.7
   git clone -b v5.0 https://github.com/jerry73204/zed-sdk-debian-package.git
   cd zed-sdk-debian-package

   # Or for ZED SDK 4.2
   git clone -b v4.2 https://github.com/jerry73204/zed-sdk-debian-package.git
   cd zed-sdk-debian-package
   ```

2. **Follow the build instructions** in the branch-specific README:
   - [v5.0 README](https://github.com/jerry73204/zed-sdk-debian-package/blob/v5.0/README.md) - Building ZED SDK 5.0.7 packages
   - [v4.2 README](https://github.com/jerry73204/zed-sdk-debian-package/blob/v4.2/README.md) - Building ZED SDK 4.2 packages

### Prerequisites

- **makedeb** - Required to build packages. See [makedeb.org](https://www.makedeb.org/) for installation.
- **Platform-specific requirements** - See the branch-specific README files for detailed prerequisites.

---

## License

These packaging scripts are provided as-is. The ZED SDK itself is proprietary software from StereoLabs with its own licensing terms. See the [official ZED SDK license](https://www.stereolabs.com/developers/license/) for details.
