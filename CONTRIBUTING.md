# Contributing to UN1CA

Thank you for your interest in contributing to UN1CA! This document provides guidelines and instructions for contributing to the project.

## Table of Contents
- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Building the Project](#building-the-project)
- [Code Style](#code-style)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/UN1CA-v2.git`
3. Create a new branch for your feature: `git checkout -b feature/your-feature-name`

## Development Environment

### Prerequisites

The build system requires the following dependencies:
- 7z, awk, basename, bc, brotli, cat, clang, cmake
- cp, cpio, curl, cut, cwebp, dd, dirname, du, ffmpeg
- file, fmt, getfattr, git, grep, head, java, ln
- lz4, make, md5sum, mkdir, mount, mv, perl, protoc
- python3, rm, rsync, sed, sha1sum, sort, split, stat
- sudo, tail, tar, touch, tr, truncate, umount, unzip
- wc, whoami, xargs, xxd, zip, zstd

### Setting Up

1. Source the build environment:
   ```bash
   source buildenv.sh <target>
   ```

2. Available targets can be found in the `target/` directory:
   - a52sxq
   - a73xq
   - dm2q
   - m52xq

## Building the Project

### Build Dependencies
```bash
./scripts/build_dependencies.sh
```

### Download Firmware
```bash
./scripts/download_fw.sh
```

### Extract Firmware
```bash
./scripts/extract_fw.sh
```

### Build ROM
```bash
./scripts/make_rom.sh
```

#### Build Options
- `-f, --force`: Force ROM build
- `--no-rom-zip`: Do not build ROM zip

## Code Style

### Shell Scripts

1. **Always use shebang**: Start scripts with `#!/usr/bin/env bash`

2. **Use shellcheck**: Run shellcheck on your scripts before submitting:
   ```bash
   shellcheck -S warning your_script.sh
   ```

3. **Error handling**: Use proper error handling with safe variable expansion:
   ```bash
   # Good
   rm -rf "${VAR:?}/"*
   
   # Bad
   rm -rf "$VAR/"*
   ```

4. **Function documentation**: Document functions with comments explaining:
   - Purpose
   - Parameters
   - Return values

5. **Logging**: Use the provided logging utilities:
   ```bash
   LOG "Info message"
   LOGW "Warning message"
   LOGE "Error message"
   ```

### Commit Messages

- Use clear and descriptive commit messages
- Start with a verb in present tense (e.g., "Add", "Fix", "Update")
- Keep the first line under 72 characters
- Add detailed description if necessary

Example:
```
Fix workflow step reference in build.yml

- Corrected step ID references for version and download links
- Added missing IDs to workflow steps
```

## Testing

1. Test your changes locally before submitting
2. Ensure the build completes successfully
3. Verify that existing functionality is not broken
4. Test on actual devices when possible

## Submitting Changes

1. Ensure your code follows the style guidelines
2. Run shellcheck on modified scripts
3. Update documentation if necessary
4. Commit your changes with clear messages
5. Push to your fork
6. Create a Pull Request with:
   - Clear title
   - Description of changes
   - Related issue number (if applicable)
   - Screenshots/logs if relevant

## Project Structure

```
UN1CA-v2/
├── .github/          # GitHub Actions workflows
├── external/         # External tools and dependencies
├── platform/         # Platform-specific patches
├── prebuilts/        # Prebuilt tools and blobs
├── scripts/          # Build scripts
│   ├── internal/     # Internal build scripts
│   └── utils/        # Utility functions
├── security/         # Security keys and certificates
├── target/           # Device-specific configurations
└── unica/            # UN1CA ROM modifications
    ├── configs/      # Configuration files
    ├── mods/         # ROM modifications
    └── patches/      # ROM patches
```

## Additional Resources

- [Discussions](https://github.com/salvogiangri/UN1CA/discussions)
- [Telegram](https://t.me/unicarom)
- [Main Repository](https://github.com/salvogiangri/UN1CA)

## License

By contributing to UN1CA, you agree that your contributions will be licensed under the GNU General Public License v3.0.
