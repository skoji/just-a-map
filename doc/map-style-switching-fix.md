# Fix for Zoom Level Reset Issue When Switching Map Styles

## Problem Overview

When switching map styles (Standard/Hybrid/Satellite) on actual devices, the following issues occurred:

1. **Style changes not immediately reflected**: Tapping the style button didn't change the appearance, and it would only be reflected after zoom or scroll operations
2. **Zoom level reset**: After style switching, it would return to the maximum zoom level displaying all of Japan

## Root Cause Analysis

### Problems with Initial Implementation

```swift
// Map
Group {
    switch viewModel.mapControlsViewModel.currentMapStyle {
    case .standard:
        Map(position: $mapPosition) {
            UserAnnotation()
        }
        .mapStyle(.standard)
    case .hybrid:
        Map(position: $mapPosition) {
            UserAnnotation()
        }
        .mapStyle(.hybrid)
    case .imagery:
        Map(position: $mapPosition) {
            UserAnnotation()
        }
        .mapStyle(.imagery)
    }
}
```

This implementation created separate `Map` instances for each style. Therefore:

1. A new `Map` instance was created when switching styles
2. The `onMapCameraChange` event fired unexpectedly, changing the zoom level
3. Camera position (zoom level and center coordinates) was lost

## Evolution of Solution Approaches

### 1. Complex Approach (Failed)

Initially, we attempted the following complex solutions:

- Introduction of style changing flag (`isChangingMapStyle`)
- Saving and restoring camera position
- Forced redraw through minor camera position changes
- View recreation using `.id()` modifier

These approaches were overly complex and caused new problems (unexpected zoom out).

### 2. Simple Approach (Successful)

Eventually, we reached a simple solution that leveraged SwiftUI's basic state management.

## Final Solution

### Implementation Code

```swift
struct MapView: View {
    // ... other properties ...
    
    // @State variable for map style display (initial value is nil)
    @State private var mapStyleForDisplay: JustAMap.MapStyle?
    
    // Computed property to convert to MapKit.MapStyle
    private var currentMapKitStyle: MapKit.MapStyle {
        switch mapStyleForDisplay ?? viewModel.mapControlsViewModel.currentMapStyle {
        case .standard:
            return .standard
        case .hybrid:
            return .hybrid
        case .imagery:
            return .imagery
        }
    }
    
    var body: some View {
        ZStack {
            // Use single Map instance
            Map(position: $mapPosition) {
                UserAnnotation()
            }
            .mapStyle(currentMapKitStyle)  // Apply style dynamically
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            // ... other modifiers ...
        }
        .onAppear {
            // ... other initialization processing ...
            // Set initial style (only if not already set)
            if mapStyleForDisplay == nil {
                mapStyleForDisplay = viewModel.mapControlsViewModel.currentMapStyle
            }
        }
        .onReceive(viewModel.mapControlsViewModel.$currentMapStyle) { newStyle in
            viewModel.saveSettings()
            // Update State variable to trigger SwiftUI redraw
            mapStyleForDisplay = newStyle
        }
    }
}
```

### Key Points of the Solution

1. **Single Map Instance**: Use a single `Map` instead of multiple instances through switch statement
2. **Utilize @State Variable**: Use `mapStyleForDisplay` to properly trigger SwiftUI's redraw mechanism
3. **Proper Initial Value Handling**: Use optional type and set initial value from viewModel in `onAppear` to prevent flicker
4. **Simple Implementation**: No need for complex processing like camera position save/restore

## Why This Solution Works

### SwiftUI's Redraw Mechanism

1. When `@State` variable changes, SwiftUI redraws the view
2. Since we're using a single `Map` instance, camera position is automatically preserved
3. Only the map appearance is updated by changing the `mapStyle` property

### Resolving Type Conflicts

To avoid name conflicts between the app-defined `MapStyle` enum and `MapKit.MapStyle`:

- Use fully qualified names (`JustAMap.MapStyle`)
- Convert to `MapKit.MapStyle` with computed property

## Lessons Learned

1. **Importance of Simplicity**: Map style switching is a basic operation and doesn't require complex handling
2. **Return to SwiftUI Basics**: Solvable with basic features like `@State` and computed properties
3. **Single Instance Benefits**: State preservation is automatic, no additional management code needed

## Test Additions

Added `MapStyleSwitchingTests` and developed using TDD approach:

```swift
@MainActor
class MapStyleSwitchingTests: XCTestCase {
    // MainActor annotation required (ViewModel is MainActor isolated)
    
    func testMapStyleChangePreservesZoomLevel() {
        // Verify zoom level is preserved
    }
}
```

## Future Improvements

The current implementation is simple and effective, but future improvements could include:

1. Animated style switching
2. Visual feedback during style switching
3. More advanced camera control (if needed)

## References

- [SwiftUI Map Documentation](https://developer.apple.com/documentation/mapkit/map)
- [Managing State in SwiftUI](https://developer.apple.com/documentation/swiftui/state-and-data-flow)