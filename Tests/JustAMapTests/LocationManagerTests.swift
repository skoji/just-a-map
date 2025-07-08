import XCTest
import CoreLocation
@testable import JustAMapCore

final class LocationManagerTests: XCTestCase {
    var sut: LocationManagerProtocol!
    var mockDelegate: MockLocationManagerDelegate!
    
    override func setUp() {
        super.setUp()
        mockDelegate = MockLocationManagerDelegate()
    }
    
    override func tearDown() {
        sut = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    func testLocationManagerRequestsAuthorization() {
        // Given
        sut = MockLocationManager()
        
        // When
        sut.requestLocationPermission()
        
        // Then
        XCTAssertTrue((sut as! MockLocationManager).didRequestAuthorization)
    }
    
    func testLocationManagerStartsLocationUpdates() {
        // Given
        sut = MockLocationManager()
        sut.delegate = mockDelegate
        
        // When
        sut.startLocationUpdates()
        
        // Then
        XCTAssertTrue((sut as! MockLocationManager).isUpdatingLocation)
    }
    
    func testLocationManagerStopsLocationUpdates() {
        // Given
        sut = MockLocationManager()
        sut.startLocationUpdates()
        
        // When
        sut.stopLocationUpdates()
        
        // Then
        XCTAssertFalse((sut as! MockLocationManager).isUpdatingLocation)
    }
    
    func testLocationManagerReportsLocationToDelegate() {
        // Given
        sut = MockLocationManager()
        sut.delegate = mockDelegate
        let expectedLocation = CLLocation(latitude: 35.6762, longitude: 139.6503) // Tokyo Station
        
        // When
        (sut as! MockLocationManager).simulateLocationUpdate(expectedLocation)
        
        // Then
        XCTAssertNotNil(mockDelegate.lastReceivedLocation)
        XCTAssertEqual(mockDelegate.lastReceivedLocation!.coordinate.latitude, expectedLocation.coordinate.latitude, accuracy: 0.0001)
        XCTAssertEqual(mockDelegate.lastReceivedLocation!.coordinate.longitude, expectedLocation.coordinate.longitude, accuracy: 0.0001)
    }
    
    func testLocationManagerReportsErrorToDelegate() {
        // Given
        sut = MockLocationManager()
        sut.delegate = mockDelegate
        let expectedError = LocationError.authorizationDenied
        
        // When
        (sut as! MockLocationManager).simulateError(expectedError)
        
        // Then
        XCTAssertEqual(mockDelegate.lastReceivedError as? LocationError, expectedError)
    }
    
    func testLocationManagerReportsAuthorizationChangeToDelegate() {
        // Given
        sut = MockLocationManager()
        sut.delegate = mockDelegate
        
        // When
        (sut as! MockLocationManager).simulateAuthorizationChange(.authorizedWhenInUse)
        
        // Then
        XCTAssertEqual(mockDelegate.lastAuthorizationStatus, .authorizedWhenInUse)
    }
    
    func testLocationManagerAdjustsDistanceFilterForHighSpeedAndCloseZoom() {
        // Given
        sut = MockLocationManager()
        let speed = 60.0 // km/h
        let zoomDistance = 500.0 // meters (close zoom)
        
        // When
        sut.adjustUpdateFrequency(forSpeed: speed, zoomDistance: zoomDistance)
        
        // Then
        XCTAssertEqual((sut as! MockLocationManager).distanceFilter, 5.0) // 5m for high speed + close zoom
    }
    
    func testLocationManagerAdjustsDistanceFilterForLowSpeedAndFarZoom() {
        // Given
        sut = MockLocationManager()
        let speed = 10.0 // km/h
        let zoomDistance = 5000.0 // meters (far zoom)
        
        // When
        sut.adjustUpdateFrequency(forSpeed: speed, zoomDistance: zoomDistance)
        
        // Then
        XCTAssertEqual((sut as! MockLocationManager).distanceFilter, 50.0) // 50m for low speed + far zoom
    }
    
    func testLocationManagerAdjustsDistanceFilterForMediumSpeed() {
        // Given
        sut = MockLocationManager()
        let speed = 30.0 // km/h
        let zoomDistance = 1000.0 // meters
        
        // When
        sut.adjustUpdateFrequency(forSpeed: speed, zoomDistance: zoomDistance)
        
        // Then
        XCTAssertEqual((sut as! MockLocationManager).distanceFilter, 10.0) // 10m for medium conditions
    }
}

// MARK: - Mock Delegate
class MockLocationManagerDelegate: LocationManagerDelegate {
    var lastReceivedLocation: CLLocation?
    var lastReceivedError: Error?
    var lastAuthorizationStatus: CLAuthorizationStatus?
    
    func locationManager(_ manager: LocationManagerProtocol, didUpdateLocation location: CLLocation) {
        lastReceivedLocation = location
    }
    
    func locationManager(_ manager: LocationManagerProtocol, didFailWithError error: Error) {
        lastReceivedError = error
    }
    
    func locationManager(_ manager: LocationManagerProtocol, didChangeAuthorization status: CLAuthorizationStatus) {
        lastAuthorizationStatus = status
    }
}