# Version Management System

## Overview

The JustAMap project adopts a Git-based automatic version management system. This system automatically generates version numbers from Git information during build and embeds them in the application.

## System Components

### Major Components

1. **scripts/generate-version.sh**
   - Retrieves information from Git repository
   - Generates version strings and build numbers
   - Returns specific information via command line arguments

2. **scripts/sync-version-info.sh**
   - Executed during build
   - Generates `Resources/built/VersionInfo.plist`
   - Synchronizes Git information in plist format

3. **Resources/built/VersionInfo.plist**
   - Generated during build
   - Excluded from Git tracking (listed in .gitignore)
   - Read by application

4. **SettingsViewModel**
   - Reads version information from VersionInfo.plist
   - Fallback to Bundle if file doesn't exist

## Version Number Structure

### Version String
```
<major>.<minor>.<patch>+<commit-hash>[.dirty]
```

- **major.minor.patch**: Semantic versioning
- **commit-hash**: Shortened Git commit hash (7 characters)
- **.dirty**: Added when uncommitted changes exist

Example: `1.0.0+89a1dfd.dirty`

### Build Number
- Uses Git commit count
- Automatically increments
- Example: `234`

## Build Process

1. Execute `make build` or `make test`
2. `sync-version-info.sh` is called
3. Get Git information with `generate-version.sh`
4. Generate `Resources/built/VersionInfo.plist`
5. Copy to app bundle with `fix-assets.sh`

## Implementation Details

### VersionInfo.plist Format
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0+89a1dfd</string>
    <key>CFBundleVersion</key>
    <string>234</string>
</dict>
</plist>
```

### Loading in SettingsViewModel
```swift
// Load from VersionInfo.plist
if let versionInfoURL = bundle.url(forResource: "VersionInfo", withExtension: "plist"),
   let data = try? Data(contentsOf: versionInfoURL),
   let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
    self.versionInfo = plist
}
```

## Important Design Decisions

### Why Not Directly Modify Info.plist

1. **Git Management Issues**: Info.plist is tracked by Git, so changes with each build would pollute the repository
2. **CI/CD Issues**: Uncommitted changes occur during automated builds
3. **Development Experience**: Git status becomes dirty constantly during development

### Benefits of Runtime Version Information

1. **Clean Git Status**: Repository stays clean even after builds
2. **Flexibility**: Dynamically generate version information during build
3. **Compatibility**: No need to change existing Info.plist structure

## Troubleshooting

### VersionInfo.plist Not Found

- Doesn't exist before first build (normal)
- Auto-generated when running `make build`
- No need to create manually

### Version Information Not Updating

1. Confirm it's a Git repository
2. Check current status with `git status`
3. Manual check with `./scripts/generate-version.sh version-string`

### Version Information During Tests

- Use `MockBundle` for testing
- Can set VersionInfo.plist URL with `mockResources` property

## Future Extensions

- Automatic version acquisition from release tags
- Add build environment information (branch name, etc.)
- Record version history