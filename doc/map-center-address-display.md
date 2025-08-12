# Map Center Address Display Feature Implementation

## Overview

This document explains the technical details of the feature implemented in Issue #8, which displays the address of the map center when scrolling.

## Feature Requirements

1. **Follow Mode Management**
   - Toggle between automatic follow mode for current location and free map operation mode
   - Automatically disable follow mode when user operates the map

2. **Crosshair Display**
   - Display crosshairs at map center when follow mode is disabled
   - High-visibility design (red color, white background)

3. **Center Point Address Display**
   - Reverse geocode map center coordinates
   - Debounce processing to prevent excessive API calls

## Architecture

### State Management

```swift
// MapViewModel.swift
@Published var isFollowingUser = true  // Follow mode state
@Published var mapCenterCoordinate = CLLocationCoordinate2D(...)  // Map center coordinates
@Published var mapCenterAddress: FormattedAddress?  // Center point address
@Published var isLoadingMapCenterAddress = false  // Loading state
```

### Data Flow

```
User Operation
    ↓
MapView.onMapCameraChange
    ↓
viewModel.updateMapCenter()  // Debounce processing
    ↓
viewModel.fetchAddressForMapCenter()  // Address acquisition
    ↓
AddressView  // Display update
```

## Implementation Details

### 1. Detection of Follow Mode Disabling

```swift
// MapView.swift
.onMapCameraChange { context in
    // Update map center coordinates
    viewModel.updateMapCenter(context.region.center)
    
    // If user manually moved the map, disable follow mode
    if viewModel.isFollowingUser {
        if let userLocation = viewModel.userLocation {
            let mapCenter = CLLocation(
                latitude: context.region.center.latitude,
                longitude: context.region.center.longitude
            )
            let distance = userLocation.distance(from: mapCenter)
            if distance > 100 { // Disable follow if more than 100m away
                viewModel.handleUserMapInteraction()
            }
        }
    }
}
```

**Key Points:**
- Detect map changes with `onMapCameraChange`
- Disable follow mode when more than 100m away from current location
- Exclude zoom button operations with `isZoomingByButton` flag

### 2. Debounce Processing

```swift
// MapViewModel.swift
private var mapCenterGeocodingTask: Task<Void, Never>?
private let mapCenterDebounceDelay: UInt64 = 300_000_000 // 300ms

func updateMapCenter(_ coordinate: CLLocationCoordinate2D) {
    mapCenterCoordinate = coordinate
    
    guard !isFollowingUser else { return }
    
    // Cancel previous task
    mapCenterGeocodingTask?.cancel()
    
    // Start new task
    mapCenterGeocodingTask = Task {
        // Debounce
        try? await Task.sleep(nanoseconds: mapCenterDebounceDelay)
        
        guard !Task.isCancelled else { return }
        
        // Acquire address
        await fetchAddressForMapCenter()
    }
}
```

**Debounce Mechanism:**
1. Cancel previous task each time map moves
2. Wait 300ms
3. Start address acquisition if no new movement during that time
4. Task management with Structured Concurrency

### 3. Crosshair Display

```swift
// CrosshairView.swift
struct CrosshairView: View {
    var body: some View {
        ZStack {
            // Background circle (improved visibility)
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 40, height: 40)
                .shadow(radius: 2)
            
            // Crosshair mark
            ZStack {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 30, height: 3)
                
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 3, height: 30)
            }
            
            // Center point
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
        }
    }
}
```

**Design Considerations:**
- Semi-transparent white background for improved visibility
- Red design for prominence
- `allowsHitTesting(false)` to pass through touch events

### 4. Address Display Switching

```swift
// MapView.swift
AddressView(
    formattedAddress: viewModel.isFollowingUser 
        ? viewModel.formattedAddress 
        : viewModel.mapCenterAddress,
    isLoading: viewModel.isFollowingUser 
        ? viewModel.isLoadingAddress 
        : viewModel.isLoadingMapCenterAddress
)
```

**Conditional Branching:**
- Follow mode: Current location address
- Follow mode disabled: Map center address

### 5. Current Location Button Feedback

```swift
// MapView.swift
Button(action: {
    viewModel.centerOnUserLocation()
    // Update camera position
}) {
    Image(systemName: viewModel.isFollowingUser ? "location.fill" : "location")
        .font(.title2)
        .foregroundColor(.white)
        .frame(width: 60, height: 60)
        .background(viewModel.isFollowingUser ? Color.blue : Color.gray)
        .clipShape(Circle())
        .shadow(radius: 4)
        .overlay(
            // Pulse animation when follow mode is disabled
            Circle()
                .stroke(Color.blue, lineWidth: 2)
                .scaleEffect(viewModel.isFollowingUser ? 1 : 1.3)
                .opacity(viewModel.isFollowingUser ? 0 : 0.6)
                .animation(
                    viewModel.isFollowingUser ? .none : 
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: viewModel.isFollowingUser
                )
        )
}
```

**Visual Feedback:**
- Icon: `location.fill` (following) / `location` (disabled)
- Background color: Blue (following) / Gray (disabled)
- Pulse animation: Displayed only when disabled

## Performance Optimization

### 1. Debounce Processing
- Prevents excessive API calls during map scrolling
- Achieves proper balance with 300ms delay

### 2. Task Cancellation
- Proper task management with Structured Concurrency
- Immediate cancellation of unnecessary tasks

### 3. Conditional Processing
- Skip center point address acquisition when in follow mode
- Execute reverse geocoding only when necessary

## Test Strategy

### 1. Unit Tests (MapViewModelTests)
- Follow mode state management
- Verification of debounce processing behavior
- Map center coordinate updates

### 2. Integration Tests (Future Task)
- MapView and MapViewModel coordination
- Verification of behavior through actual map operations

## Future Improvement Ideas

1. **Offline Support**
   - Address cache implementation
   - Fallback for offline situations

2. **Performance Enhancement**
   - Caching of address acquisition results
   - More efficient coordinate comparison algorithms

3. **UI/UX Improvements**
   - Customizable crosshair settings
   - Address display animations

## Summary

This implementation achieves efficient map center address display using SwiftUI's `onMapCameraChange` and Structured Concurrency. Through debounce processing, we were able to balance performance and usability.