# Settings Screen and Default Zoom Level Feature

## Overview

JustAMap's settings screen allows users to customize the following items:
- Default zoom level
- Default map style (Standard/Satellite/Hybrid)
- Default map orientation (North Fixed/Direction of Travel)
- Address display format (Standard/Detailed/Simple)
- App version information display

## Implementation Details

### SettingsViewModel

ViewModel that manages the business logic of the settings screen:

```swift
class SettingsViewModel: ObservableObject {
    private var settingsStorage: MapSettingsStorageProtocol
    private var bundle: BundleProtocol
    private var versionInfo: [String: Any]?
    
    @Published var defaultZoomIndex: Int
    @Published var defaultMapStyle: MapStyle
    @Published var defaultIsNorthUp: Bool
    @Published var addressFormat: AddressFormat
}
```

### Version Information Acquisition

Uses the version management system implemented in PR #50:

1. **Acquire from VersionInfo.plist** (Priority)
   - Generated at build time
   - Contains automatically generated version number from Git information

2. **Acquire from Bundle.main** (Fallback)
   - Used when VersionInfo.plist doesn't exist
   - Valid during development and testing

### Settings Persistence

Saved to UserDefaults using `MapSettingsStorage`:

```swift
protocol MapSettingsStorageProtocol {
    var defaultZoomIndex: Int { get set }
    var defaultMapStyle: MapStyle { get set }
    var defaultIsNorthUp: Bool { get set }
    var addressFormat: AddressFormat { get set }
}
```

## TDD Approach

### Test-First Development

1. **SettingsViewModelTests**
   - Version information acquisition logic
   - Settings value read/write
   - Tests using MockBundle

2. **Integration Tests**
   - Settings screen display
   - Settings change reflection
   - Settings persistence on app restart

### Mock Objects

```swift
class MockBundle: BundleProtocol {
    var infoDictionary: [String: Any]?
    var mockResources: [String: URL] = [:]
    
    func url(forResource name: String?, withExtension ext: String?) -> URL? {
        // Mock for VersionInfo.plist
    }
}
```

## UI Implementation

### SwiftUI Form

The settings screen uses SwiftUI Form:

```swift
Form {
    Section("map_settings") {
        // Zoom level settings
        // Map style settings
        // Map orientation settings
    }
    
    Section("address_settings") {
        // Address format settings
    }
    
    Section("app_info") {
        // Version information display
    }
}
```

## Internationalization Support

All setting items support multiple languages:
- Japanese (ja)
- English (en)

Managed in Localizable.strings files.

## Future Extensions

- Settings export/import
- iCloud synchronization
- Detailed customization options