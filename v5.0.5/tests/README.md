# ZED SDK Installation Comparison Test Suite

This test suite provides comprehensive verification that our custom .deb packages produce identical installations to the official ZED SDK .run files. It uses Docker containers to create controlled, reproducible test environments for comparison.

## Overview

The test suite creates two Docker images for each supported platform:
- **Runfile Image**: Installs ZED SDK using the official .run file from StereoLabs
- **Deb Image**: Installs ZED SDK using our custom .deb package

Both installations are then compared across multiple dimensions to ensure equivalence.

## Test Architecture

```
tests/
├── docker/
│   ├── amd64/                    # AMD64 test configurations
│   │   ├── Dockerfile.runfile    # Official .run installation
│   │   ├── Dockerfile.deb        # Custom .deb installation
│   │   └── install-runfile.sh    # .run installation script
│   ├── arm64/                    # ARM64 test configurations
│   │   ├── Dockerfile.runfile
│   │   ├── Dockerfile.deb
│   │   └── install-runfile.sh
│   └── common/
│       ├── base-deps.sh          # Shared dependencies
│       └── compare-install.sh    # Installation comparison logic
├── scripts/
│   ├── build-test-images.sh      # Build Docker test images
│   ├── run-comparison.sh         # Execute comparison tests
│   └── generate-report.sh        # Generate detailed analysis
├── results/                      # Test execution results
├── reports/                      # Detailed analysis reports
├── Makefile                      # Test automation
└── README.md                     # This documentation
```

## Prerequisites

### System Requirements
- **Docker**: Must be installed and running
- **Disk Space**: ~10GB for images and test data
- **Memory**: 4GB+ recommended for parallel testing

### Package Requirements
Before running tests, ensure .deb packages are built:

```bash
# Build AMD64 package
cd ../amd64
make build

# Build ARM64 package
cd ../arm64
make build
```

## Quick Start

### 1. Complete Test Suite
Run the full test suite for all platforms:

```bash
cd tests/
make all
```

This will:
1. Build Docker test images
2. Run installation comparisons
3. Generate detailed analysis reports

### 2. Platform-Specific Testing
Test only a specific platform:

```bash
# Test AMD64 only
make amd64

# Test ARM64 only
make arm64
```

### 3. Individual Steps
Run components separately for debugging:

```bash
# Build images only
make build-images

# Run tests only (requires existing images)
make test

# Generate reports only (requires test results)
make reports
```

## Usage Examples

### Basic Testing
```bash
# Check prerequisites
make check-prereqs

# Run complete test suite
make all

# View results
make results
```

### Development Workflow
```bash
# Clean everything and start fresh
make clean-all

# Build packages first
cd ../amd64 && make build
cd ../arm64 && make build
cd ../tests

# Run tests with clean slate
make all

# Review comprehensive analysis
cat reports/comprehensive_analysis.txt
```

### Debugging Issues
```bash
# Check test status
make status

# Clean and rebuild images
make rebuild

# Run tests with verbose output
./scripts/run-comparison.sh -v

# Generate detailed file differences
./scripts/generate-report.sh -f
```

## Test Comparison Points

### 1. File System Layout
- **Core Files**: All files under `/usr/local/zed/`
- **Symlinks**: Tool symlinks in `/usr/local/bin/`
- **Udev Rules**: Rules in `/etc/udev/rules.d/`
- **Library Config**: Configuration in `/etc/ld.so.conf.d/`

### 2. Python Package Installation
- **Import Test**: `import pyzed` functionality
- **Package Location**: Installation path verification
- **Module Files**: Complete package file listing

### 3. System Configuration
- **Group Creation**: 'zed' group setup
- **Permissions**: File ownership and access rights
- **Library Cache**: ldconfig integration
- **Udev Integration**: Device rule activation

### 4. Tool Availability
- **Executables**: ZED diagnostic and viewer tools
- **Symlinks**: Tool accessibility from PATH
- **Functionality**: Basic tool execution (without hardware)

## Test Results

### Result Files
Test execution creates several result files in `results/`:

- `{platform}_{method}_results.txt`: Complete test output
- `{platform}_{method}_manifest.txt`: File system manifest
- `{platform}_comparison.txt`: Side-by-side comparison
- `test_summary.txt`: Overall test summary

