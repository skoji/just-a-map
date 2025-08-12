# Stage 3 Implementation Guide - Map Controls and Display Mode Switching

## Overview
In Stage 3, we added intuitive map operation features to the just a map application. The implementation considers use on motorcycle handle mounts, with large tap targets and clear UI.

## Implemented Features

### 1. Zoom Controls
- **Zoom In/Out Buttons**: Large 60x60 point buttons displayed with magnifying glass icons
- **12-Level Discrete Zoom**: From building level (200m) to earth level (1,000,000m)
- **Altitude-Based Implementation**: Stable operation unaffected by MapKit's internal conversions
- **Zoom Limit Indicator**: Buttons gray out when zoom limits are reached
- **Smooth Animation**: Natural scaling with withAnimation

### 2. Map Display Mode Switching
- **3 Display Modes**:
  - Standard (normal map)
  - Hybrid (satellite imagery + map information)
  - Satellite only
- **One-Tap Switching**: Cycles through modes each time map icon is tapped
- **Visual Feedback**: Icon changes according to current mode

### 3. North Up / Heading Up Switching Preparation
- **Toggle Button**: Displayed with compass icon
- **State Management**: Foundation implemented for future heading information support
- **Icon Changes**: Different icons for North Up and Heading Up

### 4. Settings Persistence
- **UserDefaults Storage**:
  - Current map style
  - North Up/Heading Up settings
  - Zoom level (saved as index)
- **App Restart Restoration**: Previous settings automatically applied

## Implementation Details

### MapControlsViewModel
Created a new ViewModel to manage map control business logic.

```swift
@MainActor
class MapControlsViewModel: ObservableObject {
    @Published var currentMapStyle: MapStyle = .standard
    @Published var isNorthUp: Bool = true
    @Published private(set) var currentZoomIndex: Int = 5
    
    // Altitude-based zoom levels (12 levels)
    private let predefinedAltitudes: [Double] = [
        200,      // Building level
        500,      // Block level
        1000,     // Neighborhood level
        2000,     // District level
        5000,     // Ward/City level
        10000,    // City level
        20000,    // Metropolitan level
        50000,    // Prefecture level
        100000,   // Regional level
        200000,   // National level
        500000,   // Continental level
        1000000,  // Global level
    ]
    
    // Zoom operations
    func zoomIn()
    func zoomOut()
    func setNearestZoomIndex(for altitude: Double)
    
    // Properties
    var currentAltitude: Double { get }
    var canZoomIn: Bool { get }
    var canZoomOut: Bool { get }
}
```

### Zoom Implementation Improvements

#### Problems
The previous span (latitude/longitude range) based implementation had issues where MapKit internally converted values, returning different values than expected:

```
Expected: 0.02 -> MapKit return: 0.034474...
Expected: 0.05 -> MapKit return: 0.08618...
```

#### Solution
Using MKMapCamera's altitude property achieved more stable zoom management:

```swift
// New zoom implementation
let camera = MapCamera(
    centerCoordinate: coordinate,
    distance: viewModel.mapControlsViewModel.currentAltitude,
    heading: heading,
    pitch: 0
)
mapPosition = .camera(camera)
```

### MapControlsView
UI component for map controls.

```swift
struct MapControlsView: View {
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var controlsViewModel: MapControlsViewModel
    @Binding var mapPosition: MapCameraPosition
    @Binding var isZoomingByButton: Bool
    let currentMapCamera: MapCamera?
    
    var body: some View {
        VStack(spacing: 16) {
            // Zoom controls
            VStack(spacing: 8) {
                ControlButton(
                    icon: "plus.magnifyingglass",
                    action: { zoomIn() },
                    isEnabled: controlsViewModel.canZoomIn
                )
                ControlButton(
                    icon: "minus.magnifyingglass",
                    action: { zoomOut() },
                    isEnabled: controlsViewModel.canZoomOut
                )
            }
            
            Divider()
            
            // Map style switching
            ControlButton(icon: mapStyleIcon, action: { controlsViewModel.toggleMapStyle() })
            
            // North Up / Heading Up switching
            ControlButton(icon: orientationIcon, action: { controlsViewModel.toggleMapOrientation() })
        }
    }
}
```

