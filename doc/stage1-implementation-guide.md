# Stage 1 Implementation Guide: Basic Map Display

This document provides a detailed explanation of the content implemented in Stage 1, aimed at programmers unfamiliar with iOS development.

## Table of Contents

1. [Project Structure](#project-structure)
2. [Explanation of Major Components](#explanation-of-major-components)
3. [Location Information Acquisition Flow](#location-information-acquisition-flow)
4. [SwiftUI and MapKit Integration](#swiftui-and-mapkit-integration)
5. [Error Handling](#error-handling)
6. [Test Strategy](#test-strategy)

## Project Structure

```
JustAMap/
├── JustAMapApp.swift      # App entry point
├── ContentView.swift      # Main view (displays MapView)
├── MapView.swift          # Map display UI
├── Models/
│   ├── LocationManagerProtocol.swift  # Location management abstraction
│   ├── LocationManager.swift          # Actual location management
│   └── MapViewModel.swift             # Business logic
└── Assets.xcassets/       # Resources like icons and colors
```

## Explanation of Major Components

### 1. JustAMapApp.swift - App Entry Point

```swift
@main
struct JustAMapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Explanation:**
- `@main`: Indicates this struct is the application entry point
- `App` protocol: Defines the basic structure of SwiftUI applications
- `WindowGroup`: Manages app windows (usually one on iOS)

### 2. LocationManagerProtocol.swift - Abstraction Layer

```swift
protocol LocationManagerProtocol: AnyObject {
    var delegate: LocationManagerDelegate? { get set }
    var authorizationStatus: CLAuthorizationStatus { get }
    
    func requestLocationPermission()
    func startLocationUpdates()
    func stopLocationUpdates()
}
```

**Why Use Protocols?**
- **Testability**: Can test without actual GPS
- **Dependency Inversion**: Higher layers don't depend on specific implementations of lower layers
- **Mocking**: Easy injection of fake location information during testing

### 3. LocationManager.swift - Implementation

```swift
class LocationManager: NSObject, LocationManagerProtocol {
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0  // Update every 10m movement
        locationManager.activityType = .automotiveNavigation
    }
}
```

**Important Settings:**
- `desiredAccuracy`: GPS accuracy (specifies highest accuracy)
- `distanceFilter`: Update frequency (every 10m movement)
- `activityType`: Usage scenario (optimized for vehicle navigation)

### 4. MapViewModel.swift - Business Logic

```swift
@MainActor
class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(...)
    @Published var userLocation: CLLocation?
    @Published var isLocationAuthorized = false
    @Published var locationError: LocationError?
    @Published var isFollowingUser = true
}
```

**Important SwiftUI Concepts:**
- `@MainActor`: UI updates must always be performed on the main thread
- `@Published`: Automatically updates UI when value changes
- `ObservableObject`: Makes this object observable by SwiftUI

## Location Information Acquisition Flow

```
1. App Launch
   ↓
2. MapView.onAppear() calls requestLocationPermission()
   ↓
3. System displays permission dialog
   ↓
4. User grants permission
   ↓
5. locationManagerDidChangeAuthorization() is called
   ↓
6. startLocationUpdates() begins location acquisition
   ↓
7. locationManager(_:didUpdateLocations:) receives location
   ↓
8. MapViewModel updates the map
```

## SwiftUI and MapKit Integration

### iOS 17's New Map API

```swift
Map(position: $mapPosition) {
    UserAnnotation()  // Current location marker
}
.mapControls {
    MapCompass()      # Compass
    MapScaleView()    # Scale display
}
```

**Differences from Old API:**
- Old: `Map(coordinateRegion: $region)`
- New: `Map(position: .constant(.region(region)))`
- More declarative and easier to integrate with other MapKit features

### Map Follow Mode

```swift
.onMapCameraChange { context in
    if viewModel.isFollowingUser {
        // Disable follow if user moves the map
        if distance > 100 { // If more than 100m away
            viewModel.isFollowingUser = false
        }
    }
}
```

## Error Handling

### Types of Location Information Errors

1. **Permission Denied** (`CLAuthorizationStatus.denied`)
   - User denied location information usage
   - Need to guide to Settings app

2. **Temporary Error** (`kCLErrorDomain Code=0`)
   - Commonly occurs in simulator
   - Safe to ignore

3. **Location Services Disabled**
   - Location information is off device-wide
   - System settings change required

### Error Display UI

```swift
struct ErrorBanner: View {
    let error: LocationError
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(error.localizedDescription)
            
            if error == .authorizationDenied {
                Button("Settings") {
                    // Open Settings app
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
            }
        }
    }
}
```

## Test Strategy

### Mocking with Protocols

```swift
class MockLocationManager: LocationManagerProtocol {
    func simulateLocationUpdate(_ location: CLLocation) {
        delegate?.locationManager(self, didUpdateLocation: location)
    }
}
```

**Test Example:**
```swift
func testLocationUpdate() {
    // Given
    let mockManager = MockLocationManager()
    let viewModel = MapViewModel(locationManager: mockManager)
    
    // When
    mockManager.simulateLocationUpdate(CLLocation(...))
    
    // Then
    XCTAssertNotNil(viewModel.userLocation)
}
```

## iOS-Specific Considerations

### 1. Info.plist Configuration
To use location information, you must specify the reason for use:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Uses location information to display current location at map center</string>
```

### 2. Main Thread and Background Thread
- UI updates must be on main thread (`@MainActor`)
- Location information acquisition is on background thread
- Switch with `Task { @MainActor in ... }`

### 3. Memory Management
- `weak var delegate`: Prevents retain cycles
- `@StateObject`: Maintains same instance even when view redraws
- `@ObservedObject`: Observes objects passed from parent

## Summary

In Stage 1, we implemented the following basic functionality:

1. **Location information acquisition and permission management**
2. **Map display and current location following**
3. **Error handling and user feedback**
4. **Testable design**

These implementations completed the foundation for a basic map application that can be used on motorcycle handle mounts.