### Report Files
Detailed analysis creates comprehensive reports in `reports/`:

- `{platform}_file_diff.txt`: File-by-file differences
- `{platform}_python_analysis.txt`: Python package analysis
- `{platform}_system_config.txt`: System configuration comparison
- `comprehensive_analysis.txt`: Executive summary and final assessment

## Interpreting Results

### Success Indicators
```
✓ Installations appear equivalent
✓ No major differences detected
✓ All tested platforms show equivalent installations
```

### Warning Indicators
```
⚠ File count mismatch detected
⚠ Python package installation differs
⚠ Library configuration differs
```

### Failure Indicators
```
✗ ISSUES DETECTED: Significant differences found
✗ .deb packages may not be equivalent to .run files
```

## Common Test Scenarios

### Scenario 1: New Package Version
When updating to a new ZED SDK version:

```bash
# Update checksums in PKGBUILD files
# Build new packages
cd ../amd64 && make build
cd ../arm64 && make build

# Test equivalence
cd ../tests
make clean-all
make all

# Review results
make results
```

### Scenario 2: PKGBUILD Changes
After modifying package build scripts:

```bash
# Rebuild affected packages
cd ../amd64 && make clean && make build

# Test changes
cd ../tests
make clean-images  # Force image rebuild
make amd64         # Test specific platform

# Review differences
cat reports/amd64_file_diff.txt
```

### Scenario 3: New Platform Support
When adding support for a new architecture:

```bash
# Create new platform directory with Dockerfiles
# Add platform to test scripts
# Run tests
make build-images
make test
```

## Troubleshooting

### Docker Issues
```bash
# Check Docker status
docker info

# List test images
make list-images

# Rebuild images from scratch
make clean-images
make build-images
```

### Missing Packages
```bash
# Check for required .deb files
ls -la ../*/*.deb

# Build missing packages
cd ../amd64 && make build
cd ../arm64 && make build
```

### Test Failures
```bash
# Check detailed results
cat results/amd64_runfile_results.txt
cat results/amd64_deb_results.txt

# Generate focused reports
./scripts/generate-report.sh -f amd64  # File differences only
./scripts/generate-report.sh -p amd64  # Python analysis only
```

### Permission Issues
```bash
# Ensure scripts are executable
make setup

# Check Docker permissions
sudo usermod -a -G docker $(whoami)
# Log out and back in
```

## Limitations and Considerations

### Platform Limitations
- **Jetson Testing**: Limited without actual Jetson hardware
- **GPU Features**: Cannot test CUDA functionality in most Docker environments
- **Hardware Devices**: No actual ZED camera testing

### Test Scope
- **Installation Verification**: Files, configurations, packages
- **Basic Functionality**: Import tests, tool availability
- **Not Covered**: Runtime performance, actual camera operations

### Docker Constraints
- **No Hardware Access**: Cannot test hardware-dependent features
- **Image Size**: Large images due to ZED SDK size (~2GB+)
- **Build Time**: Initial builds can take 15-30 minutes

## Advanced Usage

### Custom Test Configurations
Modify Docker build arguments:
```bash
# Build with specific options
docker build --build-arg CUDA_VERSION=12.8 -f docker/amd64/Dockerfile.deb .
```

### Parallel Testing
Run platform tests in parallel:
```bash
make parallel-test
```

### CI/CD Integration
```bash
# Automated testing pipeline
make check-prereqs
make validate
make all
if [ $? -eq 0 ]; then echo "Tests passed"; else echo "Tests failed"; exit 1; fi
```

## Contributing

### Adding New Tests
1. Add test logic to `compare-install.sh`
2. Update result parsing in `generate-report.sh`
3. Test with existing platforms
4. Document new comparison points

### Supporting New Platforms
1. Create platform directory under `docker/`
2. Add Dockerfiles and installation scripts
3. Update automation scripts with new platform
4. Test thoroughly before submitting

### Improving Analysis
1. Enhance report generation scripts
2. Add new comparison dimensions
3. Improve result visualization
4. Add statistical analysis

## References

- [ZED SDK Documentation](https://www.stereolabs.com/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [makedeb Documentation](https://docs.makedeb.org/)

---

**Maintainer**: Hsiang-Jui Lin <jerry73204@gmail.com>
**Last Updated**: September 2025
**Version**: 1.0.0