# Speed Display Feature - Technical Documentation

## Overview

We implemented a feature that displays the current speed in real-time while riding a motorcycle. It uses GPS speed information and can display in km/h or mph units.

## Implementation Date
2025-07-10

## Related Issue
[Issue #57](https://github.com/skoji/just-a-map/issues/57) - Add speed display feature

## Implementation Details

### 1. SpeedUnit Enum
Created an enumeration type to manage speed display units.

**File**: `Sources/JustAMap/Models/SpeedUnit.swift`

```swift
enum SpeedUnit: String, CaseIterable {
    case kmh = "kmh"
    case mph = "mph"
    
    var symbol: String
    func displayString(for speed: Double) -> String
    static func convertKmhToMph(kmh: Double) -> Double
    static func convertMphToKmh(mph: Double) -> Double
}
```

**Features**:
- km/h ↔ mph conversion
- Speed display string generation
- Handling of invalid speed values (negative numbers)

### 2. Settings Storage Extension
Added persistence functionality for speed display settings.

**File**: `Sources/JustAMap/Services/MapSettingsStorage.swift`

**Added Properties**:
- `isSpeedDisplayEnabled: Bool` - Speed display ON/OFF
- `speedUnit: SpeedUnit` - Speed unit (default: km/h)

**Added Methods**:
- `saveSpeedDisplayEnabled(_:)` / `loadSpeedDisplayEnabled()`
- `saveSpeedUnit(_:)` / `loadSpeedUnit()`

### 3. SettingsViewModel Extension
Added speed display control in settings screen.

**File**: `Sources/JustAMap/Models/SettingsViewModel.swift`

**Added Properties**:
```swift
@Published var isSpeedDisplayEnabled: Bool
@Published var speedUnit: SpeedUnit
```

### 4. SpeedView UI Component
Created SwiftUI component for speed display.

**File**: `Sources/JustAMap/Views/SpeedView.swift`

**Features**:
- Similar UI design to AltitudeView
- Uses speedometer icon
- Monospace font ensures readability
- Proper handling of loading state and invalid values

### 5. MapViewModel Extension
Added GPS speed information tracking functionality.

**File**: `Sources/JustAMap/Models/MapViewModel.swift`

**Added Features**:
- `currentSpeed: Double?` - Current speed (in m/s units)
- `isSpeedDisplayEnabled` - Get speed display settings
- `speedUnit` - Get speed unit settings
- Speed information update in CLLocationDelegate

### 6. UI Integration
Integrated speed display functionality into map screen and settings screen.

**MapView**: 
- Added speed display below address/altitude display
- Show/hide control based on settings

**SettingsView**:
- Speed display ON/OFF toggle
- Speed unit selection picker (only shown when display is ON)

### 7. Internationalization Support
Multilingual support for English and Japanese.

**Added Strings**:
- `settings.speed_display` - Speed Display
- `settings.speed_unit` - Speed Unit  
- `settings.speed_unit_kmh` - Kilometers per hour (km/h)
- `settings.speed_unit_mph` - Miles per hour (mph)

## Test Implementation

### TDD Approach
Following the project's TDD policy, created tests before implementation.

### Test Files
1. **SpeedUnitTests.swift** - Unit tests for SpeedUnit enum
2. **SpeedSettingsTests.swift** - Settings persistence tests
3. **SpeedViewTests.swift** - UI component tests
4. **SettingsViewModelTests.swift** - Settings ViewModel tests (extension)

### Test Coverage
- Unit conversion accuracy
- Settings persistence
- Proper handling of invalid values
- UI state management

## Error Handling

### Invalid Speed Values
- Negative speed values: Display "---"
- GPS unavailable: Display "---"

### Default Settings Values
- Speed display: OFF (default)
- Speed unit: km/h (default)

## UI/UX Considerations

### Visibility While Motorcycle Riding
- Large font size (16pt, monospace)
- High contrast color scheme
- Simple and intuitive icon (speedometer)

### Touch Targets
- Settings screen toggles and pickers ensure 60x60pt or larger
- Operable even when wearing gloves

## Performance Considerations

### Battery Consumption
- Utilizes existing GPS update frequency control
- Additional battery consumption is minimal

### Memory Usage
- SpeedView is a lightweight component
- Settings values managed with UserDefaults

## Implementation Patterns

### Clean Architecture
- Separation of business logic (SpeedUnit) and UI (SpeedView)
- Protocol-based design (MapSettingsStorageProtocol)

### SwiftUI Best Practices
- Reactive updates with @Published properties
- Preview support
- Accessibility considerations

## Future Extensions

### Voice Narration
Future integration with voice operation features for speed voice narration.

### Apple Watch Integration
Speed display on Apple Watch (future coordination with Issue #5).

### Speed Warnings
Speed limit warning functionality (under consideration).

## Related Files

### Newly Created
- `Sources/JustAMap/Models/SpeedUnit.swift`
- `Sources/JustAMap/Views/SpeedView.swift`  
- `Tests/JustAMapTests/SpeedUnitTests.swift`
- `Tests/JustAMapTests/SpeedSettingsTests.swift`
- `Tests/JustAMapTests/SpeedViewTests.swift`

### Modified
- `Sources/JustAMap/Services/MapSettingsStorage.swift`
- `Sources/JustAMap/Models/SettingsViewModel.swift`
- `Sources/JustAMap/Models/MapViewModel.swift`
- `Sources/JustAMap/MapView.swift`
- `Sources/JustAMap/Views/SettingsView.swift`
- `Sources/JustAMap/en.lproj/Localizable.strings`
- `Sources/JustAMap/ja.lproj/Localizable.strings`
- `Tests/JustAMapTests/SettingsViewModelTests.swift`
- `Tests/JustAMapTests/TestDoubles/MockMapSettingsStorage.swift`

## Technical Details

### Speed Acquisition Method
Uses CLLocation's speed property (m/s units), converting to km/h for display.

### Unit Conversion Formulas
- km/h = m/s × 3.6
- mph = km/h × 0.621371

### Display Precision
Display as integer values (decimal places rounded).

## Design Decision Rationale

### Default Settings
- **Speed display OFF**: Privacy consideration, battery saving
- **km/h unit**: Common usage in Japan

### UI Patterns
- **Following AltitudeView**: Consistent UI
- **Conditional display**: Maintain UI simplicity by showing only when needed

### Error Display
- **"---" display**: Unified with other invalid value displays

## Bug Fix History

### Issue #71: Speed doesn't reset to 0 when stopped
**Fix Date**: 2025-07-11
**PR**: #72

**Problem**:
- Even when device stops, CoreLocation's `pausesLocationUpdatesAutomatically = true` causes location updates to stop
- Last speed value continues to be displayed

**Solution**:
- Implemented 3-second timer to reset speed to 0 when location updates stop
- Timer resets with each location update

### Issue #72: Speed becomes 0 while driving
**Fix Date**: 2025-07-13

**Problem**:
- When GPS accuracy is poor, `CLLocation.speed` returns -1 (invalid value)
- Issue #71 fix unconditionally set `currentSpeed = location.speed`, so invalid values were also set
- SpeedView displays -1 as "---", effectively treating it as 0

**Solution**:
- Update speed only when `location.speed >= 0`
- Retain previous valid value when speed value is invalid (-1)
- Reset timer only when valid speed value is received

**Implementation Details**:
```swift
// Update only when speed is valid (retain previous value when invalid value -1)
if location.speed >= 0 {
    self.currentSpeed = location.speed
    // Reset timer only when valid speed value is received
    self.resetSpeedTimer()
}
```

This ensures that when GPS accuracy temporarily degrades, the previous valid speed value continues to be displayed.

### Issue #73: Speed randomly becomes 0 while driving
**Fix Date**: 2025-07-13
**PR**: #74

**Problem**:
- Issue #71 implemented timer-based speed reset, but speed could reset to 0 even while driving
- Root cause: iOS's `pausesLocationUpdatesAutomatically = true` setting causes the system to temporarily pause location updates

**Solution**:
- Changed to implementation using Apple's official Location API
- Detect stops with `locationManagerDidPauseLocationUpdates` delegate method
- Detect resumption with `locationManagerDidResumeLocationUpdates` delegate method
- Completely removed timer-based implementation

**Implementation Details**:

1. **Added pause/resume delegates to LocationManagerProtocol**:
```swift
protocol LocationManagerDelegate: AnyObject {
    // Existing delegates...
    
    /// When location updates are paused
    func locationManagerDidPauseLocationUpdates(_ manager: LocationManagerProtocol)
    
    /// When location updates are resumed
    func locationManagerDidResumeLocationUpdates(_ manager: LocationManagerProtocol)
}
```

2. **Timer removal and pause/resume handling in MapViewModel**:
```swift
// Removed timer-related code
// private var speedResetTask: Task<Void, Never>?
// private let speedResetDelay: UInt64 = 10_000_000_000

// pause/resume state management
private var isLocationPaused = false

func locationManagerDidPauseLocationUpdates(_ manager: LocationManagerProtocol) {
    Task { @MainActor in
        self.isLocationPaused = true
        // Immediately reset speed to 0 when location updates are paused
        self.currentSpeed = 0.0
    }
}

func locationManagerDidResumeLocationUpdates(_ manager: LocationManagerProtocol) {
    Task { @MainActor in
        self.isLocationPaused = false
        // Location updates resumed, wait for next update
    }
}
```

**Benefits**:
- More accurate stop detection using Apple's official API
- Simpler and more reliable than timer-based implementation
- Improved battery efficiency (no unnecessary timer processing)
- Fully synchronized behavior with iOS location information system

**Testing**:
- Added `simulateLocationUpdatesPaused()` and `simulateLocationUpdatesResumed()` to MockLocationManager
- Test pause/resume speed reset behavior in MapViewModelTests
- Removed timer-based tests