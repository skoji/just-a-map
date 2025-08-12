# Stage 2 Implementation Guide: Address Display and Sleep Prevention

This document explains the address display and sleep prevention features implemented in Stage 2.

## Table of Contents

1. [Implementation Overview](#implementation-overview)
2. [TDD Development Process](#tdd-development-process)
3. [Reverse Geocoding Service](#reverse-geocoding-service)
4. [Address Formatter](#address-formatter)
5. [Sleep Prevention Feature](#sleep-prevention-feature)
6. [UI Integration](#ui-integration)
7. [Lessons Learned](#lessons-learned)

## Implementation Overview

Stage 2 implemented the following features:

1. **Address Display Feature**
   - Acquire address from current location (reverse geocoding)
   - Support for Japanese address format
   - Prioritize place names (e.g., Tokyo Station) for display

2. **Sleep Prevention Feature**
   - Screen doesn't turn off during motorcycle riding
   - Control according to app lifecycle

## TDD Development Process

### 1. GeocodeService Development

**Red (Write failing test):**
```swift
func testReverseGeocodeSuccess() async throws {
    // Given
    let location = CLLocation(latitude: 35.6762, longitude: 139.6503)
    let expectedPlacemark = MockPlacemark(name: "Tokyo Station", ...)
    mockGeocoder.placemarkToReturn = expectedPlacemark
    
    // When
    let address = try await sut.reverseGeocode(location: location)
    
    // Then
    XCTAssertEqual(address.name, "Tokyo Station")
}
```

**Green (Minimal implementation to pass test):**
```swift
func reverseGeocode(location: CLLocation) async throws -> Address {
    let placemarks = try await geocoder.reverseGeocodeLocation(location)
    guard let placemark = placemarks.first else {
        throw GeocodeError.noResults
    }
    return Address(name: placemark.name, ...)
}
```

## Reverse Geocoding Service

### Abstraction with Protocols

```swift
protocol GeocoderProtocol {
    func reverseGeocodeLocation(_ location: CLLocation) async throws -> [CLPlacemark]
}

extension CLGeocoder: GeocoderProtocol {}
```

**Why Use Protocols?**
- Make CLGeocoder mockable for testing
- Run tests without network connection
- Easy testing of error cases

### Utilizing async/await

```swift
func reverseGeocode(location: CLLocation) async throws -> Address {
    do {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        // ...
    } catch {
        throw GeocodeError.geocodingFailed
    }
}
```

**Differences from Traditional Callback Approach:**
- Code is more readable (looks synchronous)
- Unified error handling
- Simple cancellation processing

## Address Formatter

### Support for Japanese Address Display

```swift
private func buildFullAddress(from placemark: CLPlacemark) -> String {
    var components: [String] = []
    
    // Japanese address format: Prefecture > City/Ward/Town/Village > Street Number
    if let administrativeArea = placemark.administrativeArea {
        components.append(administrativeArea)
    }
    if let locality = placemark.locality {
        components.append(locality)
    }
    // ...
    
    return components.joined()
}
```

### Display Priority

```swift
private func determinePrimaryText(from address: Address) -> String {
    // Priority: 1. Place name, 2. City/Ward/Town/Village, 3. Default
    if let name = address.name, !name.isEmpty {
        return name  // "Tokyo Station"
    }
    if let locality = address.locality, !locality.isEmpty {
        return locality  // "Chiyoda City"
    }
    return "Current Location"
}
```

## Sleep Prevention Feature

### UIApplication Wrapping

```swift
protocol UIApplicationProtocol {
    var isIdleTimerDisabled: Bool { get set }
}

extension UIApplication: UIApplicationProtocol {}
```

**Improved Testability:**
- UIApplication can be mocked
- Independent of actual application state

### Lifecycle Management

```swift
func handleAppDidEnterBackground() {
    // Always disable sleep prevention in background
    application.isIdleTimerDisabled = false
}

func handleAppWillEnterForeground() {
    // Restore previous state
    application.isIdleTimerDisabled = shouldKeepScreenOn
}
```

**Important Points:**
- Maintaining sleep prevention in background wastes battery
- Restore state when returning to foreground

## UI Integration

### AddressView

```swift
struct AddressView: View {
    let formattedAddress: FormattedAddress?
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isLoading && formattedAddress == nil {
                // Initial loading
                HStack {
                    ProgressView()
                    Text("Loading address...")
                }
            } else if let address = formattedAddress {
                // Address display
                Text(address.primaryText)
                    .font(.headline)
                Text(address.secondaryText)
                    .font(.subheadline)
            }
        }
    }
}
```

### MapViewModel Integration

```swift
private func fetchAddress(for location: CLLocation) {
    geocodingTask?.cancel()  // Cancel previous task
    
    geocodingTask = Task {
        do {
            let address = try await geocodeService.reverseGeocode(location: location)
            guard !Task.isCancelled else { return }
            self.formattedAddress = addressFormatter.formatForDisplay(address)
        } catch {
            // Keep previous address even on error
        }
    }
}
```

**Asynchronous Processing Considerations:**
- Cancel previous requests for continuous location updates
- Don't update UI if task is cancelled
- Keep previous address on error (improves UX)

### Utilizing NotificationCenter

```swift
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
    viewModel.handleAppDidEnterBackground()
}
```

**SwiftUI Lifecycle Management:**
- NotificationCenter is more reliable than ScenePhase
- Multiple views can subscribe to the same event

## Lessons Learned

### 1. Effects of TDD
- Testable without external dependencies through mocking
- Confidence during refactoring
- Clear interface design

### 2. Benefits of async/await
- Readable asynchronous processing
- Unified error handling
- Cancellation processing with Task

### 3. Protocol-Oriented Design
- Easy dependency injection
- Improved testability
- Hide implementation details

### 4. UX Considerations
- Clear waiting time with loading display
- Keep previous information on errors
- Consideration for battery consumption

## Summary

In Stage 2, we implemented the following with thorough TDD:

1. **Reverse Geocoding Service**
   - Abstraction with protocols
   - Asynchronous processing with async/await

2. **Address Formatter**
   - Support for Japanese address format
   - Thoughtful display improvements

3. **Sleep Prevention Feature**
   - Control according to lifecycle
   - Consideration for battery consumption

4. **UI Integration**
   - Proper management of asynchronous processing
   - Improved user experience

These implementations further improved the map application for easier use during motorcycle riding.