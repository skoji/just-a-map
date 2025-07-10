import XCTest
import CoreLocation
@testable import JustAMap

final class MapViewModelAltitudeTests: XCTestCase {
    var sut: MapViewModel!
    var mockLocationManager: MockLocationManager!
    var mockGeocodeService: MockGeocodeService!
    var mockSettingsStorage: MockMapSettingsStorage!
    
    override func setUp() {
        super.setUp()
        mockLocationManager = MockLocationManager()
        mockGeocodeService = MockGeocodeService()
        mockSettingsStorage = MockMapSettingsStorage()
        
        sut = MapViewModel(
            locationManager: mockLocationManager,
            geocodeService: mockGeocodeService,
            settingsStorage: mockSettingsStorage
        )
    }
    
    override func tearDown() {
        sut = nil
        mockLocationManager = nil
        mockGeocodeService = nil
        mockSettingsStorage = nil
        super.tearDown()
    }
    
    func testCurrentAltitudeInitiallyNil() {
        XCTAssertNil(sut.currentAltitude)
    }
    
    func testCurrentAltitudeAccuracyInitiallyNil() {
        XCTAssertNil(sut.currentAltitudeAccuracy)
    }
    
    func testUpdateLocationWithValidAltitude() {
        let testLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 150.5,
            horizontalAccuracy: 10.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )
        
        mockLocationManager.simulateLocationUpdate(testLocation)
        
        XCTAssertEqual(sut.currentAltitude, 150.5)
        XCTAssertEqual(sut.currentAltitudeAccuracy, 5.0)
    }
    
    func testUpdateLocationWithInvalidVerticalAccuracy() {
        let testLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 150.5,
            horizontalAccuracy: 10.0,
            verticalAccuracy: -1.0, // 負の値は無効
            timestamp: Date()
        )
        
        mockLocationManager.simulateLocationUpdate(testLocation)
        
        // 無効な精度の場合、高度をnilにする
        XCTAssertNil(sut.currentAltitude)
        XCTAssertEqual(sut.currentAltitudeAccuracy, -1.0)
    }
    
    func testUpdateLocationWithNegativeAltitude() {
        let testLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: -50.0, // 海面下
            horizontalAccuracy: 10.0,
            verticalAccuracy: 3.0,
            timestamp: Date()
        )
        
        mockLocationManager.simulateLocationUpdate(testLocation)
        
        XCTAssertEqual(sut.currentAltitude, -50.0)
        XCTAssertEqual(sut.currentAltitudeAccuracy, 3.0)
    }
    
    func testAltitudeDisplayEnabledFromSettings() {
        mockSettingsStorage.isAltitudeDisplayEnabled = true
        XCTAssertTrue(sut.isAltitudeDisplayEnabled)
        
        mockSettingsStorage.isAltitudeDisplayEnabled = false
        XCTAssertFalse(sut.isAltitudeDisplayEnabled)
    }
    
    func testAltitudeUnitFromSettings() {
        mockSettingsStorage.altitudeUnit = .meters
        XCTAssertEqual(sut.altitudeUnit, .meters)
        
        mockSettingsStorage.altitudeUnit = .feet
        XCTAssertEqual(sut.altitudeUnit, .feet)
    }
    
    func testDisplayedAltitudeWithMeters() {
        mockSettingsStorage.altitudeUnit = .meters
        
        let testLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 150.7,
            horizontalAccuracy: 10.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )
        
        mockLocationManager.simulateLocationUpdate(testLocation)
        
        XCTAssertEqual(sut.displayedAltitude, 150.7)
    }
    
    func testDisplayedAltitudeWithFeet() {
        mockSettingsStorage.altitudeUnit = .feet
        
        let testLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 150.0, // メートル
            horizontalAccuracy: 10.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )
        
        mockLocationManager.simulateLocationUpdate(testLocation)
        
        // フィートに変換されているか確認
        let expectedFeet = AltitudeUnit.convertToFeet(meters: 150.0)
        XCTAssertEqual(sut.displayedAltitude, expectedFeet, accuracy: 0.001)
    }
    
    func testDisplayedAltitudeWithInvalidAccuracy() {
        mockSettingsStorage.altitudeUnit = .meters
        
        let testLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            altitude: 150.0,
            horizontalAccuracy: 10.0,
            verticalAccuracy: -1.0, // 無効
            timestamp: Date()
        )
        
        mockLocationManager.simulateLocationUpdate(testLocation)
        
        XCTAssertNil(sut.displayedAltitude)
    }
}