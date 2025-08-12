# Just a Map

**just a map** - Just a map, except it updates in real-time

A simple and practical map application designed for motorcycle handlebar mounting.

## Main Features

### Stage 1 (Implemented)
- ✅ Map display centered on current location
- ✅ Automatic location tracking (when moved 10m or more)
- ✅ Tracking mode disabled when map is manually moved
- ✅ Return to current location button (60x60pt for glove compatibility)
- ✅ Proper location permission handling
- ✅ Error display and navigation to settings

### Stage 2 (Implemented)
- ✅ Current location address display (reverse geocoding)
- ✅ Support for Japanese address format (Prefecture → City → Street)
- ✅ Priority display of place names (e.g., Tokyo Station)
- ✅ Postal code display
- ✅ Sleep prevention feature (screen doesn't automatically turn off)
- ✅ Proper background/foreground transition handling

### Stage 3 (Implemented)
- ✅ Zoom controls (12 discrete zoom levels)
  - From building level (200m) to global level (1,000,000m)
  - Stable altitude-based implementation (unaffected by MapKit internal conversions)
  - Button grays out at zoom limits
- ✅ Map display mode switching (Standard/Hybrid/Satellite)
- ✅ North Up / Heading Up toggle button (rotation implemented)
- ✅ Settings persistence (UserDefaults)
  - Zoom level (saved as index)
  - Map style
  - Map orientation setting

### Other Implemented Features

- ✅ North Up / Heading Up switching and rotation
- ✅ Compass

## Technical Specifications

- **iOS**: 17.0 or later
- **Frameworks**: SwiftUI, MapKit, CoreLocation
- **Location Accuracy**: Best (kCLLocationAccuracyBest)
- **Update Frequency**: Varies according to speed and zoom
- **Address Retrieval**: CLGeocoder (reverse geocoding)
- **Sleep Prevention**: UIApplication.shared.isIdleTimerDisabled
- **Zoom Implementation**: MKMapCamera.distance (altitude) based

## Development Environment

- Xcode 16.0 or later (optional)
- Swift 5.9 or later
- macOS 14.0 or later / Linux / WSL
- iOS Simulator (iOS 18.5 recommended)
- xtool (cross-platform build tool)

## Setup

### 1. Open the Project
```bash
git clone <repository-url>
cd just-a-map
```

### 2. Build and Run

#### Using xtool (Recommended)
```bash
# Install xtool
brew install xtool  # macOS
# For Linux/WSL see https://github.com/xtool-org/xtool

# Build and run using Makefile
make build           # Build the app
make run             # Run in simulator
make install DEVICE_ID=<device-id>  # Install on physical device

# Check device IDs
make devices         # Display list of connected devices

# Other useful commands
make test           # Run tests
make clean          # Clean build artifacts
make help           # Display available commands
```

**Note**: xtool cannot compile Assets.xcassets, so special steps are required for asset processing. The Makefile handles this automatically.

#### About Asset Updates
When changing icons or other assets:
1. Run `make compile-assets` on macOS to compile assets
2. Since compiled assets are committed to Git, builds are possible on other platforms

#### Using Xcode
```bash
# Open as SwiftPM project
open Package.swift
```

See [xtool Migration Guide](doc/xtool-migration-guide.md) for details.

### 3. Location Permission Settings
When the app launches, a location permission dialog will appear. Select "Allow While Using App"

## Simulating Location in Emulator

### How to Set Location:
1. From the emulator menu bar: Features > Location
2. Select from the following options:
   - **Apple**: Apple headquarters (California)
   - **City Bicycle Ride**: Simulate bicycle movement
   - **City Run**: Simulate running movement
   - **Freeway Drive**: Simulate highway driving
   - **Custom Location...**: Enter custom latitude/longitude

### Recommended Test Scenarios:
1. First select "Apple" to verify basic operation
2. Test movements similar to motorcycle riding with "City Bicycle Ride"
3. Set Japanese locations with Custom Location:
   - Tokyo Station: Latitude 35.6762, Longitude 139.6503
   - Osaka Station: Latitude 34.7024, Longitude 135.4959

## 5. Functional Verification Items

### Basic Functions
- [ ] Location permission dialog appears on app launch
- [ ] After permission, current location is displayed at map center
- [ ] Map follows when location moves
- [ ] Tracking is disabled when map is manually dragged
- [ ] Tapping the location button in bottom-right returns to current location
- [ ] Error banner displays when location permission is denied
- [ ] Settings button in error banner opens Settings app

### Address Display and Sleep Prevention
- [ ] Current location address displays at the top
- [ ] Address updates when moving
- [ ] Screen doesn't sleep while app is in use
- [ ] Sleep prevention is disabled when moving to background

### Map Controls
- [ ] Zoom in/out buttons switch between 12 zoom levels
- [ ] Buttons gray out at zoom limits
- [ ] Buttons reliably move to next level after pinch operation
- [ ] Map style button switches between Standard/Hybrid/Satellite
- [ ] North Up/Heading Up button displays (state toggles on tap)
- [ ] Previous settings restore on app restart

## 6. Debug Tips

### If Location Cannot Be Obtained:
1. Reset emulator: Device > Erase All Content and Settings...
2. Clean build in Xcode: Product > Clean Build Folder
3. Check emulator location settings: Settings > Privacy & Security > Location Services

### Checking Console Logs:
You can check logs in the debug area at the bottom of Xcode. Current level is output to console during zoom operations.

## Testing

### Running Unit Tests

#### Using Makefile (Recommended)
```bash
make test
```

#### Using Xcode
```bash
open Package.swift
# ⌘+U in Xcode
```

#### Using xcodebuild
```bash
xcodebuild test -scheme JustAMap -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Current Test Coverage
- LocationManager protocol compliance
- Location permission handling
- Location update delegate notifications
- Error handling
- Address format conversion (AddressFormatterTests)
- Sleep prevention feature (IdleTimerManagerTests)
- Altitude-based zoom feature and map style switching (MapControlsViewModelTests)
  - 12-level zoom management
  - Zoom limit testing
  - Altitude to zoom index conversion
- Settings persistence (MapSettingsStorageTests)
  - Zoom index save/load

## Troubleshooting

### If Location Cannot Be Obtained
1. Check simulator location settings: Features > Location
2. Verify Settings > Privacy & Security > Location Services is ON
3. Delete and reinstall the app

### If "kCLErrorDomain Code=0" Error Appears
This is a temporary error specific to the simulator and doesn't affect app operation. It doesn't occur on physical devices.

## License

This project is released under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Documentation

For more detailed technical documentation, see the [doc](doc) directory.
- [Stage 1 Implementation Guide](doc/stage1-implementation-guide.md)
- [Stage 2 Implementation Guide](doc/stage2-implementation-guide.md)
- [Stage 3 Implementation Guide](doc/stage3-implementation-guide.md)
- [iOS Development Basics](doc/ios-development-basics.md)
- [Troubleshooting Guide](doc/troubleshooting-guide.md)