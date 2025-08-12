# Map Rotation Animation Implementation

## Overview

The JustAMap application supports two map display modes: North Up (north is up) and Heading Up (direction of travel is up). This document explains the implementation of smooth rotation animation when switching between modes.

## Implementation Details

### 1. Immediate Rotation Animation

In the previous implementation, when the North Up/Heading Up toggle button was pressed, the map would not rotate until the next location update. The new implementation provides immediate smooth rotation animation when the toggle button is pressed.

#### Implementation in MapView.swift

```swift
.onReceive(viewModel.mapControlsViewModel.$isNorthUp) { isNorthUp in
    viewModel.saveSettings()
    // Immediately rotate with animation when map orientation is toggled
    if let location = viewModel.userLocation ?? currentMapCamera.map({ camera in
        CLLocation(latitude: camera.centerCoordinate.latitude, longitude: camera.centerCoordinate.longitude)
    }) {
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1)) {
            let heading: Double
            if isNorthUp {
                heading = 0 // North Up
            } else if let userLocation = viewModel.userLocation, userLocation.course >= 0 {
                heading = userLocation.course // Heading Up with valid course
            } else {
                heading = 0 // Default
            }
            
            let camera = MapCamera(
                centerCoordinate: location.coordinate,
                distance: currentMapCamera?.distance ?? viewModel.mapControlsViewModel.currentAltitude,
                heading: heading,
                pitch: 0
            )
            mapPosition = .camera(camera)
        }
    }
}
```

This implementation achieves the following behavior when switching modes:
- **North Up mode**: Set heading to 0 (north is up)
- **Heading Up mode**: Use GPS course information (direction of travel is up)
- **Smooth animation**: Natural rotation using `interactiveSpring`

### 2. Preventing User Rotation in North Up Mode

In North Up mode, the map should always face north, and we need to prevent users from manually rotating it.

#### Implementation in MapView.swift

```swift
Map(position: $mapPosition, interactionModes: viewModel.mapControlsViewModel.isNorthUp ? [.pan, .zoom] : .all) {
    UserAnnotation()
}
```

Using the `interactionModes` parameter, we allow only interactions excluding rotation (pan and zoom only) when in North Up mode.

### 3. Map Direction Calculation Based on Location Information

A method was added to MapViewModel to calculate the appropriate map direction based on the current mode and location information.

#### Implementation in MapViewModel.swift

```swift
/// Calculate map heading based on location information
func calculateMapHeading(for location: CLLocation) -> Double {
    if mapControlsViewModel.isNorthUp {
        return 0 // North Up: always north is up
    } else {
        // Heading Up: use course information if valid, otherwise 0
        return location.course >= 0 ? location.course : 0
    }
}
```

### 4. Animation Details

Animation parameters used:
- **Type**: `interactiveSpring` - Natural spring animation suitable for user interaction
- **response**: 0.3 seconds - Quick response time
- **dampingFraction**: 0.8 - High damping for smooth deceleration
- **blendDuration**: 0.1 seconds - Short blend time for immediate response

## Testing

Created the following test cases for the implementation:

1. **Toggle Test**: Verify that North Up/Heading Up switching works correctly
2. **Rotation Angle Calculation Test**: Verify correct rotation angles are calculated for each direction
3. **Invalid Course Handling Test**: Verify fallback behavior when GPS course is invalid
4. **User Operation Restriction Test**: Verify rotation is disabled in North Up mode

## Performance Impact

- **Battery Consumption**: No additional consumption as existing location update frequency is unchanged
- **CPU Usage**: Animation uses SwiftUI's optimized rendering
- **Memory Usage**: No additional memory usage

## Future Improvement Ideas

1. **Compass Display**: Add compass overlay to visually show current direction
2. **Rotation Gesture**: Support two-finger rotation gesture in Heading Up mode
3. **Direction Smoothing**: Moving average filter to reduce GPS course fluctuation

## Related Files

- `/JustAMap/MapView.swift` - Map display and animation processing
- `/JustAMap/Models/MapViewModel.swift` - Map direction calculation logic
- `/JustAMap/Models/MapControlsViewModel.swift` - Map control state management
- `/JustAMapTests/MapRotationAnimationTests.swift` - Rotation feature tests

## Issue

- [#1 Feature Addition: Map Rotation Animation for North Up / Heading Up Switching](https://github.com/skoji/just-a-map/issues/1)