### MapSettingsStorage
Service class that manages settings persistence.

```swift
protocol MapSettingsStorageProtocol {
    func saveMapStyle(_ style: MapStyle)
    func loadMapStyle() -> MapStyle
    func saveMapOrientation(isNorthUp: Bool)
    func loadMapOrientation() -> Bool
    func saveZoomIndex(_ index: Int)
    func loadZoomIndex() -> Int?
}
```

## iOS Development Learning Points

### 1. MapCamera and MapCameraPosition
iOS 17's new MapKit API uses `MapCamera` and `MapCameraPosition` to manage map position:

```swift
// Creating MapCamera
let camera = MapCamera(
    centerCoordinate: location.coordinate,
    distance: 10000,  // Altitude (meters)
    heading: 0,       // Direction (degrees)
    pitch: 0          // Tilt (degrees)
)

// Applying to MapCameraPosition
@State private var mapPosition: MapCameraPosition = .automatic
mapPosition = .camera(camera)
```

### 2. Utilizing onMapCameraChange
Monitor map changes and track user operations:

```swift
.onMapCameraChange { context in
    // Get current camera information from context
    let camera = context.camera
    currentMapCamera = camera
    
    // Set nearest zoom level from altitude
    viewModel.mapControlsViewModel.setNearestZoomIndex(for: camera.distance)
}
```

### 3. SwiftUI State Management
Flag management to distinguish button operations from pinch operations:

```swift
@State private var isZoomingByButton = false

// During button zoom
isZoomingByButton = true
withAnimation {
    mapPosition = .camera(newCamera)
}
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    isZoomingByButton = false
}
```

## Test-Driven Development (TDD) Practice

### 1. MapControlsViewModelTests
Test zoom operations, style switching, and orientation switching logic:

```swift
func testZoomInLimit() {
    // Set to minimum zoom level
    sut.setZoomIndex(0)
    
    // Attempt to zoom in
    sut.zoomIn()
    
    // Verify cannot zoom in further
    XCTAssertEqual(sut.currentZoomIndex, 0)
    XCTAssertFalse(sut.canZoomIn)
}

func testSetNearestZoomIndex() {
    // Altitude 750m is nearest to 1000m (index 2)
    sut.setNearestZoomIndex(for: 750)
    XCTAssertEqual(sut.currentZoomIndex, 2)
}
```

### 2. MapSettingsStorageTests
Test settings save and load using mocks:

```swift
func testSaveZoomIndex() {
    sut.saveZoomIndex(7)
    XCTAssertEqual(mockUserDefaults.storage["zoomIndex"] as? Int, 7)
}
```

### 3. @MainActor Considerations
UI-related class tests require `@MainActor` annotation:

```swift
@MainActor
final class MapControlsViewModelTests: XCTestCase {
    // Test code
}
```

## Implementation Benefits

### 1. Stable Zoom Operation
- Independent of MapKit's internal conversions
- Always predictable 12-level zoom
- Reliable movement to next level with buttons even after pinch operations

### 2. Excellent User Experience
- Visual indication of zoom limits (button grayout)
- Consistent zoom steps
- Smooth animations

### 3. Improved Maintainability
- Simple index-based implementation
- Easy to write tests and verify behavior
- Design that accommodates future extensions (voice commands, etc.)

## Future Extensions

### Heading Up Feature Implementation
Currently only buttons and flags implemented. Elements needed for future implementation:
- Get heading information with CLLocationManagerDelegate
- Apply to MapCamera's heading property
- Option to choose magnetic north vs. true north

### Voice Command Support
Foundation for future voice operations:
- Each operation method is independent
- Easy to call from voice recognition
- Simple commands like "zoom in", "zoom out"

## Summary
In Stage 3, we implemented intuitive map controls considering motorcycle use. Particularly, the altitude-based zoom implementation achieved stable operability independent of MapKit's internal behavior. Through large tap targets, visual feedback, and settings persistence, we completed basic functionality as a practical map application.

The TDD approach ensured reliable operation of each feature while allowing gradual feature addition.