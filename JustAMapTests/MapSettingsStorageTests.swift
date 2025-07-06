import XCTest
import MapKit
@testable import JustAMap

final class MapSettingsStorageTests: XCTestCase {
    var sut: MapSettingsStorageProtocol!
    var mockUserDefaults: MockUserDefaults!
    
    override func setUp() {
        super.setUp()
        mockUserDefaults = MockUserDefaults()
        sut = MapSettingsStorage(userDefaults: mockUserDefaults)
    }
    
    override func tearDown() {
        sut = nil
        mockUserDefaults = nil
        super.tearDown()
    }
    
    func testSaveMapStyle() {
        // Given
        let style = MapStyle.hybrid
        
        // When
        sut.saveMapStyle(style)
        
        // Then
        XCTAssertEqual(mockUserDefaults.storage["mapStyle"] as? String, style.rawValue)
    }
    
    func testLoadMapStyle() {
        // Given
        mockUserDefaults.storage["mapStyle"] = MapStyle.imagery.rawValue
        
        // When
        let style = sut.loadMapStyle()
        
        // Then
        XCTAssertEqual(style, .imagery)
    }
    
    func testLoadMapStyleDefault() {
        // Given - UserDefaultsに何も保存されていない
        
        // When
        let style = sut.loadMapStyle()
        
        // Then
        XCTAssertEqual(style, .standard)
    }
    
    func testSaveMapOrientation() {
        // Given
        let isNorthUp = false
        
        // When
        sut.saveMapOrientation(isNorthUp: isNorthUp)
        
        // Then
        XCTAssertEqual(mockUserDefaults.storage["isNorthUp"] as? Bool, false)
    }
    
    func testLoadMapOrientation() {
        // Given
        mockUserDefaults.storage["isNorthUp"] = false
        
        // When
        let isNorthUp = sut.loadMapOrientation()
        
        // Then
        XCTAssertFalse(isNorthUp)
    }
    
    func testLoadMapOrientationDefault() {
        // Given - UserDefaultsに何も保存されていない
        
        // When
        let isNorthUp = sut.loadMapOrientation()
        
        // Then
        XCTAssertTrue(isNorthUp) // デフォルトはNorth Up
    }
    
    func testSaveZoomLevel() {
        // Given
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        
        // When
        sut.saveZoomLevel(span: span)
        
        // Then
        XCTAssertEqual(mockUserDefaults.storage["zoomLatDelta"] as? Double, 0.05)
        XCTAssertEqual(mockUserDefaults.storage["zoomLonDelta"] as? Double, 0.05)
    }
    
    func testLoadZoomLevel() {
        // Given
        mockUserDefaults.storage["zoomLatDelta"] = 0.1
        mockUserDefaults.storage["zoomLonDelta"] = 0.1
        
        // When
        let span = sut.loadZoomLevel()
        
        // Then
        XCTAssertEqual(span?.latitudeDelta, 0.1)
        XCTAssertEqual(span?.longitudeDelta, 0.1)
    }
    
    func testLoadZoomLevelDefault() {
        // Given - UserDefaultsに何も保存されていない
        
        // When
        let span = sut.loadZoomLevel()
        
        // Then
        XCTAssertNil(span)
    }
}

// MARK: - Mock UserDefaults
class MockUserDefaults: UserDefaultsProtocol {
    var storage: [String: Any] = [:]
    
    func object(forKey defaultName: String) -> Any? {
        return storage[defaultName]
    }
    
    func set(_ value: Any?, forKey defaultName: String) {
        if let value = value {
            storage[defaultName] = value
        } else {
            storage.removeValue(forKey: defaultName)
        }
    }
    
    func bool(forKey defaultName: String) -> Bool {
        return storage[defaultName] as? Bool ?? false
    }
    
    func double(forKey defaultName: String) -> Double {
        return storage[defaultName] as? Double ?? 0.0
    }
    
    func string(forKey defaultName: String) -> String? {
        return storage[defaultName] as? String
    }
}