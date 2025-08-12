# Troubleshooting Guide

This document compiles problems encountered during Stage 1 implementation and their solutions.

## Table of Contents

1. [Build Errors](#build-errors)
2. [Runtime Errors](#runtime-errors)
3. [Location Information Related](#location-information-related)
4. [UI Related](#ui-related)
5. [Test Related](#test-related)

## Build Errors

### 1. Info.plist Duplication Error

**Error Message:**
```
Multiple commands produce '.../JustAMap.app/Info.plist'
```

**Cause:**
- Conflict between custom Info.plist file and auto-generation settings

**Solution:**
1. Delete custom Info.plist
2. Verify `GENERATE_INFOPLIST_FILE = YES` in Build Settings
3. Specify Info.plist settings with `INFOPLIST_KEY_*`

```
// Add to Build Settings
INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "Uses location information to display current location at map center"
```

### 2. MapKit API Deprecation Warning

**Warning Message:**
```
'init(coordinateRegion:interactionModes:showsUserLocation:userTrackingMode:)' was deprecated in iOS 17.0
```

**Cause:**
- New Map API was introduced in iOS 17

**Solution:**

Old API:
```swift
Map(coordinateRegion: $viewModel.region,
    showsUserLocation: true,
    userTrackingMode: .constant(.follow))
```

New API:
```swift
Map(position: $mapPosition) {
    UserAnnotation()
}
.mapControls {
    MapCompass()
    MapScaleView()
}
```

### 3. MKCoordinateRegion Not Conforming to Equatable

**Error Message:**
```
Instance method 'onChange(of:perform:)' requires that 'MKCoordinateRegion' conform to 'Equatable'
```

**Solution:**
Use `onReceive` instead of `onChange`:

```swift
// This causes error
.onChange(of: viewModel.region) { _ in }

// Correct method
.onReceive(viewModel.$region) { newRegion in }

// Or with new API
.onMapCameraChange { context in }
```

## Runtime Errors

### 1. CLLocationManager did fail with error: Error Domain=kCLErrorDomain Code=1

**Error Meaning:**
- Code=1: Access to location services is denied

**Check Items:**
1. Is permission description set in Info.plist
2. Is Settings > Privacy > Location Services ON in simulator
3. Has location permission been granted to the app

**Solution:**
1. Delete and reinstall app
2. Reset simulator: Device > Erase All Content and Settings

### 2. CLLocationManager did fail with error: Error Domain=kCLErrorDomain Code=0

**Error Meaning:**
- Code=0 (locationUnknown): Temporarily unable to acquire location information

**Characteristics:**
- Frequently occurs in simulator
- Rarely occurs on actual devices
- Location information updates normally

**Solution:**
Add processing to ignore this error:

```swift
func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if let clError = error as? CLError {
        switch clError.code {
        case .locationUnknown:
            // Code 0: Temporary error so ignore
            print("Temporary location error - ignoring")
            return
        case .denied:
            // Handle permission denial appropriately
            delegate?.locationManager(self, didFailWithError: LocationError.authorizationDenied)
        default:
            // Other errors
            delegate?.locationManager(self, didFailWithError: LocationError.locationUpdateFailed(clError.localizedDescription))
        }
    }
}
```

## Location Information Related

### 1. Location Information Not Updating

**Causes:**
- Location information not set in simulator
- Permission not granted

**Solution:**
1. Simulator menu: Features > Location > Apple
2. Or specify latitude/longitude with Custom Location

### 2. Error Message Won't Disappear

**Problem:**
"Failed to acquire location information" continues to display

**Cause:**
- Error not cleared even when location information is acquired normally

**Solution:**
Clear error when location acquisition succeeds:

```swift
nonisolated func locationManager(_ manager: LocationManagerProtocol, didUpdateLocation location: CLLocation) {
    Task { @MainActor in
        self.userLocation = location
        // Clear error (except permission denial)
        if self.locationError != nil && self.locationError != .authorizationDenied {
            self.locationError = nil
        }
    }
}
```

## UI Related

### 1. Map Doesn't Follow Current Location

**Cause:**
- Implementation needed for new MapKit API

**Solution:**
```swift
// Update map when location information is updated
.onReceive(viewModel.$userLocation) { newLocation in
    if viewModel.isFollowingUser, let location = newLocation {
        withAnimation {
            mapPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
}
```

### 2. Buttons Too Small

**Problem:**
Difficult to tap when wearing motorcycle gloves

**Solution:**
Minimum 60x60 point tap targets:

```swift
Button(action: { }) {
    Image(systemName: "location.fill")
        .font(.title2)
        .frame(width: 60, height: 60)  // Minimum size
        .background(Color.blue)
        .clipShape(Circle())
}
```

## Test Related

### 1. Test Compilation Error

**Error:**
```
Cannot convert value of type 'CLLocationDegrees?' to expected argument type 'CLLocationDegrees'
```

**Cause:**
Improper handling of optional types

**Solution:**
```swift
// This causes error
XCTAssertEqual(mockDelegate.lastReceivedLocation?.coordinate.latitude, expected, accuracy: 0.0001)

// Correct method
XCTAssertNotNil(mockDelegate.lastReceivedLocation)
XCTAssertEqual(mockDelegate.lastReceivedLocation!.coordinate.latitude, expected, accuracy: 0.0001)
```

### 2. Device Specification Error During Test Execution

**Error:**
```
Unable to find a device matching the provided destination specifier
```

**Solution:**
Check available devices:
```bash
xcodebuild -showdestinations -scheme JustAMap
```

Specify correct device:
```bash
xcodebuild test -scheme JustAMap -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Debugging Tips

### 1. Output Error Details

```swift
print("Location error: \(clError.code.rawValue) - \(clError.localizedDescription)")
```

### 2. Check State

```swift
print("Authorization status: \(locationManager.authorizationStatus.rawValue)")
print("Is updating location: \(isUpdatingLocation)")
print("User location: \(userLocation?.coordinate ?? CLLocationCoordinate2D())")
```

### 3. Check Simulator Logs

You can check app logs and system logs in Xcode's bottom debug area.

## Stage 2 Related Problems

### 1. Address Not Displaying

**Causes:**
- No network connection
- Reverse geocoding rate limits
- Low location accuracy

**Solution:**
```swift
// Add debug logs
print("Geocoding location: \(location.coordinate)")
print("Geocoding error: \(error)")
```

**Check Items:**
1. Simulator network connection
2. Check error messages in console
3. Test on actual device (simulator reverse geocoding can be unstable)

### 2. Sleep Prevention Not Working

**Symptoms:**
Screen automatically turns off

**Causes:**
- Timing of `isIdleTimerDisabled` setting
- Missing setting when returning from background

**Solution:**
```swift
// Debug check
print("Idle timer disabled: \(UIApplication.shared.isIdleTimerDisabled)")
```

### 3. async/await Errors

**Error:**
```
'async' call in a function that does not support concurrency
```

**Solution:**
```swift
// Execute asynchronous processing within Task
Task {
    do {
        let address = try await geocodeService.reverseGeocode(location: location)
        // UI update
    } catch {
        // Error handling
    }
}
```

### 4. Slow Address Acquisition

**Symptoms:**
Takes several seconds to display address

**Causes:**
- Network delays
- Continuous requests

**Solution:**
```swift
// Cancel previous task
geocodingTask?.cancel()

// Add debounce processing (optional)
private var geocodingTimer: Timer?

func scheduleGeocoding(for location: CLLocation) {
    geocodingTimer?.invalidate()
    geocodingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
        self.fetchAddress(for: location)
    }
}
```

### 5. Mock Creation Error for Tests

**Error:**
```
Cannot override with a stored property 'name'
```

**Cause:**
CLPlacemark properties cannot be `override`

**Solution:**
```swift
class MockPlacemark: CLPlacemark {
    private let _name: String?
    
    override var name: String? { _name }
    
    init(name: String?) {
        self._name = name
        super.init()
    }
}
```

## SwiftUI Form Related

### 1. Button in Form Not Responding

**Symptoms:**
Zoom level adjustment buttons (+/-) in settings screen cannot be pressed

**Cause:**
Applying `.buttonStyle(.plain)` to Button in SwiftUI Form disables tap events

**Solution:**
```swift
// NG: Doesn't work in Form
Button { /* action */ } label: { /* label */ }
    .buttonStyle(.plain)

// OK: Works in Form
Button { /* action */ } label: { /* label */ }
    .buttonStyle(.borderless)
```

### 2. Current Location Button Disables Follow Mode

**Symptoms:**
Pressing current location button briefly shows crosshairs and disables follow mode

**Cause:**
Temporary map center shift during zoom level changes triggers distance check in onMapCameraChange, causing follow mode disable

**Solution:**
```swift
// Use isZoomingByButton flag
Button(action: {
    isZoomingByButton = true
    viewModel.centerOnUserLocation()
    // Camera update processing
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        isZoomingByButton = false
    }
}) { /* Button UI */ }

// Check flag in onMapCameraChange
.onMapCameraChange { context in
    guard !isZoomingByButton else { return }
    // Normal processing
}
```

## Summary

Many problems are caused by:

1. **Permission setting issues**
2. **Mixing old and new APIs**
3. **Simulator-specific behavior**
4. **Asynchronous processing handling**
5. **Network-related errors**
6. **SwiftUI-specific behavior** (Form, Button, State management, etc.)

Understanding these enables efficient troubleshooting.