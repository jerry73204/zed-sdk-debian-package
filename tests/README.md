# ZED SDK Build Test Suite

Automated testing for all ZED SDK package builds.

## Quick Start

```bash
cd tests

# Test all versions
make all

# Test specific version
make test-v5.1.2
make test-v5.0.5
make test-v4.2

# Check build status
make status
```

## What It Tests

- **Builds packages** using `make docker-build` for each platform
- **Verifies output** `.deb` files exist in `output/` directories
- **Validates packages** using `dpkg-deb --info`
- **Reports status** for all versions and platforms

## Tested Platforms

| Version | AMD64 | JP60 |
|---------|-------|------|
| v4.2    | ✅    | ✅   |
| v5.0.5  | ✅    | ✅   |
| v5.1.2  | ✅    | ✅   |

## Prerequisites

- Docker installed and running
- QEMU for ARM64 emulation (on x86_64 hosts):
  ```bash
  sudo apt-get install qemu-user-static binfmt-support
  ```

## Targets

- `make all` - Test all versions and platforms
- `make test-v5.1.2` - Test ZED SDK 5.1.2 only
- `make test-v5.0.5` - Test ZED SDK 5.0.5 only
- `make test-v4.2` - Test ZED SDK 4.2 only
- `make status` - Show build status for all platforms
- `make clean` - Remove all built packages
- `make validate` - Check prerequisites

## Example Output

```
═══════════════════════════════════════
Testing ZED SDK 5.1.2
═══════════════════════════════════════

→ Building v5.1.2/amd64...
✓ v5.1.2/amd64 build successful
  ✓ Package found: zed-sdk_5.1.2-1_amd64.deb (33M)

→ Building v5.1.2/jp60...
✓ v5.1.2/jp60 build successful
  ✓ Package found: zed-sdk-jetpack_5.1.2-1_arm64.deb (33M)
```

## Notes

- Each build downloads ~2GB SDK files (cached after first run)
- ARM64 builds on x86_64 use QEMU emulation (slower)
- Builds run in isolated Docker containers
- No system dependencies required (except Docker)
