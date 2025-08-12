# iOS Development Fundamentals

This document explains basic concepts and terminology for programmers new to iOS development.

## Table of Contents

1. [What is SwiftUI](#what-is-swiftui)
2. [Property Wrappers](#property-wrappers)
3. [View Lifecycle](#view-lifecycle)
4. [Asynchronous Processing](#asynchronous-processing)
5. [Permission System](#permission-system)
6. [Xcode Basics](#xcode-basics)

## What is SwiftUI

SwiftUI is a declarative UI framework announced by Apple in 2019.

### Example of Declarative UI

```swift
// Imperative (UIKit)
let label = UILabel()
label.text = "Hello"
label.textColor = .red
view.addSubview(label)

// Declarative (SwiftUI)
Text("Hello")
    .foregroundColor(.red)
```

**Features:**
- Describes "what to display" rather than "how to create it"
- UI automatically updates when state changes
- Real-time preview with preview functionality

## Property Wrappers

Special attributes frequently used in SwiftUI.

### @State
Manages state within a view.
```swift
struct CounterView: View {
    @State private var count = 0  // View redraws when value changes
    
    var body: some View {
        Button("Count: \(count)") {
            count += 1  // UI automatically updates
        }
    }
}
```

### @StateObject
Manages objects owned by the view.
```swift
struct MapView: View {
    @StateObject private var viewModel = MapViewModel()  // Same instance even when view redraws
}
```

### @Published
In ObservableObject, a property that notifies of changes.
```swift
class MapViewModel: ObservableObject {
    @Published var location: CLLocation?  // Notifies subscribers when changed
}
```

### @ObservedObject
Observes objects passed from elsewhere.
```swift
struct DetailView: View {
    @ObservedObject var viewModel: MapViewModel  // Received from parent
}
```

### @EnvironmentObject
An object shared across the entire app.
```swift
@EnvironmentObject var settings: UserSettings  // Accessible from anywhere
```

## View Lifecycle

Main events in SwiftUI view lifecycle:

```swift
struct MapView: View {
    var body: some View {
        Map()
            .onAppear {
                // When view appears
                print("View appeared")
            }
            .onDisappear {
                // When view disappears
                print("View disappeared")
            }
            .onChange(of: someValue) { newValue in
                // When specific value changes
                print("Value changed: \(newValue)")
            }
    }
}
```

## Asynchronous Processing

### async/await (Swift 5.5 and later)

```swift
// Traditional callback approach
CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
    if let placemark = placemarks?.first {
        // Processing
    }
}

// async/await approach
func getAddress(for location: CLLocation) async throws -> String {
    let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
    return placemarks.first?.name ?? "Unknown"
}
```

### Task

Starts asynchronous processing:
```swift
Task {
    let address = try await getAddress(for: location)
    print(address)
}
```

### @MainActor

UI updates must always be performed on the main thread:
```swift
@MainActor
class MapViewModel: ObservableObject {
    // All properties and methods in this class execute on the main thread
}

// Or
Task { @MainActor in
    // Code inside here executes on the main thread
    self.userLocation = newLocation
}
```

## Permission System

iOS requires permissions for access to the following user data:

- Location information
- Camera
- Microphone
- Contacts
- Photos

### Permission Request Flow

1. **Record usage reason in Info.plist**
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>To display current location on the map</string>
   ```

2. **Request permission**
   ```swift
   locationManager.requestWhenInUseAuthorization()
   ```

3. **Check permission status**
   ```swift
   switch locationManager.authorizationStatus {
   case .notDetermined:  // Not asked yet
   case .denied:         // Denied
   case .authorizedWhenInUse:  // Authorized when in use only
   }
   ```

## Xcode Basics

### Project Structure

```
MyApp.xcodeproj/          # Project file
├── MyApp/                # Source code
│   ├── Assets.xcassets/  # Images and icons
│   ├── Info.plist        # App settings
│   └── *.swift           # Swift files
├── MyAppTests/           # Unit tests
└── MyAppUITests/         # UI tests
```

### Frequently Used Shortcuts

- **⌘+R**: Build & Run
- **⌘+B**: Build only
- **⌘+U**: Run tests
- **⌘+Shift+K**: Clean build
- **⌘+.**: Stop execution
- **⌘+Shift+O**: Open file

### Simulator Operations

- **⌘+D**: Home screen
- **⌘+Shift+H**: Home button
- **⌘+→/←**: Rotate screen
- **Features > Location**: Simulate location information

### Debugging

```swift
// Print debugging
print("Current location: \(location)")

// Breakpoint
// Click line number to place blue arrow

// Debug console
// Displayed at bottom of Xcode
```

## Memory Management

Swift manages memory with ARC (Automatic Reference Counting).

### Preventing Retain Cycles

```swift
// Bad example: Retain cycle
class LocationManager {
    var delegate: LocationManagerDelegate?  // Strong reference
}

// Good example: Weak reference
class LocationManager {
    weak var delegate: LocationManagerDelegate?  // Weak reference
}
```

### Caution with Closures

```swift
// Bad example: Strong reference to self
locationManager.updateHandler = { location in
    self.updateLocation(location)  // Captures self
}

// Good example: Weak capture
locationManager.updateHandler = { [weak self] location in
    self?.updateLocation(location)  // Weak reference
}
```

## Summary

Characteristics of iOS development:

1. **Declarative UI**: Declare state, and UI updates automatically
2. **Strict Permission Management**: Emphasis on user privacy
3. **Asynchronous Processing**: Important for maintaining UI responsiveness
4. **Memory Management**: Automated with ARC, but be careful of retain cycles

Understanding these concepts will give you a foundation in iOS development basics.