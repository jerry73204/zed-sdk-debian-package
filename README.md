# ZED SDK Debian Package

<p align="center">
  <a href="https://github.com/jerry73204/zed-sdk-debian-package/releases/tag/4.2-1">
    <strong>Download Debian Packages »</strong>
  </a>
</p>

This repository contains makedeb PKGBUILD scripts to create Debian packages for the StereoLabs ZED SDK. It extracts the content from the ZED SDK run file and re-packages it into a Debian package file.

**This is not an official release. Use at your own risk.**

## Repository Structure

The repository has been restructured to support separate builds for different architectures:

```
makedeb-zed-sdk/
├── README.md                    # This file
├── shared/                      # Shared files used by both architectures
│   ├── python_shebang.patch
│   └── zed_download_ai_models
├── x86_64/                      # x86_64/Desktop build
│   ├── PKGBUILD
│   ├── Makefile
│   ├── postinst.sh
│   ├── prerm.sh
│   └── postrm.sh
└── jetson/                      # Jetson/ARM64 build
    ├── PKGBUILD
    ├── Makefile
    ├── postinst.sh
    ├── prerm.sh
    └── postrm.sh
```

## Build the Debian Package

You need to install `makedeb` to build this package. Please visit [makedeb.org](https://www.makedeb.org/) to install this command.

### For x86_64 (Desktop) Systems

```bash
cd x86_64
make
# or
makedeb -s
```

### For Jetson (ARM64) Systems

```bash
cd jetson
make
# or
makedeb -s
```

## Important Notes

### For x86_64/Desktop Users

- CUDA 12.1+ is required for the SDK to function
- AI features require proper CUDA installation
- After installation, add your user to the video group: `sudo usermod -a -G video $(whoami)`
- Log out and back in for group changes to take effect
- Download AI models with: `zed_download_ai_models`

### For Jetson Users

1. **DO NOT** install the `libv4l-dev` package on Jetson devices as it will break hardware encoding/decoding support. This package is configured to conflict with `libv4l-dev`.
2. The package automatically modifies the `nvargus-daemon.service` to enable infinite timeout for camera connections, improving stability with multiple cameras.
3. The `zed_media_server_cli.service` is automatically configured and enabled on Jetson devices.
4. L4T 36.3 is required for this package version.
5. For ZED X camera support with GMSL, refer to the [official documentation](https://www.stereolabs.com/docs/get-started-with-zed-x/).

## Development and Contributing

See [missing-features.md](missing-features.md) for:
- Detailed analysis of missing features from the official installer
- Implementation roadmap organized in phases
- Testing checklists
- Architecture-specific considerations
