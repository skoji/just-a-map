import XCTest
import CoreLocation
@testable import JustAMap

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
    
    func testLocationManagerAdjustsDistanceFilterForVeryDetailedZoom() {
        // Given
        sut = MockLocationManager()
        let altitude = 200.0 // Very low altitude (very detailed zoom)
        
        // When
        sut.adjustUpdateFrequency(forAltitude: altitude)
        
        // Then
        XCTAssertEqual((sut as! MockLocationManager).distanceFilter, 5.0) // 5m for very detailed zoom
    }
    
    func testLocationManagerAdjustsDistanceFilterForWideAreaZoom() {
        // Given
        sut = MockLocationManager()
        let altitude = 50000.0 // High altitude (wide area zoom)
        
        // When
        sut.adjustUpdateFrequency(forAltitude: altitude)
        
        // Then
        XCTAssertEqual((sut as! MockLocationManager).distanceFilter, 50.0) // 50m for wide area zoom
    }
    
    func testLocationManagerAdjustsDistanceFilterForDetailedZoom() {
        // Given
        sut = MockLocationManager()
        let altitude = 1000.0 // Low altitude (detailed zoom)
        
        // When
        sut.adjustUpdateFrequency(forAltitude: altitude)
        
        // Then
        XCTAssertEqual((sut as! MockLocationManager).distanceFilter, 10.0) // 10m for detailed zoom
    }
    
    func testLocationManagerAdjustsDistanceFilterForStandardZoom() {
        // Given
        sut = MockLocationManager()
        let altitude = 5000.0 // Medium altitude (standard zoom)
        
        // When
        sut.adjustUpdateFrequency(forAltitude: altitude)
        
        // Then
        XCTAssertEqual((sut as! MockLocationManager).distanceFilter, 20.0) // 20m for standard zoom
    }
    
    func testLocationManagerReportsPauseToDelegate() {
        // Given
        sut = MockLocationManager()
        sut.delegate = mockDelegate
        
        // When
        (sut as! MockLocationManager).simulateLocationUpdatesPaused()
        
        // Then
        XCTAssertTrue(mockDelegate.didPauseLocationUpdates)
    }
    
    func testLocationManagerReportsResumeToDelegate() {
        // Given
        sut = MockLocationManager()
        sut.delegate = mockDelegate
        
        // When
        (sut as! MockLocationManager).simulateLocationUpdatesResumed()
        
        // Then
        XCTAssertTrue(mockDelegate.didResumeLocationUpdates)
    }
    
    func testLocationManagerDisablesPausesWhenSpeedDisplayEnabled() {
        // Given
        sut = MockLocationManager()
        let mockSettings = MockMapSettingsStorage()
        mockSettings.isSpeedDisplayEnabled = true
        
        // When
        (sut as! MockLocationManager).updatePausesLocationUpdatesAutomatically(for: mockSettings)
        
        // Then
        XCTAssertFalse((sut as! MockLocationManager).pausesLocationUpdatesAutomatically)
    }
    
    func testLocationManagerEnablesPausesWhenSpeedDisplayDisabled() {
        // Given
        sut = MockLocationManager()
        let mockSettings = MockMapSettingsStorage()
        mockSettings.isSpeedDisplayEnabled = false
        
        // When
        (sut as! MockLocationManager).updatePausesLocationUpdatesAutomatically(for: mockSettings)
        
        // Then
        XCTAssertTrue((sut as! MockLocationManager).pausesLocationUpdatesAutomatically)
    }
}

// MARK: - Mock Delegate
class MockLocationManagerDelegate: LocationManagerDelegate {
    var lastReceivedLocation: CLLocation?
    var lastReceivedError: Error?
    var lastAuthorizationStatus: CLAuthorizationStatus?
    var didPauseLocationUpdates = false
    var didResumeLocationUpdates = false
    
    func locationManager(_ manager: LocationManagerProtocol, didUpdateLocation location: CLLocation) {
        lastReceivedLocation = location
    }
    
    func locationManager(_ manager: LocationManagerProtocol, didFailWithError error: Error) {
        lastReceivedError = error
    }
    
    func locationManager(_ manager: LocationManagerProtocol, didChangeAuthorization status: CLAuthorizationStatus) {
        lastAuthorizationStatus = status
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: LocationManagerProtocol) {
        didPauseLocationUpdates = true
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: LocationManagerProtocol) {
        didResumeLocationUpdates = true
    }
}