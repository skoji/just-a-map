# Utilizing Swift Structured Concurrency

## Overview

This document explains examples of implementing asynchronous processing using Swift Structured Concurrency in the just a map project.

## What is Structured Concurrency

Structured concurrency is a mechanism for structured parallel processing introduced in Swift 5.5, with the following characteristics:

- **Structured**: Clear parent-child relationships between tasks
- **Automatic Cancellation**: Child tasks are automatically cancelled when parent tasks are cancelled
- **Type Safety**: Data races are detected at compile time

## Implementation Examples

### 1. Basic Asynchronous Processing

```swift
// GeocodeService.swift
func reverseGeocode(location: CLLocation) async throws -> Address {
    do {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else {
            throw GeocodeError.noResults
        }
        
        // Build address
        let fullAddress = buildFullAddress(from: placemark)
        
        return Address(
            name: placemark.name,
            fullAddress: fullAddress,
            // ...
        )
    } catch {
        if error is GeocodeError {
            throw error
        }
        throw GeocodeError.geocodingFailed
    }
}
```

**Key Points:**
- Describe asynchronous processing synchronously with `async/await`
- Natural error handling implementation possible

### 2. Task Cancellation Processing

```swift
// MapViewModel.swift
private var mapCenterGeocodingTask: Task<Void, Never>?

func updateMapCenter(_ coordinate: CLLocationCoordinate2D) {
    mapCenterCoordinate = coordinate
    
    guard !isFollowingUser else { return }
    
    // Cancel previous task
    mapCenterGeocodingTask?.cancel()
    
    // Start new task
    mapCenterGeocodingTask = Task {
        // Debounce
        try? await Task.sleep(nanoseconds: mapCenterDebounceDelay)
        
        // Cancellation check
        guard !Task.isCancelled else { return }
        
        // Acquire address
        await fetchAddressForMapCenter()
    }
}
```

**Key Points for Cancellation Processing:**
1. Hold task references
2. Cancel previous tasks before starting new tasks
3. Check `Task.isCancelled` at key points in processing

### 3. Utilizing @MainActor

```swift
@MainActor
class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(...)
    @Published var userLocation: CLLocation?
    // ...
}

// LocationManagerDelegate
extension MapViewModel: LocationManagerDelegate {
    nonisolated func locationManager(_ manager: LocationManagerProtocol, didUpdateLocation location: CLLocation) {
        Task { @MainActor in
            self.userLocation = location
            self.updateRegionIfFollowing(location: location)
            // ...
        }
    }
}
```

**Benefits of @MainActor:**
- UI updates automatically execute on main thread
- Prevents data races
- Separate delegate methods with `nonisolated`

### 4. Debounce Processing Implementation

```swift
private let mapCenterDebounceDelay: UInt64 = 300_000_000 // 300ms

mapCenterGeocodingTask = Task {
    // Debounce
    try? await Task.sleep(nanoseconds: mapCenterDebounceDelay)
    
    guard !Task.isCancelled else { return }
    
    // Actual processing
    await fetchAddressForMapCenter()
}
```

**Debounce Mechanism:**
1. Achieve delay with `Task.sleep`
2. Cancel if new requests arrive during that time
3. Only the last request is executed

### 5. Managing Multiple Asynchronous Processes

```swift
// MapViewModel.swift
private var geocodingTask: Task<Void, Never>?        // Current location address acquisition
private var mapCenterGeocodingTask: Task<Void, Never>?  // Map center address acquisition

func stopLocationTracking() {
    locationManager.stopLocationUpdates()
    geocodingTask?.cancel()
    mapCenterGeocodingTask?.cancel()
}
```

**Multiple Task Management:**
- Manage tasks for different purposes separately
- Can cancel individually as needed
- Batch cancellation according to app lifecycle

## Best Practices

### 1. Error Handling

```swift
private func fetchAddressForMapCenter() async {
    isLoadingMapCenterAddress = true
    
    let location = CLLocation(
        latitude: mapCenterCoordinate.latitude,
        longitude: mapCenterCoordinate.longitude
    )
    
    do {
        let address = try await geocodeService.reverseGeocode(location: location)
        
        guard !Task.isCancelled else { return }
        
        self.mapCenterAddress = addressFormatter.formatForDisplay(address)
        self.isLoadingMapCenterAddress = false
    } catch {
        guard !Task.isCancelled else { return }
        
        print("Map center geocoding error: \(error)")
        self.isLoadingMapCenterAddress = false
    }
}
```

**Key Points:**
- Reset loading state even on error
- Don't update UI if cancelled

### 2. Asynchronous Processing in Tests

```swift
func testFetchAddressForMapCenterWithDebounce() async {
    // Given
    let newCenter = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
    sut.isFollowingUser = false
    
    // When
    sut.updateMapCenter(newCenter)
    
    // Then - Address acquisition doesn't start immediately
    XCTAssertFalse(sut.isLoadingMapCenterAddress)
    
    // Wait for debounce time
    try? await Task.sleep(nanoseconds: 500_000_000)
    
    // Then - Address is acquired after debounce
    XCTAssertNotNil(sut.mapCenterAddress)
}
```

**Testing Key Points:**
- Test asynchronous processing with `async` test functions
- Control timing with `Task.sleep`
- Consider actual processing time for wait duration

### 3. Memory Management

```swift
// Example not using weak references (capture lists unnecessary for Tasks as they're structs)
mapCenterGeocodingTask = Task {
    try? await Task.sleep(nanoseconds: mapCenterDebounceDelay)
    
    guard !Task.isCancelled else { return }
    
    // Strong reference to self is fine (released when Task is cancelled)
    await fetchAddressForMapCenter()
}
```

## Performance Impact

### 1. Responsive UI
- UI doesn't block due to asynchronous processing
- Reduce wasteful processing with debounce

### 2. Efficient Resource Utilization
- Immediately cancel unnecessary tasks
- Prevent waste of system resources

### 3. Battery Consumption Optimization
- Prevent excessive API calls
- Execute only minimum necessary processing

## Troubleshooting

### 1. Tasks Don't Cancel

```swift
// Bad example
Task {
    while true {
        // Infinite loop without checking Task.isCancelled
        await someWork()
    }
}

// Good example
Task {
    while !Task.isCancelled {
        await someWork()
    }
}
```

### 2. Heavy Processing on Main Thread

```swift
// Bad example
@MainActor
func processHeavyData() async {
    // Execute heavy processing on main thread
    let result = heavyComputation()
}

// Good example
func processHeavyData() async {
    // Execute in background
    let result = await Task.detached {
        return heavyComputation()
    }.value
    
    // Update only result on main thread
    await MainActor.run {
        self.result = result
    }
}
```

## Summary

By utilizing Structured Concurrency:

1. **Safe Asynchronous Processing**: Prevent data races and deadlocks
2. **Readable Code**: Asynchronous processing can be described synchronously
3. **Efficient Resource Management**: Automatic cancellation processing
4. **Excellent Performance**: Responsive UI and battery efficiency

The just a map project leverages these characteristics to provide users with a comfortable map experience.