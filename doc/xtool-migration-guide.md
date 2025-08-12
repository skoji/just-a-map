# xtool Migration Guide

## Overview

The JustAMap project has migrated from Xcode projects to xtool-based SwiftPM workspaces. This enables cross-platform development on Linux, WSL, and macOS.

## New Project Structure

```
just-a-map/
├── Package.swift           # SwiftPM manifest
├── xtool.yml              # xtool configuration file
├── Info.plist             # App information (location permissions, etc.)
├── Makefile               # Build automation
├── Resources/             # Resource files
│   ├── source/           # Source assets
│   │   └── Assets.xcassets
│   ├── built/            # Compiled assets
│   │   ├── Assets.car
│   │   ├── *.png
│   │   └── VersionInfo.plist  # Generated at build (.gitignore)
├── Sources/
│   └── JustAMap/          # Main target
│       ├── JustAMapApp.swift  # @main entry point
│       ├── ContentView.swift
│       ├── MapView.swift
│       ├── Models/
│       ├── Services/
│       ├── Views/
│       └── Extensions/
├── Tests/
│   └── JustAMapTests/     # Test target
├── scripts/               # Build scripts
│   ├── compile-assets.sh  # Asset compilation
│   ├── fix-assets.sh      # Asset deployment
│   ├── generate-version.sh # Version information generation
│   └── sync-version-info.sh # VersionInfo.plist sync
└── xtool/                 # Build artifacts (added to .gitignore)
    └── JustAMap.app/      # Generated app
```

## Build Methods

### Prerequisites

1. Install xtool:
```bash
# macOS
brew install xtool

# Linux/WSL
curl -L https://github.com/xtool-org/xtool/releases/latest/download/xtool-linux-x86_64 -o /usr/local/bin/xtool
chmod +x /usr/local/bin/xtool
```

2. Install Swift 5.9 or later

### Build and Run

#### Using Makefile (Recommended)

```bash
# Build app
make build

# Run in simulator
make run

# Install on device
make install DEVICE_ID=<device-udid>

# Check device list
make devices

# Run tests
make test

# Clean build
make clean

# Show help
make help
```

#### Manual Build

Due to xtool limitations, asset compilation requires additional steps:

```bash
# 1. Build app
xtool dev build

# 2. Fix assets (required for icon display)
./scripts/fix-assets.sh

# 3. Install on device
xtool install -u <device-udid> xtool/JustAMap.app
```

### Asset Updates

xtool cannot compile Assets.xcassets, so pre-compilation on macOS is required:

```bash
# Compile assets on macOS
make compile-assets

# Or run manually
./scripts/compile-assets.sh
```

Compiled assets (Resources/built/) are committed to Git, allowing builds on other platforms.

### Test Execution

**Using Makefile (Recommended)**
```bash
make test
```

**Other Methods**

1. Using Xcode:
```bash
open Package.swift
# Run tests with Cmd+U
```

2. Using xcodebuild:
```bash
xcodebuild test -scheme JustAMap -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Other Commands

```bash
# Cleanup
rm -rf xtool/ .build/

# Check device list
xtool devices

# Install app (.ipa file)
xtool install <path-to-ipa>

# Launch app
xtool launch --bundle-id com.example.JustAMap
```

## Development with Xcode

When using Xcode, open as SwiftPM project:

```bash
open Package.swift
```

Or select Package.swift from Xcode's "File > Open...".

## CI/CD Configuration

You can use workflows like the following in GitHub Actions:

```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Install Swift
      uses: swift-actions/setup-swift@v1
      with:
        swift-version: "5.9"
    
    - name: Install xtool
      run: |
        if [ "$RUNNER_OS" == "Linux" ]; then
          curl -L https://github.com/xtool-org/xtool/releases/latest/download/xtool-linux-x86_64 -o /usr/local/bin/xtool
        else
          brew install xtool
        fi
        chmod +x /usr/local/bin/xtool
    
    - name: Setup xtool (Linux)
      if: runner.os == 'Linux'
      run: |
        # Note: Requires Xcode.xip to be provided
        # See xtool documentation for setup instructions
    
    - name: Build
      run: xtool dev run --simulator --configuration release
    
    - name: Test (macOS only)
      if: runner.os == 'macOS'
      run: xcodebuild test -scheme JustAMap -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Troubleshooting

### Build Errors

1. **Build error: "No devices are booted"**
   ```bash
   # Start simulator
   xcrun simctl boot "iPhone 16"
   # Run again
   make run
   ```

2. **App icon not displaying**
   - Run `make fix-assets` to fix assets
   - Verify Assets.car exists in Resources/built/
   - Run `make compile-assets` on macOS to recompile assets

3. **Resources not found**
   - Verify assets are placed in Resources/source/Assets.xcassets
   - Check if resources are correctly defined in Package.swift

4. **xtool.yml errors**
   - Verify filename is `xtool.yml` (not `.yaml`)
   - Minimum configuration: `version: 1`, `bundleID: com.example.JustAMap`, `infoPath: Info.plist`

### Test Errors

1. **Tests not found**
   - Verify test files are placed in `Tests/JustAMapTests/`
   - Check import statement is `@testable import JustAMap`

## Migration Benefits

1. **Cross-platform support**: Development possible on Linux, WSL, macOS
2. **Simplified CI/CD**: Build and test possible without Xcode
3. **Dependency management**: Unified dependency management with SwiftPM
4. **Development environment consistency**: Unified build settings with xtool
5. **Version management**: Git-based automatic version management system (see [version-management-system.md](version-management-system.md) for details)

## Known Limitations

1. **Asset catalog**: xtool cannot compile Assets.xcassets, requiring pre-compilation on macOS
2. **App icon**: fix-assets script execution required after build
3. **dev mode**: Automatic asset fixing is not performed with `xtool dev`

## Future Work

- Complete CI/CD configuration migration
- Testing in Linux/WSL environments
- Performance optimization
- Waiting for xtool asset catalog support improvements