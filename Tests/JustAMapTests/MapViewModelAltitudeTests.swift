import XCTest
import CoreLocation
@testable import JustAMap

@MainActor
final class MapViewModelAltitudeTests: XCTestCase {
    var sut: MapViewModel!
    var mockLocationManager: MockLocationManager!
    var mockGeocodeService: MockGeocodeService!
    var mockSettingsStorage: MockMapSettingsStorage!
    
    override func setUp() async throws {
        mockLocationManager = MockLocationManager()
        mockGeocodeService = MockGeocodeService()
        mockSettingsStorage = MockMapSettingsStorage()
        
        sut = MapViewModel(
            locationManager: mockLocationManager,
            geocodeService: mockGeocodeService,
            settingsStorage: mockSettingsStorage
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        mockLocationManager = nil
        mockGeocodeService = nil
        mockSettingsStorage = nil
    }
    
    func testMapViewModelInitialAltitudeState() {
        // Given & When
        let altitude = sut.currentAltitude
        let verticalAccuracy = sut.currentVerticalAccuracy
        
        // Then
        XCTAssertNil(altitude)
        XCTAssertNil(verticalAccuracy)
    }
    
    func testMapViewModelUpdatesAltitudeOnLocationUpdate() {
        // Given
        let expectedAltitude = 123.5
        let expectedAccuracy = 5.0
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: expectedAltitude,
            horizontalAccuracy: 5.0,
            verticalAccuracy: expectedAccuracy,
            timestamp: Date()
        )
        
        // When
        sut.locationManager(mockLocationManager, didUpdateLocation: location)
        
        // Then
        XCTAssertEqual(sut.currentAltitude, expectedAltitude)
        XCTAssertEqual(sut.currentVerticalAccuracy, expectedAccuracy)
    }
    
    func testMapViewModelHandlesInvalidAltitude() {
        // Given
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 100.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: -1.0, // Negative indicates invalid
            timestamp: Date()
        )
        
        // When
        sut.locationManager(mockLocationManager, didUpdateLocation: location)
        
        // Then
        XCTAssertEqual(sut.currentAltitude, 100.0) // Altitude value is still stored
        XCTAssertEqual(sut.currentVerticalAccuracy, -1.0) // But accuracy indicates invalid
    }
    
    func testMapViewModelProvidesAltitudeDisplayString() {
        // Given
        let altitude = 123.5
        let accuracy = 5.0
        let unit = AltitudeUnit.meters
        
        // When
        let displayString = sut.getAltitudeDisplayString(
            altitude: altitude,
            verticalAccuracy: accuracy,
            unit: unit
        )
        
        // Then
        XCTAssertEqual(displayString, "124m") // Rounded to integer
    }
    
    func testMapViewModelProvidesInvalidAltitudeDisplayString() {
        // Given
        let altitude = 123.5
        let accuracy = -1.0 // Invalid
        let unit = AltitudeUnit.meters
        
        // When
        let displayString = sut.getAltitudeDisplayString(
            altitude: altitude,
            verticalAccuracy: accuracy,
            unit: unit
        )
        
        // Then
        XCTAssertEqual(displayString, "---")
    }
    
    func testAltitudeSettingsFromStorage() {
        // Given
        mockSettingsStorage.isAltitudeDisplayEnabled = true
        mockSettingsStorage.altitudeUnit = .feet
        
        // When
        let newViewModel = MapViewModel(
            locationManager: mockLocationManager,
            geocodeService: mockGeocodeService,
            settingsStorage: mockSettingsStorage
        )
        
        // Then
        XCTAssertTrue(newViewModel.isAltitudeDisplayEnabled)
        XCTAssertEqual(newViewModel.altitudeUnit, .feet)
    }
}