# Test-Driven Development (TDD) Practice Example

## Overview

This document explains the TDD process practiced in the implementation of Issue #8 (Map Center Address Display Feature) with specific code examples.

## TDD Cycle

```
1. Red   - Write failing test
2. Green - Minimal implementation to pass test
3. Refactor - Improve code (while keeping tests passing)
```

## Implementation Example 1: Follow Mode State Management

### 1. Red - Write failing test

```swift
// MapViewModelTests.swift
func testCenterOnUserLocationEnablesFollowingMode() {
    // Given
    let location = CLLocation(latitude: 35.6762, longitude: 139.6503)
    sut.userLocation = location
    sut.isFollowingUser = false
    
    // When
    sut.centerOnUserLocation()
    
    // Then
    XCTAssertTrue(sut.isFollowingUser, "Follow mode should be enabled when calling centerOnUserLocation")
}
```

**Error at this point:**
- `centerOnUserLocation` method is not enabling follow mode

### 2. Green - Minimal implementation to pass test

```swift
// MapViewModel.swift
func centerOnUserLocation() {
    guard let location = userLocation else { return }
    
    // Enable follow mode
    isFollowingUser = true  // Added this line
    
    withAnimation(.easeInOut(duration: 0.3)) {
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: region.span
        )
    }
}
```

### 3. Refactor - Improve as needed

In this example, no refactoring was needed due to simple implementation.

## Implementation Example 2: Address Acquisition with Debounce Processing

### 1. Red - Write failing test

```swift
func testFetchAddressForMapCenterWithDebounce() async {
    // Given
    let newCenter = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
    sut.isFollowingUser = false
    
    // When - Update map center
    sut.updateMapCenter(newCenter)
    
    // Then - Address acquisition doesn't start immediately
    XCTAssertFalse(sut.isLoadingMapCenterAddress)
    XCTAssertNil(sut.mapCenterAddress)
    
    // Wait for debounce time (300ms)
    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    
    // Then - Address is acquired after debounce
    XCTAssertNotNil(sut.mapCenterAddress)
    XCTAssertFalse(sut.isLoadingMapCenterAddress)
}
```

**Errors at this point:**
- `updateMapCenter` method doesn't exist
- `isLoadingMapCenterAddress` property doesn't exist
- `mapCenterAddress` property doesn't exist

### 2. Green - Implementation to pass tests

First, add necessary properties:

```swift
// MapViewModel.swift
@Published var mapCenterCoordinate = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
@Published var mapCenterAddress: FormattedAddress?
@Published var isLoadingMapCenterAddress = false

private var mapCenterGeocodingTask: Task<Void, Never>?
private let mapCenterDebounceDelay: UInt64 = 300_000_000 // 300ms
```

Next, implement methods:

```swift
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

### 3. Refactor - Improve task management

```swift
// Added to stopLocationTracking() method
func stopLocationTracking() {
    locationManager.stopLocationUpdates()
    geocodingTask?.cancel()
    mapCenterGeocodingTask?.cancel()  // Added: Cancel map center task too
}
```

## Implementation Example 3: Continuous Update Cancellation

### 1. Red - Write failing test

```swift
func testRapidMapCenterUpdatesCancelPreviousFetch() async {
    // Given
    let center1 = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
    let center2 = CLLocationCoordinate2D(latitude: 35.6820, longitude: 139.7680)
    let center3 = CLLocationCoordinate2D(latitude: 35.6830, longitude: 139.7690)
    sut.isFollowingUser = false
    
    // When - Continuously update map center
    sut.updateMapCenter(center1)
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    sut.updateMapCenter(center2)
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    sut.updateMapCenter(center3)
    
    // Then - Only the last update is processed
    try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
    XCTAssertEqual(sut.mapCenterCoordinate.latitude, center3.latitude, accuracy: 0.0001)
    XCTAssertEqual(sut.mapCenterCoordinate.longitude, center3.longitude, accuracy: 0.0001)
}
```

This test automatically passed with the debounce processing already implemented. This is evidence of good design.

## Benefits of TDD (From Examples)

### 1. Design Improvement
- Consider API usability by writing tests first
- Example: `updateMapCenter` method arguments naturally determined

### 2. Regression Prevention
- Ensure existing functionality doesn't break by having all tests pass
- Example: Guarantee that location updates in follow mode continue to work normally

### 3. Documentation
- Test code functions as specification documentation
- Example: Clear that debounce time is 300ms

### 4. Safe Refactoring
- Tests ensure safe code improvement
- Example: Guarantee behavior when improving task management

## Utilizing Mock Objects

```swift
// MockGeocodeService.swift
class MockGeocodeService: GeocodeServiceProtocol {
    var reverseGeocodeResult: Result<Address, Error> = .success(Address(
        name: "Tokyo Station",
        fullAddress: "1-9-1 Marunouchi, Chiyoda City, Tokyo",
        postalCode: "100-0005",
        locality: "Chiyoda City",
        subAdministrativeArea: nil,
        administrativeArea: "Tokyo",
        country: "Japan"
    ))
    
    func reverseGeocode(location: CLLocation) async throws -> Address {
        switch reverseGeocodeResult {
        case .success(let address):
            return address
        case .failure(let error):
            throw error
        }
    }
}
```

**Benefits of Mocks:**
- Fast tests without external API dependencies
- Easy testing of error cases
- Improved test stability with predictable results

## Lessons Learned

### 1. Asynchronous Processing Tests
- How to write tests using `async/await`
- Control timing with `Task.sleep`

### 2. SwiftUI Integration
- Focus on ViewModel tests
- Minimal UI tests (supplemented with manual testing this time)

### 3. Incremental Implementation
- Run Red-Green-Refactor cycle in small units
- Commit at each stage

## Summary

By practicing TDD:
- Implement reliable, low-bug code
- Design naturally improves
- Safety for future changes is ensured

Particularly for complex asynchronous processing like debounce processing, the TDD approach proved very effective.